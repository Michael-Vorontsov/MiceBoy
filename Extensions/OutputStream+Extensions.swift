//
//  OutputStream+Extensions.swift
//  MiceBoy
//
//  Created by Mykhailo Vorontsov on 9/26/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation

private let encoder = JSONEncoder()

extension OutputStream {
  
  func send<T: Codable>(object:T) {
    let data = try! encoder.encode(object)
    
    _ = data.withUnsafeBytes {
      self.write($0, maxLength: data.count)
    }
  }
  
}
