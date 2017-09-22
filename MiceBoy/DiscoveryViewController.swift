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

class DiscoveryViewController: UIViewController {
  @IBOutlet var textView: UITextView!
  
  @IBAction func switchActive(_ sender: UISwitch) {
    paused = !sender.isOn
  }
  
  @IBAction func buttonTouched(_ sender: Any) {
    paused = true
  }
  
  @IBAction func buttonReleased(_ sender: Any) {
    paused = false
  }
  
  
  @IBAction func changeSensitivity(_ sender: UISlider) {
    sensibility = Double(sender.value)
  }
  
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
    enableMotioTracking()

  }
  
  var sensibility = 10.0
  
  var zeroGravity: CMAcceleration?
  
  func enableMotioTracking() {
    guard motionManager.isDeviceMotionActive == false else { return }
//    motionManager.gyroUpdateInterval = 0.1
    motionManager.deviceMotionUpdateInterval = 0.1
    motionManager.startDeviceMotionUpdates(to: OperationQueue()) {[unowned self] (data, error) in
      if let error = error {
        self.print(error.localizedDescription)
        return
      }
      guard self.paused == false else { return }
      if let rotationRate = data?.rotationRate {
                let event = MouseEvent.move(delta: CGPoint(
                  x: -rotationRate.z * self.sensibility,
                  y: -rotationRate.x * self.sensibility)
                )
      
//      if let gravity = data?.gravity {
//        guard let zeroGravity = self.zeroGravity else {
//          self.zeroGravity = gravity
//          return
//        }
//
//        let event = MouseEvent.move(delta: CGPoint(
//          x: (zeroGravity.x - gravity.x) * self.sensibility,
//          y: (zeroGravity.y - gravity.y) * self.sensibility)
//        )
        guard let stream = self.outputStream else { return }
        stream.send(object: event)
      }
    }
  }

  var paused = false {
    didSet {
      if paused {
        zeroGravity = nil
      }
    }
  }
  
  @IBAction func tapRecognised(_ sender: UITapGestureRecognizer) {
//    guard let session = session else { return }
//    print("Sending event to peer: \(session)")
//    let button = (sender.numberOfTouches == 1) ? MouseEvent.ButtonType.left : MouseEvent.ButtonType.right
    switch sender.state {
    case .began:
      paused = true
//      session.send(object: MouseEvent.button(button, state: .down))
    case .ended, .cancelled:
      paused = false
//      session.send(object: MouseEvent.button(button, state: .up))
    default: break;
      paused = false
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
  
  let motionManager = CMMotionManager()
  
  
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

