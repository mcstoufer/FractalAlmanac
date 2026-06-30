//
//  UIInt32+Color.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import UIKit


extension UInt32 {
    var uiColor: UIColor {
        let red = (CGFloat) ( (self>>24)&0xFF )
        let green = (CGFloat) ( (self>>16)&0xFF )
        let blue = (CGFloat) ( (self>>8)&0xFF )
        let alpha = (CGFloat) ( (self)&0xff)
        
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: alpha)
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
