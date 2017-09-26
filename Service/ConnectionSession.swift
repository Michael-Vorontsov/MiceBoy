//
//  ConnectionSession.swift
//  MiceBoy
//
//  Created by Mykhailo Vorontsov on 9/18/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class ConnectionSessionManager: NSObject {
  
  typealias IncommingObjectHandler = ((Codable) throws -> ())
  typealias SpecIncommingObjectHandler<C: Codable> = ((C) throws -> ())

  private class Token: TokenProtocol {
    fileprivate let handler: IncommingObjectHandler
    fileprivate let mapper: Mapping
    
    init(mapper: Mapping, handler: @escaping IncommingObjectHandler) {
      self.handler = handler
      self.mapper = mapper
    }
    
    init<C: Codable>(handler: @escaping SpecIncommingObjectHandler<C>) {
      self.handler = {(a) in
        if let a = a as? C  { try handler(a) }
      }
      self.mapper = Mapper<C>()
    }
    
    @discardableResult
    func process(data: Data) throws -> Codable {
      let object = try mapper.map(data: data)
      try handler(object)
      return object
    }
  }

//  private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
  
  private let encoder = JSONEncoder()

  let session: MCSession
  
  init(peerID: MCPeerID) {
    session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    super.init()
    session.delegate = self
  }

  typealias StreamToken = GToken<InputStream, Void>
  typealias StateToken = GToken<MCSessionState, Void>

  private let subscriptions = NSHashTable<Token>.weakObjects()
  private let streamSubscriptions = NSHashTable<StreamToken>.weakObjects()
  private let stateSubscriptions = NSHashTable<StateToken>.weakObjects()

  func subscribe<T: Codable>( handler: @escaping  SpecIncommingObjectHandler<T>) -> TokenProtocol {
    let token = Token(handler: handler)
    subscriptions.add(token)
    return token
  }
  
  func subscribe(streamHandler: @escaping (InputStream)->Void ) -> TokenProtocol {
    let token = StreamToken(handler: streamHandler)
    streamSubscriptions.add(token)
    return token
  }

  func subscribeState(stateHandler: @escaping (MCSessionState)->Void ) -> TokenProtocol {
    let token = StateToken(handler: stateHandler)
    stateSubscriptions.add(token)
    return token
  }

  enum SessionError: Error {
    case noPeers
  }
  
  func establishStream() throws -> OutputStream {
    guard let peer = session.connectedPeers.first else { throw SessionError.noPeers }
    let stream = try session.startStream(withName: "remoteEvents", toPeer: peer)
    return stream
  }
  
  func send<T: Codable>(object: T) {
    
    if session.connectedPeers.count > 0 {
      do {
        let data = try encoder.encode(object)
        try self.session.send(data, toPeers: session.connectedPeers, with: .reliable)
      }
      catch let error {
        NSLog("%@", "Error for sending: \(error)")
      }
    }
  }

}

extension ConnectionSessionManager : MCSessionDelegate {
  
  func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    NSLog("%@", "peer \(peerID) didChangeState: \(state)")
    guard stateSubscriptions.count > 0 else {
      print("No subscription avaliable to react on state!")
      return
    }
    for each in stateSubscriptions.allObjects {
      each.handler(state)
    }
  }
  
  
  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
//    NSLog("%@", "didReceiveData: \(data)")
    guard subscriptions.count > 0 else {
      print("No subscription avaliable to process data!")
      return
    }
    for each in subscriptions.allObjects {
      do {
        try each.process(data: data)
      }
      catch {
        continue
      }
    }
  }
  
  func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    NSLog("%@", "didReceiveStream")
    guard streamSubscriptions.count > 0 else {
      print("No subscription avaliable to process stream!")
      return
    }
    for each in streamSubscriptions.allObjects {
      each.handler(stream)
    }
  }
  
  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    NSLog("%@", "didStartReceivingResourceWithName")
  }
  
  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    NSLog("%@", "didFinishReceivingResourceWithName")
  }
  
}
