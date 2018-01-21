//
//  random.swift
//  HelloMetal
//
//  Created by Tony Monckton on 01/01/2018.
//
//

import Foundation

public extension Int {
  
  /// Returns a random Int point number between 0 and Int.max.
  public static var random: Int {
    return Int.random(n: Int.max)
  }
  
  /// Random integer between 0 and n-1.
  ///
  /// - Parameter n:  Interval max
  /// - Returns:      Returns a random Int point number between 0 and n max
  public static func random(n: Int) -> Int {
    return Int(arc4random_uniform(UInt32(n)))
  }
  
  ///  Random integer between min and max
  ///
  /// - Parameters:
  ///   - min:    Interval minimun
  ///   - max:    Interval max
  /// - Returns:  Returns a random Int point number between 0 and n max
  public static func random(min: Int, max: Int) -> Int {
    return Int.random(n: max - min + 1) + min
    
  }
}

// MARK: Double Extension

public extension Double {
  
  /// Returns a random floating point number between 0.0 and 1.0, inclusive.
  public static var random: Double {
    return Double(arc4random()) / 0xFFFFFFFF
  }
  
  /// Random double between 0 and n-1.
  ///
  /// - Parameter n:  Interval max
  /// - Returns:      Returns a random double point number between 0 and n max
  public static func random(min: Double, max: Double) -> Double {
    return Double.random * (max - min) + min
  }
}

// MARK: Float Extension

public extension Float {
  
  /// Returns a random floating point number between 0.0 and 1.0, inclusive.
  public static var random: Float {
    return Float(arc4random()) / 0xFFFFFFFF
  }
  
  /// Random float between 0 and n-1.
  ///
  /// - Parameter n:  Interval max
  /// - Returns:      Returns a random float point number between 0 and n max
  public static func random(min: Float, max: Float) -> Float {
    return Float.random * (max - min) + min
  }
}
