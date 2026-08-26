//
//  UIInt32+Color.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 6/29/26.
//

import UIKit
import SwiftUI


extension UInt32 {
    var uiColor: UIColor {
        let red = (CGFloat) ( (self>>24)&0xFF ) / 255.0
        let green = (CGFloat) ( (self>>16)&0xFF ) / 255.0
        let blue = (CGFloat) ( (self>>8)&0xFF ) / 255.0
        let alpha = (CGFloat) ( (self)&0xff) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    var systemColor: Color {
        let red = (CGFloat) ( (self>>24)&0xFF ) / 255.0
        let green = (CGFloat) ( (self>>16)&0xFF ) / 255.0
        let blue = (CGFloat) ( (self>>8)&0xFF ) / 255.0
        let alpha = (CGFloat) ( (self)&0xff) / 255.0

        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    var shaderColor: [Float] {
        return [
            Float((self>>24)&0xFF) / 255.0,
            Float((self>>16)&0xFF) / 255.0,
            Float((self>>8)&0xFF) / 255.0,
            Float((self)&0xff) / 255.0
        ]
    }
    
    var hue: Int {
        let red = (CGFloat) ( (self>>24)&0xFF )
        let green = (CGFloat) ( (self>>16)&0xFF )
        let blue = (CGFloat) ( (self>>8)&0xFF )
        
        let minC = Swift.min(Swift.min(red, green), blue)
        let maxC = Swift.max(Swift.max(red, green), blue)
        
        if (minC == maxC) {
            return 0
        }
        var hue:CGFloat = 0
        if (maxC == red) {
            hue = (green - blue) / (maxC - minC)
        } else if (maxC == green) {
            hue = 2.0 + (blue - red) / (maxC - minC)
        } else {
            hue = 4.0 + (red - green) / (maxC - minC)
        }
        
        hue = hue * 60
        if (hue < 0) {
            hue += 360
        }
        
        return Int(hue.rounded(.toNearestOrAwayFromZero))
    }
}
