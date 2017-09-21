//
//  ConnectionBrowser.swift
//  MiceBoy
//
//  Created by Mykhailo Vorontsov on 9/18/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class ConnectionBrowser : NSObject {
  
  enum DiscoveryEvent {
    case lost(peer: MCPeerID)
    case found(peer: MCPeerID, info: [String : String]?)
    
    var peerName: String {
      get {
        switch self {
        case .found(let peer, _):
          return peer.displayName
        case .lost(let peer):
          return peer.displayName
        }
      }
    }
  }
  
  typealias DiscoveryHandler = ((DiscoveryEvent) -> (Void))
  
  // Service type must be a unique string, at most 15 characters long
  // and can contain only ASCII lowercase letters, numbers and hyphens.
  
  private let ColorServiceType = "miceboy-host"
  
  private let myPeerId: MCPeerID
  
  private var serviceBrowser : MCNearbyServiceBrowser?
  
  fileprivate var pendingPeers = Set<MCPeerID>()
  fileprivate var runningSessions = [String : ConnectionSessionManager]()
  
  init (peerName: String) {
    myPeerId = MCPeerID(displayName: peerName)
    super.init()
  }
  
  func startDiscovery() {
    guard nil == self.serviceBrowser else { return }
    let discovery = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ColorServiceType)
    self.serviceBrowser = discovery
    discovery.delegate = self
    discovery.startBrowsingForPeers()
  }
  
  deinit {
    self.serviceBrowser?.stopBrowsingForPeers()
  }
  
  typealias DToken = GToken<DiscoveryEvent, Void>
  
  private let subscriptions = NSHashTable<DToken>.weakObjects()
  
  func subscribeForDiscovery( handler: @escaping DiscoveryHandler ) -> TokenProtocol {
    let token = DToken(handler: handler)
    subscriptions.add(token)
    return token
  }
  
  @discardableResult
  func invite(peer: MCPeerID, context: Data? = nil) -> ConnectionSessionManager {
    let session = ConnectionSessionManager(peerID: self.myPeerId)
    self.serviceBrowser?.invitePeer(peer, to: session.session, withContext: context, timeout: 120.0)
    runningSessions[peer.displayName] = session
    return session
  }
  
  func session(for peerName: String) -> ConnectionSessionManager? {
    return self.runningSessions[peerName]
  }
  
  func pendingPeer(for name: String) -> MCPeerID? {
    return self.pendingPeers
      .filter{ (peer) -> Bool in
        return peer.displayName == name
      }
      .first
  }

}
extension ConnectionBrowser : MCNearbyServiceBrowserDelegate {
  
  func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
    NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
  }
  
  func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
    NSLog("%@", "foundPeer: \(peerID)")
    NSLog("%@", "invitePeer: \(peerID)")
    
    let discovery = DiscoveryEvent.found(peer: peerID, info: info)
    self.pendingPeers.insert(peerID)
    
    for each in subscriptions.allObjects {
      each.handler(discovery)
    }
  }
  
  func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    let discovery = DiscoveryEvent.lost(peer: peerID)
    self.pendingPeers.insert(peerID)
    for each in subscriptions.allObjects {
      each.handler(discovery)
    }
  }
  
}
