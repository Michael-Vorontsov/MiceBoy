//
//  MotionToMoveEventsProcessor.swift
//  MiceboyHost
//
//  Created by Mykhailo Vorontsov on 9/24/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

class MotionToMoveEventsProcessor: ChainEventsProcessor {
  
  override func processRemoteEvent(motionEvent: RemoteEvent) {
    guard case .motionData(let motionData) = motionEvent else {
      super.processRemoteEvent(motionEvent: motionEvent)
      return
    }
    
    let mouseMovement = CGPoint(x: -motionData.rotationChange.z, y: motionData.rotationChange.x)
    super.processRemoteEvent(motionEvent: .move(delta: mouseMovement))
  }
}
