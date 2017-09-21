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
  
  private let subscriptions = NSHashTable<Token>.weakObjects()

  func subscribe<T: Codable>( handler: @escaping  SpecIncommingObjectHandler<T>) -> TokenProtocol {
    let token = Token(handler: handler)
    subscriptions.add(token)
    return token
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
//    session.connectPeer(peerID, withNearbyConnectionData: Data())
  }
  
  
  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    NSLog("%@", "didReceiveData: \(data)")
    guard subscriptions.count > 0 else {
      print("No sucription avaliable to process data!")
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
  }
  
  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    NSLog("%@", "didStartReceivingResourceWithName")
  }
  
  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    NSLog("%@", "didFinishReceivingResourceWithName")
  }
  
}
