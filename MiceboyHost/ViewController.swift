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
  
  var sensitivity = 10.0
  
  @IBAction func changeSensitivity(_ sender: NSSlider) {
    sensitivity = sender.doubleValue
  }
  
  let connectionService = ConnectionAdvertiser(peerName: "miceboy-host")
  
  var session: ConnectionSessionManager? {
    didSet {
      guard let session = session else { return }
      
      self.tokens.append( session.subscribe {[unowned self] (mouseEvent: RemoteEvent) in
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
  
  var eventsProcessor: MotionEventsProcessing?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupEventsProcessor()
    tokens.append(connectionService.subscribe { [unowned self] (peerInvitation) in
      DispatchQueue.main.async {
        self.textView.textStorage?.mutableString.append("\n Accpeting invitation from:\(peerInvitation.peerName)")
        self.session = try? self.connectionService.accept(invitation: peerInvitation)
      }
    })
    
    
    
    connectionService.startAdvertising()
    
    
    // Do any additional setup after loading the view.
  }
  
  var observationTokens = [NSKeyValueObservation]()
  
  func setupEventsProcessor() {
//    let mouseMovement =  FooMouseMoveEventProcessor()
    let mouseMovement =  QuartzEventTapMouseMoveEventProcessor()
//    let mouseMovement =  DrawMouseEventProcesor(view: drawingView)
    
    let accumulator = AccumulatedMoveEventsProcessor(nextProcessor: mouseMovement)
    let sensitivity = SensitivityEventsProcesor(nextProcessor: accumulator)

//    observationTokens.append(self.observe(\.sensitivity) { (controller, value) in
//      sensitivity.sensitivity = CGFloat(controller.sensitivity)
//    })
    
    let motionProcessor = MotionToMoveEventsProcessor(nextProcessor: sensitivity)
    let pauseProcessor = PauseEventsProcessor(nextProcessor: motionProcessor)
    eventsProcessor = pauseProcessor
  }
  
  
  @IBAction func reset(_ sender: Any) {
    drawingView.reset()
  }
  
  var pause = false
  
  func didReceive(event: RemoteEvent) {
    
    self.eventsProcessor?.processRemoteEvent(motionEvent: event)
    if let pauseProcessor = self.eventsProcessor as? PauseEventsProcessor {
      pauseProcessor.processRemoteEvent(motionEvent: event)
    }
  }
  
  let decoder = JSONDecoder()
  
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
      if let event = try? decoder.decode(RemoteEvent.self, from: data) {
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


