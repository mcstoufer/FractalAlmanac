//
//  Extents.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//
import UIKit

/**
 Performance here is limited by decimal point accuracy of the Double. For x86_64 platforms, we could of used the Float80.
 That gives us virtually unlimited zooming power.
 */
struct Extent {
    var XMin:Double
    var XMax:Double
    var YMin:Double
    var YMax:Double
    
    static func newExtentFrom(rect:CGRect) -> Extent {
        return rect.toExtent()
    }
    
    func scaleExtent(withMinXScale xMinOffsetScale:Double,
                     withMaxXScale xMaxOffsetScale:Double,
                     withMinYScale yMinOffsetScale:Double,
                     withMaxYScale yMaxOffsetScale:Double,
                     withXSpan XSpan:Double,
                     withYSpan YSpan:Double) -> Extent {
        return Extent(XMin: XMin+(xMinOffsetScale * XSpan),
                      XMax: XMax-(xMaxOffsetScale * XSpan),
                      YMin: YMin+(yMinOffsetScale * YSpan),
                      YMax: YMax-(yMaxOffsetScale * YSpan))
    }
    
    func convertToStorable() -> [Double] {
        return [XMin, XMax, YMin, YMax]
    }
}

struct ConvolutionalExtent {
    var bufferSize:CGSize
    var maxIters:Int
    var defaultSpan:Double
    var minXExtent:Double
    var minYExtent:Double
}
