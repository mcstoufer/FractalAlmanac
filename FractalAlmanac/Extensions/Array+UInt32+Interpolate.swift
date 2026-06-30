//
//  Array+UInt32+Interpolate.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import CoreFoundation
import UIKit


extension Array where Element == UInt32 {
    func interpolateColorScheme(steps:Int) -> [UInt32] {
        if steps <= count {
            return self
        }
        
        var interpolated = [UInt32]()
        interpolated.reserveCapacity(steps)
        
        let segmentSize = Double(steps)/Double(count)
        var baseIndexes = [Int]()
        for step in stride(from: 0, to: count, by: 1) {
            baseIndexes.append(Int((segmentSize * Double(step)).rounded(.toNearestOrAwayFromZero)))
        }
        baseIndexes[baseIndexes.count-1] = steps-1
        for (index, val) in baseIndexes.enumerated() {
            interpolated.append(self[index])
            if index == baseIndexes.count-1 {
                break
            }
            let nextVal = baseIndexes[index+1]
            let diff = nextVal - val
            if diff == 1 {
                continue
            }
            let startColor = self[index].uiColor
            let endColor = self[index+1].uiColor
            for x in 1..<diff {
                let f = CGFloat(x)/CGFloat(diff)
                interpolated.append(interpolatedColorBetweenColors(c1: startColor, c2: endColor, fraction: f))
            }
        }
        return interpolated
    }
}

func interpolatedColorBetweenColors(c1:UIColor, c2:UIColor, fraction f:CGFloat) -> UInt32 {
    let ccStart = c1.cgColor.components!
    let ccEnd = c2.cgColor.components!
    let r = ccStart[0] + (ccEnd[0] - ccStart[0]) * f
    let g = ccStart[1] + (ccEnd[1] - ccStart[1]) * f
    let b = ccStart[2] + (ccEnd[2] - ccStart[2]) * f
    let a = ccStart[3] + (ccEnd[3] - ccStart[3]) * f
    
    let bytes:[UInt8] = [UInt8(r*255.0), UInt8(g*255.0),UInt8( b*255.0), UInt8(a*255.0)]
    let bigEndianValue = bytes.withUnsafeBufferPointer {
        ($0.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0 })
    }.pointee
    let value = UInt32(bigEndian: bigEndianValue)
    return value
}
