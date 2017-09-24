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


