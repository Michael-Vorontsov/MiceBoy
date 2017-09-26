//
//  EventsViewController.swift
//  MiceBoy
//
//  Created by Mykhailo Vorontsov on 9/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import UIKit
import CoreMotion
import MultipeerConnectivity

class EventsViewController: UIViewController {
  
  @IBOutlet var textView: UITextView?
  
  var tokens = [TokenProtocol]()

  @IBAction func switchActive(_ sender: UISwitch) {
    paused = !sender.isOn
  }
  
  @IBAction func buttonTouched(_ sender: Any) {
    paused = true
  }
  
  @IBAction func buttonReleased(_ sender: Any) {
    paused = false
  }
  
  var sensitivity: CGFloat = 10.0
  
  @IBAction func changeSensitivity(_ sender: UISlider) {
    sensitivity = CGFloat(sender.value)
  }
  
  var outputStream: OutputStream?
  
  var peer: MCPeerID?
  let mexRetries = 3
  var retries = 0

  var session: ConnectionSessionManager? {
    didSet {
      guard let session = session else { return }
      self.tokens.append( session.subscribeState {[unowned self] state in
        switch state {
        case .connected:
          self.retries = 0
          self.print("\n session connected!, establishing stream")
          if let stream = try? session.establishStream() {
            stream.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
            stream.delegate = self
            stream.open()
            self.outputStream = stream
          }
          
        case .notConnected:
          self.print("\n session disconected")
          self.outputStream = nil
          self.retries += 1
          if self.retries < self.mexRetries, let peer = self.peer {
            session.session.connectPeer(peer, withNearbyConnectionData: Data())
          }
          else {
            DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
            }
          }
        case .connecting:
          self.print("\n session connecting")
        }
      })
    }
  }
  
  func enableMotioTracking() {
    guard motionManager.isDeviceMotionActive == false else { return }
    //    motionManager.gyroUpdateInterval = 0.1
    motionManager.deviceMotionUpdateInterval = 0.1
    motionManager.startDeviceMotionUpdates(to: OperationQueue()) {[unowned self] (data, error) in
      if let error = error {
        self.print(error.localizedDescription)
        return
      }
      guard self.paused == false, let data = data else { return }
      
      let event = RemoteEvent.motionData(motion: RemoteEvent.MotionData(
        gravity: RemoteEvent.Vector(
          x: data.gravity.x,
          y: data.gravity.y,
          z: data.gravity.z),
        rotationChange: RemoteEvent.Vector(
          x: data.rotationRate.x,
          y: data.rotationRate.y,
          z: data.rotationRate.z),
        acceleration: RemoteEvent.Vector(
          x: data.userAcceleration.x,
          y: data.userAcceleration.y,
          z: data.userAcceleration.z)
      ))
      
      //    let rotationRate = data.rotationRate
      //      let event = RemoteEvent.move(delta: CGPoint(
      //        x: -rotationRate.z * self.sensibility,
      //        y: -rotationRate.x * self.sensibility)
      //      )
      self.sendToHost(event: event)
    }
  }
  
  func sendToHost(event: RemoteEvent) {
    guard let stream = self.outputStream else { return }
    stream.send(object: event)
  }
  
  @IBAction func tapRecognised(_ sender: UITapGestureRecognizer) {
    //    guard let session = session else { return }
    //    print("Sending event to peer: \(session)")
    //    let button = (sender.numberOfTouches == 1) ? RemoteEvent.ButtonType.left : RemoteEvent.ButtonType.right
    switch sender.state {
    case .began:
      paused = true
    //      session.send(object: RemoteEvent.button(button, state: .down))
    case .ended, .cancelled:
      paused = false
    //      session.send(object: RemoteEvent.button(button, state: .up))
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
    //    let event = RemoteEvent.move(delta: deltaNormilized)
    
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
    
    let event = RemoteEvent.move(delta: delta)
    guard let stream = outputStream else { return }
    
    stream.send(object: event)
    
    //    session?.send(object: event)
  }
  
  let motionManager = CMMotionManager()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    enableMotioTracking()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  var paused = false {
    didSet {
      guard let stream = self.outputStream else { return }
      stream.send(object: RemoteEvent.pause(paused))
    }
  }
  
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using segue.destinationViewController.
   // Pass the selected object to the new view controller.
   }
   */
  
}

extension EventsViewController: TextPrintable {}


extension EventsViewController : StreamDelegate {
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

