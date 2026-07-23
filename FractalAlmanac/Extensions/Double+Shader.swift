//
//  Double+Shader.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/22/26.
//

extension Double {
    var splitDouble: (hi: Double, lo: Double) {
        let splitMultiplier = 16777216.0 + 1.0
        
        let c = self * splitMultiplier
        let hi = c - (c - self)
        let lo = self - hi
        return (hi, lo)
    }
}
