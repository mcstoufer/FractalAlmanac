//
//  Double+Shader.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/22/26.
//

extension Double {
    var splitDouble: (hi: Float, lo: Float) {
        let hi = Float(self)
        let lo = Float(self - Double(hi))
        return (hi, lo)
    }
}
