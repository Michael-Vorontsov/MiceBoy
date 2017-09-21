//
//  DataMapper.swift
//  MiceBoy
//
//  Created by Mykhailo Vorontsov on 9/18/17.
//  Copyright © 2017 Mykhailo Vorontsov. All rights reserved.
//

import Foundation


protocol Mapping {
  func map(data: Data) throws -> Codable
}

class Mapper<T: Codable>: Mapping {
  
  func map(data: Data) throws -> Codable {
    return try JSONDecoder().decode(T.self, from: data)
  }
}
