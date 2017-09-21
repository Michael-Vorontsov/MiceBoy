//
//  ViewController.swift
//  MiceboyHost
//
//  Created by Mykhailo Vorontsov on 9/18/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

  @IBOutlet var textView: NSTextView!

  let connectionService = ConnectionAdvertiser(peerName: "miceboy-host")
  
  var session: ConnectionSessionManager? {
    didSet {
      guard let session = session else { return }
      
      self.tokens.append( session.subscribe {[unowned self] (mouseEvent: MouseEvent) in
        DispatchQueue.main.async {
          self.didReceive(event: mouseEvent)
        }
      })
    }
  }
  
  var tokens = [TokenProtocol]()
  
  override func viewDidLoad() {
    super.viewDidLoad()

    let token = connectionService.subscribe { [unowned self] (peerInvitation) in
      DispatchQueue.main.async {
        self.textView.textStorage?.mutableString.append("\n Accpeting invitation from:\(peerInvitation.peerName)")
        self.session = try? self.connectionService.accept(invitation: peerInvitation)
      }
    }
    tokens.append(token)
    connectionService.startAdvertising()
    

    // Do any additional setup after loading the view.
  }
  
    func didReceive(event: MouseEvent) {
      var details = "\n Did recive mouse event"
      switch (event) {
      case .move(let delta):
        details += "\nMove: (\(delta.x), \(delta.y))"
      case .button(let type, state: let state):
        switch type {
        case .left:
          details += "\nLeft "
          case .right:
          details += "\nRight "
        }
        switch state {
        case .up:
          details += "released "
        case .down:
          details += "pressed"
        }
      }
      self.textView.textStorage?.mutableString.append(details)
    }

  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }


}

