//
//  ViewController.swift
//  MiceBoy
//
//  Created by Mykhailo Vorontsov on 9/18/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit

class DiscoveryViewController: UIViewController {
  @IBOutlet var textView: UITextView!
  

  let connectionService = ConnectionBrowser(peerName: UIDevice.current.name)
  var session: ConnectionSessionManager?
  var tokens = [TokenProtocol]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    let token = connectionService.subscribeForDiscovery {[unowned self] (discovery) -> (Void) in
      DispatchQueue.main.async {
      switch discovery {
        case .found(let peer, _):
          self.textView.text.append("\n Found: \(peer.displayName)")
          self.session = self.connectionService.invite(peer: peer)
        case .lost(let peer):
          self.textView.text.append("\n lost: \(peer.displayName)")
          self.session = nil
        }
      }
    }
    tokens.append(token)
    connectionService.startDiscovery()
  }

  @IBAction func tapRecognised(_ sender: UITapGestureRecognizer) {
    guard let session = session else { return }
    print("Sending event to peer: \(session)")
    let button = (sender.numberOfTouches == 1) ? MouseEvent.ButtonType.left : MouseEvent.ButtonType.right
    switch sender.state {
    case .began:
      session.send(object: MouseEvent.button(button, state: .down))
    case .ended, .cancelled:
      session.send(object: MouseEvent.button(button, state: .up))
    default: break;
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

