//
//  RemoteEvent.swift
//  MiceBoy
//
//  Created by Mykhailo Vorontsov on 9/18/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import CoreGraphics

enum RemoteEvent: Codable {
  enum ButtonType: Int, Codable {
    case left
    case right
  }
  
  enum ButtonState: Int, Codable {
    case up
    case down
  }
  
  case move(delta: CGPoint)
  case button(ButtonType, state: ButtonState)
  case motionData(motion: MotionData)
  case pause(Bool)
}

extension RemoteEvent {
  
  struct Vector: Codable {
    let x: Double
    let y: Double
    let z: Double
  }
  
  struct MotionData: Codable {
    let gravity: Vector
    let rotationChange: Vector
    let acceleration: Vector
    //TODO: Add alt parameters
  }
  
  
//  fileprivate
  enum CodingKeys: String, CodingKey {
    case move
    case button
    case motion
    case pause
  }
  
  enum RemoteEventError: Error {
    case decoding
  }
  
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    if let value = try? values.decode(CGPoint.self, forKey: .move) {
      self = .move(delta: value)
      return
    }
    if
      let value = try? values.decode(Int.self, forKey: .button),
      let typeValue = ButtonType(rawValue: value >> 4),
      let stateValue = ButtonState(rawValue: value & 0xffff) {
      
      self = .button(typeValue, state: stateValue)
      return
    }
    if let value = try? values.decode(MotionData.self, forKey: .motion) {
      self = .motionData(motion: value)
      return
    }
    if let value = try? values.decode(Bool.self, forKey: .pause) {
      self = RemoteEvent.pause(value)
      return
    }
    
    throw RemoteEventError.decoding
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .move(let delta):
      try container.encode(delta, forKey: .move)
    case .button(let type, let state):
      let mixedCode = type.rawValue << 4 + state.rawValue
      try container.encode(mixedCode, forKey: .button)
    case .motionData(let motion):
      try container.encode(motion, forKey: .motion)
    case .pause(let value):
      try container.encode(value, forKey: .pause)
    }
    
  }
}
