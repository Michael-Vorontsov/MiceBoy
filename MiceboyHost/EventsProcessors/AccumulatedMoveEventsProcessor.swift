//
//  AccumulatedMoveEventsProcessor.swift
//  MiceboyHost
//
//  Created by Mykhailo Vorontsov on 9/24/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

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
