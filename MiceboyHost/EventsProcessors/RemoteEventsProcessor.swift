//
//  RemoteEventsProcessor.swift
//  MiceboyHost
//
//  Created by Mykhailo Vorontsov on 9/24/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Cocoa

protocol MotionEventsProcessing: class {
  func processRemoteEvent(motionEvent: RemoteEvent)
}

class ChainEventsProcessor: MotionEventsProcessing {
  
  private let subsquentProcessor: MotionEventsProcessing
  
  init(nextProcessor: MotionEventsProcessing) {
    subsquentProcessor = nextProcessor
  }
  
  func processRemoteEvent(motionEvent: RemoteEvent) {
    subsquentProcessor.processRemoteEvent(motionEvent: motionEvent)
  }
  
}

class MotionToMoveEventsProcessor: ChainEventsProcessor {

  override func processRemoteEvent(motionEvent: RemoteEvent) {
    guard case .motionData(let motionData) = motionEvent else {
      super.processRemoteEvent(motionEvent: motionEvent)
      return
    }
    
    let mouseMovement = CGPoint(x: -motionData.rotationChange.z, y: -motionData.rotationChange.x)
    super.processRemoteEvent(motionEvent: .move(delta: mouseMovement))
  }
}

class AccumulatedMoveEventsProcessor: ChainEventsProcessor {
  
  var accumulatedMouseMovement: NSPoint = NSPoint.zero
  var timer: Timer?
  var threshold: CGFloat = 25
  
  var power: CGFloat {return accumulatedMouseMovement.x * accumulatedMouseMovement.x + accumulatedMouseMovement.y * accumulatedMouseMovement.y }
  
  func submitAccumulatedMousePosition() {
    guard power > threshold else {
      timer?.invalidate()
      timer = nil
      return
    }
    super.processRemoteEvent(motionEvent: .move(delta: accumulatedMouseMovement))
  }
  
  override func processRemoteEvent(motionEvent: RemoteEvent) {
    
    switch motionEvent {
    case .move(let delta):
      accumulatedMouseMovement.x += delta.x
      accumulatedMouseMovement.y += delta.y
      
      guard nil == timer, power > threshold else {
        return
      }
      timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] (timer) in
          self?.submitAccumulatedMousePosition()
          // Stop timer if self released
          if nil == self { timer.invalidate() }
      })
    case .pause(_):
      accumulatedMouseMovement = NSPoint.zero
      timer?.invalidate()
      timer = nil
      super.processRemoteEvent(motionEvent: motionEvent)
    default:
      super.processRemoteEvent(motionEvent: motionEvent)
    }
    
  }
}

/// Trap all events if in pause ( except .pause events)
class PauseEventsProcessor: ChainEventsProcessor {
  var pause = false
  override func processRemoteEvent(motionEvent: RemoteEvent) {
    guard case .pause(let value) = motionEvent else {
      if false == self.pause {
        super.processRemoteEvent(motionEvent: motionEvent)
      }
      return
    }
    pause = value
    super.processRemoteEvent(motionEvent: motionEvent)
  }
  
}

class SensitivityEventsProcesor: ChainEventsProcessor {

  var sensitivity: CGFloat = 10.0
  override func processRemoteEvent(motionEvent: RemoteEvent) {
    guard case .move(let delta) = motionEvent else {
      super.processRemoteEvent(motionEvent: motionEvent)
      return
    }
    super.processRemoteEvent(motionEvent: .move(delta: CGPoint(x: delta.x * sensitivity, y: delta.y * sensitivity)))
  }
}

class MouseMoveEventProcessor: MotionEventsProcessing {
  func processRemoteEvent(motionEvent: RemoteEvent) {
    guard case .move(let delta) = motionEvent else { return }
    let currentPostion = NSEvent.mouseLocation
    let destination = NSPoint(x: currentPostion.x + delta.x, y: NSScreen.main!.frame.size.height - currentPostion.y + delta.y)
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

}

