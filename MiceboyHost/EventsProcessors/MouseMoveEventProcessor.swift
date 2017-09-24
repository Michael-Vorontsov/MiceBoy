//
//  MouseMoveEventProcessor.swift
//  MiceboyHost
//
//  Created by Mykhailo Vorontsov on 9/24/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import AppKit

class QuartzEventTapMouseMoveEventProcessor: MotionEventsProcessing {
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

class DrawMouseEventProcesor: MotionEventsProcessing {
  var drawingView: PointDrawingView
  init (view: PointDrawingView) {
    drawingView = view
  }
  
  func processRemoteEvent(motionEvent: RemoteEvent) {
    guard case .move(let delta) = motionEvent else { return }

    drawingView.add(point: delta)
  }
}

class FooMouseMoveEventProcessor: MotionEventsProcessing {
  func processRemoteEvent(motionEvent: RemoteEvent) {
    guard case .move(let delta) = motionEvent else { return }
    _ = try? reportMouseMove(x: Int(delta.x), y: Int(delta.y))
  }
  
}
