//
//  ViewController.swift
//  MiceBoy
//
//  Created by Mykhailo Vorontsov on 9/18/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import CoreMotion

class DiscoveryViewController: UITableViewController {
  
  @IBOutlet var textView: UITextView?
  
  var hosts = [MCPeerID]()
  var selectedPeer: MCPeerID? {
    didSet {
      guard nil != selectedPeer else { return }
      DispatchQueue.main.async {
        self.performSegue(withIdentifier: "selectPeer", sender: self)
      }
    }
  }
  
  let connectionService = ConnectionBrowser(peerName: UIDevice.current.name)
  var tokens = [TokenProtocol]()
  
  var lastConnectedPeer: String? {
    get {
      return UserDefaults.standard.string(forKey: "lastPeer")
    }
    set {
      UserDefaults.standard.set(newValue, forKey: "lastPeer")
      UserDefaults.standard.synchronize()
    }
  }
  
  override func viewDidLoad() {
    
    super.viewDidLoad()
    self.tableView.tableHeaderView = nil
    self.tableView.tableFooterView = self.textView
    
    let token = connectionService.subscribeForDiscovery {[unowned self] (discovery) -> (Void) in
      DispatchQueue.main.async {
        switch discovery {
        case .found(let peer, _):
          self.print("\n Found: \(peer.displayName)")
          self.tableView.beginUpdates()
          self.hosts.append(peer)
          let indexPath = IndexPath(row: self.hosts.count - 1, section: 0)
          self.tableView.insertRows(at: [indexPath], with: .automatic)
          self.tableView.endUpdates()
          if peer.displayName == self.lastConnectedPeer {
            self.selectedPeer = peer
          }
        case .lost(let peer):
          self.print("\n lost: \(peer.displayName)")
          if let index = self.hosts.index(of: peer) {
            self.tableView.beginUpdates()
            self.hosts.remove(at: index)
            self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            self.tableView.endUpdates()
          }
        }
      }
    }
    tokens.append(token)
    connectionService.startDiscovery()
  }
  var sensibility = 10.0
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return hosts.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
  }
  
  override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard indexPath.row < hosts.count else { return }
    let host = hosts[indexPath.row]
    cell.textLabel?.text = host.displayName
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard indexPath.row < hosts.count else { return }
    let host = hosts[indexPath.row]
    self.selectedPeer = host
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? EventsViewController {
      guard let peer = selectedPeer else { return }
//      guard let index = self.tableView.indexPathForSelectedRow?.row, index < hosts.count else { return }
//      let peer = hosts[index]
      destination.session = connectionService.invite(peer: peer)
      destination.peer = selectedPeer
      self.lastConnectedPeer = peer.displayName
    }
  }
  
}

extension DiscoveryViewController: TextPrintable {}

protocol TextPrintable {
  var textView: UITextView? { get }
  func print(_ str: String)
}

extension TextPrintable {
  func print(_ str: String) {
    DispatchQueue.main.async {
      self.textView?.text.append("\n\(str)")
    }
  }
}



