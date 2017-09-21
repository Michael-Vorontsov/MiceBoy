////
////  ConnectionServiceManager.swift
////  MiceBoy
////
////  Created by Mykhailo Vorontsov on 9/18/17.
////  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
////
//
//import Foundation
//import MultipeerConnectivity
//
////protocol ConnectionServiceHandler
//class ConnectionServiceManager : NSObject {
//
//
//  // Service type must be a unique string, at most 15 characters long
//  // and can contain only ASCII lowercase letters, numbers and hyphens.
//
//  private let ColorServiceType = "miceboy-host"
//
//  private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
//
//  private var serviceAdvertiser : MCNearbyServiceAdvertiser?
//  private var serviceBrowser : MCNearbyServiceBrowser?
//
//  func startAdvertising() {
//    guard nil == serviceAdvertiser else { return }
//    self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: ColorServiceType)
//    self.serviceAdvertiser?.delegate = self
//  }
//
//  func startDiscovery() {
//    guard nil == self.serviceBrowser else { return }
//    let discovery = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ColorServiceType)
//    self.serviceBrowser = discovery
//    discovery.delegate = self
//    discovery.startBrowsingForPeers()
//  }
//
//  deinit {
//    self.serviceAdvertiser?.stopAdvertisingPeer()
//    self.serviceBrowser?.stopBrowsingForPeers()
//  }
//}
//
//
//
//
