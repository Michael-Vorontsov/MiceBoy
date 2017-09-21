//
//  SubscriptionToken.swift
//  MiceBoy
//
//  Created by Mykhailo Vorontsov on 9/18/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

protocol TokenProtocol {}

class Token: TokenProtocol {
  let handler: (Any) -> Any
  init(handler: @escaping (Any) -> Any) {
    self.handler = handler
  }
}

class GToken<T, U>: TokenProtocol {
  let handler: (T) -> U
  init(handler: @escaping (T) -> U) {
    self.handler = handler
  }
}

