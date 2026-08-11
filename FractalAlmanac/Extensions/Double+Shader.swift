//
//  Double+Shader.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/22/26.
//
import Foundation

extension Double {
    static let splitMultiplier: Double = {
        return 16777216.0 + 1.0
    }()
    
    var splitDouble: (hi: Double, lo: Double) {
        let c = self * Double.splitMultiplier
        let hi = c - (c - self)
        let lo = self - hi
        return (hi, lo)
    }
    
    var splitSIMD2: SIMD2<Float> {
        let hi = Float(self)
        let lo = Float(self - Double(hi))
        return SIMD2<Float>(hi, lo)
    }
}
