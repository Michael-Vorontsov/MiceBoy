//
//  PointDrawingView.swift
//  MiceboyHost
//
//  Created by Mykhailo Vorontsov on 9/21/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Cocoa

extension CGRect {
  var center: CGPoint {
    get {
      return CGPoint(x: round(origin.x + size.width / 2.0), y: round(origin.y + size.height / 2.0))
    }
  }
}

class PointDrawingView: NSView {

  var lastPoint: NSPoint?
  
  let bezierPath = NSBezierPath()
  
  func reset() {
    lastPoint = bounds.center
    NSColor(
      calibratedRed: CGFloat(arc4random()) / CGFloat(RAND_MAX),
      green: CGFloat(arc4random()) / CGFloat(RAND_MAX),
      blue: CGFloat(arc4random()) / CGFloat(RAND_MAX),
      alpha: 1.0
      ).setStroke()
    bezierPath.removeAllPoints()
    bezierPath.move(to: lastPoint!)
    setNeedsDisplay(self.bounds)
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    reset()
  }
  
  func add(point: NSPoint) {
    let lastPoint = self.lastPoint ?? bounds.center

    let screenSize = NSScreen.main!.frame.size
    let aspectRation = NSPoint(x: bounds.size.width / screenSize.width, y: -bounds.size.height / screenSize.height)
    
    var pointToDraw = NSPoint(x: point.x * aspectRation.x , y: point.y * aspectRation.y)
    pointToDraw.x += lastPoint.x
    pointToDraw.y += lastPoint.y
    pointToDraw.x = max( min(pointToDraw.x,bounds.size.width), 0.0)
    pointToDraw.y = max( min( pointToDraw.y, bounds.size.height), 0.0)
    self.lastPoint = pointToDraw
    
//    var point = point
    
    if bezierPath.isEmpty {
      bezierPath.move(to: pointToDraw)
    }
    else {
      let oldPoint = bezierPath.currentPoint
      bezierPath.line(to: pointToDraw)
      let minX = min(oldPoint.x, pointToDraw.x)
      let minY = min(oldPoint.x, pointToDraw.y)
      setNeedsDisplay(NSRect(x: minX, y: minY, width: max(oldPoint.x, pointToDraw.x) - minX, height: max(oldPoint.y, pointToDraw.y) - minY))
    }
  }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        bezierPath.stroke()
//        self.layer.conte

        // Drawing code here.
    }
    
}
