//
//  ViewController.swift
//  MiceBoy
//
//  Created by Mykhailo Vorontsov on 9/18/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class DiscoveryViewController: UIViewController {
  @IBOutlet var textView: UITextView!
  
  let connectionService = ConnectionBrowser(peerName: UIDevice.current.name)
  var session: ConnectionSessionManager? {
    didSet {
      guard let session = session else { return }
      self.tokens.append( session.subscribeState {[unowned self] state in
        DispatchQueue.main.async {
          switch state {
          case .connected:
            self.textView.text.append("\n session connected!, establishing stream")
            if let stream = try? session.establishStream() {
              stream.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
              stream.delegate = self
              stream.open()
              self.outputStream = stream
            }
            
          case .notConnected:
            self.textView.text.append("\n session disconected")
            self.outputStream = nil
          case .connecting:
            self.textView.text.append("\n session connecting")
          }
        }
      })
    }
  }
  var outputStream: OutputStream?
  var tokens = [TokenProtocol]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    let token = connectionService.subscribeForDiscovery {[unowned self] (discovery) -> (Void) in
      DispatchQueue.main.async {
        switch discovery {
        case .found(let peer, _):
          self.textView.text.append("\n Found: \(peer.displayName)")
          let session = self.connectionService.invite(peer: peer)
          self.session = session
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
  
  var lastPostion: CGPoint?
  let encoder = JSONEncoder()
  @IBAction func panRecognised(_ sender: UIPanGestureRecognizer) {
    //    let delta = sender.velocity(in: view)
    //    let length = sqrt(delta.x * delta.x + delta.y * delta.y)
    //    let norm = 10.0 / length
    //    let deltaNormilized = CGPoint(x: delta.x * norm, y: delta.y * norm)
    //    let event = MouseEvent.move(delta: deltaNormilized)
    
    var delta = sender.translation(in: view)
    if let lastPostion = lastPostion {
      delta.x -= lastPostion.x
      delta.y -= lastPostion.y
    }
    if sender.state == .changed {
      lastPostion = delta
    } else {
      lastPostion = nil
    }
    
    let event = MouseEvent.move(delta: delta)
    guard let stream = outputStream else { return }
    
    stream.send(object: event)
    
//    session?.send(object: event)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
}
private let encoder = JSONEncoder()

extension OutputStream {
  
  func send<T: Codable>(object:T) {
    let data = try! encoder.encode(object)

    _ = data.withUnsafeBytes {
      self.write($0, maxLength: data.count)
    }
  }

}

extension DiscoveryViewController {
  func print(_ str: String) {
    DispatchQueue.main.async {
      self.textView.text.append("\n\(str)")
    }
  }
}

extension DiscoveryViewController : StreamDelegate {
  func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
//    guard let stream = aStream as? OutputStream else { return }
    switch eventCode {
    case .openCompleted:
      print("Stream established!")
    case .errorOccurred:
      print("Stream failed!")

//    case .hasSpaceAvailable:
//      print("Stream ready!")
    default: break

    }
  }
}

