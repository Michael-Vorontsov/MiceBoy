//
//  MouseEvent.swift
//  MiceBoy
//
//  Created by Mykhailo Vorontsov on 9/18/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation
import CoreGraphics

enum MouseEvent: Codable {
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
}

extension MouseEvent {
//  fileprivate
  enum CodingKeys: String, CodingKey {
    case move
    case button
  }
  
  enum MouseEventError: Error {
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
    throw MouseEventError.decoding
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case .move(let delta):
      try container.encode(delta, forKey: .move)
    case .button(let type, let state):
      let mixedCode = type.rawValue << 4 + state.rawValue
      try container.encode(mixedCode, forKey: .button)
    }
    
  }
}
