//
//  JuliaDataModel.swift
//  Fractal
//
//  Created by Martin Stoufer on 8/24/20.
//

import Foundation
import UIKit

class JuliaDataModel: FractalDataModel {
    var P:Double = 0
    var Q:Double = 0
    
    required init(withExtents extents:ConvolutionalExtent, listener:DataModelRenderProtocol?) {
        super.init(withExtents: extents, listener: listener)
    }
    
    override func assemble() async -> Data {
        rendering = true
        
        var X:Double
        var Y:Double
        var XSquare:Double
        var YSquare:Double
        var colorIndex:Int
        let maxSize:Double = 4.0
        
        pixelData.removeAll()
        wideBuffer = [Data](repeating: Data(), count: Int(bufferSize.width))
        
        let deltaX = (currentExtent.XMax - currentExtent.XMin)/Double(bufferSize.width)
        let deltaY = (currentExtent.YMax - currentExtent.YMin)/Double(bufferSize.height)
        
        let colorCount = colorPalette.schemeColors().count
        for col in 0..<Int(bufferSize.width) {
            for row in 0..<Int(bufferSize.height) {
                X = currentExtent.XMin + (Double(col) * deltaX)
                Y = currentExtent.YMax - (Double(row) * deltaY)
                XSquare = 0
                YSquare = 0
                colorIndex = 0
                
                while colorIndex < maxIters && (XSquare + YSquare) < maxSize {
                    XSquare = X * X
                    YSquare = Y * Y
                    Y = (2 * X * Y) + Q
                    X = XSquare - YSquare + P
                    colorIndex += 1
                }
                
                if colorIndex >= maxIters {
                    colorIndex = ( Int((XSquare + YSquare) * Double(colorCount-1)) % colorCount-1) + 1
                    if colorIndex == colorCount - 1 {
                        colorIndex = 0
                    }
                } else {
                    colorIndex = colorCount - 1 // Reset back to first color if we are going to use black here.
                }
                writeToBuffer(col: col, colorIndex: colorIndex)
            }
            await renderingListener?.updateRenderingProgress(progress: Float(col) / Float(bufferSize.height))
        }
        
        coallesceData()
        rendering = false
        return pixelData
    }
}
