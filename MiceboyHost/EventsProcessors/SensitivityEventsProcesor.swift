//
//  SensitivityEventsProcesor.swift
//  MiceboyHost
//
//  Created by Mykhailo Vorontsov on 9/24/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

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

