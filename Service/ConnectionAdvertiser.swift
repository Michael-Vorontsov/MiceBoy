//
//  ConnectionAdvertiser.swift
//  MiceBoy
//
//  Created by Mykhailo Vorontsov on 9/18/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import MultipeerConnectivity

struct PeerContext<C: Codable>: Codable {
  let peerDisplayName: String
  let context: C?
}

class ConnectionAdvertiser : NSObject {
  
  enum DiscoveryErrors: Error {
    case noPendingInvitation(key: String)
    case sessionExists(key: String)
  }
  
  typealias Token = GToken<PeerInvitation, Void>

  // Service type must be a unique string, at most 15 characters long
  // and can contain only ASCII lowercase letters, numbers and hyphens.
  private let serviceType = "miceboy-host"
  private let myPeerId: MCPeerID
  private var serviceAdvertiser : MCNearbyServiceAdvertiser?

  
  private let invitationSubscription = NSHashTable<Token>.weakObjects()
  fileprivate var pendingInvitation = [PeerInvitation : PeerInvitation]()
  fileprivate var runningSessions = [String : ConnectionSessionManager]()
  
  init (peerName: String) {
    myPeerId = MCPeerID(displayName: peerName)
    super.init()
  }

  @discardableResult
  func accept(invitation key: PeerInvitation) throws -> ConnectionSessionManager {
    guard let invitation = pendingInvitation[key] else {
      throw DiscoveryErrors.noPendingInvitation(key: key.peerName)
    }
    let session = ConnectionSessionManager(peerID: myPeerId)
    invitation.invitationHandler(true, session.session)
    pendingInvitation.removeValue(forKey: key)
    runningSessions[key.peerName] = session
    return session
  }
  
  func decline(invitation key: PeerInvitation) throws {
    guard let invitation = pendingInvitation[key] else {
      throw DiscoveryErrors.noPendingInvitation(key: key.peerName)
    }
    invitation.invitationHandler(false, nil)
    pendingInvitation.removeValue(forKey: key)
  }
  
  func session(for peerName: String) -> ConnectionSessionManager? {
    return self.runningSessions[peerName]
  }

  func subscribe(forInvitation handler: @escaping ((PeerInvitation) -> Void)) -> TokenProtocol {
    let token = Token(handler: handler)
    invitationSubscription.add(token)
    return token
  }
  
  func startAdvertising() {
    guard nil == serviceAdvertiser else { return }
    self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
    self.serviceAdvertiser?.delegate = self
    self.serviceAdvertiser?.startAdvertisingPeer()
  }
  
  deinit {
    self.serviceAdvertiser?.stopAdvertisingPeer()
  }
}

struct PeerInvitation: Hashable {
  var hashValue: Int {
    get {
      return timeStame.hashValue ^ peerName.hashValue
    }
  }
  
  static func ==(lhs: PeerInvitation, rhs: PeerInvitation) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
  
  let invitationHandler: (Bool, MCSession?) -> Void
  let peerID: MCPeerID
  let context: Data?
  let timeStame: TimeInterval = Date().timeIntervalSince1970
  
  var peerName: String  {
    get {
      return self.peerID.displayName
    }
  }
}

extension ConnectionAdvertiser : MCNearbyServiceAdvertiserDelegate {
  
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
    NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
  }
  
  func advertiser(
    _ advertiser: MCNearbyServiceAdvertiser,
    didReceiveInvitationFromPeer peerID: MCPeerID,
    withContext context: Data?,
    invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
    print("didReceiveInvitationFromPeer \(peerID)")
    
    guard invitationSubscription.count > 0 else {
      print("Declining connection to peer \(peerID) because no subsciprion avaialble")
      invitationHandler(false, nil)
      return
    }
    
    let invitation = PeerInvitation(
      invitationHandler: invitationHandler,
      peerID: peerID,
      context: context
    )
    pendingInvitation[invitation] = invitation
    
    for each in invitationSubscription.allObjects {
      each.handler(invitation)
    }
  }
  
}
