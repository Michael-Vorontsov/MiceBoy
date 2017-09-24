//
//  MouseMoveEventProcessor.swift
//  MiceboyHost
//
//  Created by Mykhailo Vorontsov on 9/24/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import AppKit

class MouseMoveEventProcessor: MotionEventsProcessing {
  func processRemoteEvent(motionEvent: RemoteEvent) {
    guard case .move(let delta) = motionEvent else { return }
    let currentPostion = NSEvent.mouseLocation
    let destination = NSPoint(
      x: currentPostion.x + delta.x,
      y: NSScreen.main!.frame.size.height - (currentPostion.y + delta.y)
    )
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
