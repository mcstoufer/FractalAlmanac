//
//  Color+Palette.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/15/26.
//

import SwiftUI

extension Color {
    
    func toUInt32() -> UInt32? {
        // Convert SwiftUI Color to UIColor
        let uiColor = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Extract RGBA components
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        // Map 0.0...1.0 components to 0...255 integers
        let r = UInt32(clamping: Int(red * 255))
        let g = UInt32(clamping: Int(green * 255))
        let b = UInt32(clamping: Int(blue * 255))
        let a = UInt32(clamping: Int(alpha * 255))
        
        // Combine into a single UInt32 (RGBA format: 0xRRGGBBAA)
        return (r << 24) | (g << 16) | (b << 8) | a
    }
    
    func toFloat() -> [Float] {
        let resolvedColor = self.resolve(in: EnvironmentValues())
        
        let redComponent: Float = resolvedColor.red
        let greenComponent: Float = resolvedColor.green
        let blueComponent: Float = resolvedColor.blue
        let opacityComponent: Float = resolvedColor.opacity
        return [redComponent, greenComponent, blueComponent, opacityComponent]
    }
}

extension Color: NumericColorProtocol {
    var naturalDescription: String {
        return self.toUInt32()?.description ?? "0"
    }
    
    var systemColor: Color {
        return self
    }
}
