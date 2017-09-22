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
  @IBOutlet weak var drawingView: PointDrawingView!

  let connectionService = ConnectionAdvertiser(peerName: "miceboy-host")
  
  var session: ConnectionSessionManager? {
    didSet {
      guard let session = session else { return }
      
      self.tokens.append( session.subscribe {[unowned self] (mouseEvent: MouseEvent) in
        DispatchQueue.main.async {
          self.didReceive(event: mouseEvent)
        }
      })
      
      self.tokens.append( session.subscribe(streamHandler: {[unowned self] (stream: InputStream) in
        self.print("Streame recived")
        stream.delegate = self
        stream.schedule(in: .main, forMode: .defaultRunLoopMode)
        stream.open()
        self.print("Stream status: \(String(describing: stream.streamStatus))")
        if let error = stream.streamError {
          self.print("Error: \(error)")
        }
        self.stream = stream
      }))
      
      self.tokens.append( session.subscribeState {[unowned self] state in
        DispatchQueue.main.async {
          switch state {
          case .connected:
            self.print("\n session connected!")
          case .notConnected:
            self.print("\n session disconected")
          case .connecting:
            self.print("\n session connecting")
          }
        }
      })

    }
  }
  
  var stream: InputStream?
  
  var tokens = [TokenProtocol]()
  
  override func viewDidLoad() {
    super.viewDidLoad()

    tokens.append(connectionService.subscribe { [unowned self] (peerInvitation) in
      DispatchQueue.main.async {
        self.textView.textStorage?.mutableString.append("\n Accpeting invitation from:\(peerInvitation.peerName)")
        self.session = try? self.connectionService.accept(invitation: peerInvitation)
      }
    })
    
    
    
    connectionService.startAdvertising()
    

    // Do any additional setup after loading the view.
  }
  
  
  func mouseMoveAndClick(onPoint point: CGPoint) {
//    drawingView.add(point: point)
    
    
    let currentPostion = NSEvent.mouseLocation
    let destination = NSPoint(x: currentPostion.x + point.x, y: NSScreen.main!.frame.size.height - currentPostion.y + point.y)
    guard let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: destination, mouseButton: .left) else {
      return
    }
    moveEvent.post(tap: CGEventTapLocation.cghidEventTap)
//    guard let downEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: destination, mouseButton: .left) else {
//      return
//    }
//    downEvent.post(tap: CGEventTapLocation.cghidEventTap)
//    guard let upEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: destination, mouseButton: .left) else {
//      return
//    }
//    upEvent.post(tap: CGEventTapLocation.cghidEventTap)
  }
  
  @IBAction func reset(_ sender: Any) {
    drawingView.reset()
  }

    func didReceive(event: MouseEvent) {
      var details = "\n Did recive mouse event"
      switch (event) {
      case .move(let delta):
        details += "\nMove: (\(delta.x), \(delta.y))"
        mouseMoveAndClick(onPoint: delta)
        
//        DispatchQueue.global(qos: .default).async {
////          _ = try? reportMouseMove(x:Int( delta.x), y: Int(delta.y))
//          _ = try? reportMouseMove(x: 5, y: 5)
//        }

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
//      self.textView.textStorage?.mutableString.append(details)
    }

  let decoder = JSONDecoder()
  
  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }


}

extension Data {
  mutating func read(from stream: InputStream) {
    let bufferSize = 1024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    while stream.hasBytesAvailable {
      let read = stream.read(buffer, maxLength: bufferSize)
      if (read == 0) {
        break  // added
      }
      self.append(buffer, count: read)
    }
    buffer.deallocate(capacity: bufferSize)
  }
}

extension ViewController : StreamDelegate {
  func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    guard let stream = aStream as? InputStream else { return }
    switch eventCode {
    case .hasBytesAvailable:
      var data = Data()
      data.read(from: stream)
      if let event = try? decoder.decode(MouseEvent.self, from: data) {
        didReceive(event: event)
      }
    case .openCompleted:
      print("Stream established!")
    case .errorOccurred:
      print("Stream failed!")

    default: break
      
    }
  }
}

extension ViewController {
  func print(_ str: String) {
    DispatchQueue.main.async {
      self.textView.textStorage?.mutableString.append("\n\(str)")
    }
  }
}


