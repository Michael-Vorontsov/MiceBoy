//
//  PauseEventsProcessor.swift
//  MiceboyHost
//
//  Created by Mykhailo Vorontsov on 9/24/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

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
