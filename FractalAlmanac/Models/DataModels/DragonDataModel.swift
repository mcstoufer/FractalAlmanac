//
//  DragonDataModel.swift
//  Fractal
//
//  Created by Martin Stoufer on 8/25/20.
//

import Foundation
import UIKit

final class DragonDataModel: JuliaDataModel {
    
    var renderAsSanMarcos = false
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
        var temp_sq:Double
        var temp_xy:Double
        var YTemp:Double
        
        let maxSize:Double = 4.0
        
        pixelData.removeAll()
        wideBuffer = [Data](repeating: Data(), count: Int(bufferSize.width))
        
        let deltaX = (currentExtent.XMax - currentExtent.XMin)/Double(bufferSize.width)
        let deltaY = (currentExtent.YMax - currentExtent.YMin)/Double(bufferSize.height)
        
        let colorCount = colorPalette.schemeColors().count
        for col in 0..<Int(bufferSize.width) {
            for row in 0..<Int(bufferSize.height) {
                X = currentExtent.XMin + Double(col) * deltaX
                Y = currentExtent.YMax - Double(row) * deltaY
                XSquare = 0
                YSquare = 0
                colorIndex = 0
                
                while colorIndex < maxIters && (XSquare + YSquare) < maxSize {
                    XSquare = X * X
                    YSquare = Y * Y
                    temp_sq = YSquare - XSquare
                    temp_xy = 2 * X * Y
                    YTemp = (Q * (temp_sq + X)) - (P * (temp_xy - Y))
                    X = (P * (temp_sq + X)) + (Q * (temp_xy - Y))
                    Y = YTemp
                    colorIndex += 1
                }
                
                if renderAsSanMarcos {
                    if  colorIndex >= maxIters {
                        colorIndex = ( Int((XSquare + YSquare) * 100.0) % colorCount-1) + 1
                    } else {
                        colorIndex = colorCount-1
                    }
                    if CGFloat(row) < bufferSize.height/2.0 {
                        colorIndex = (colorIndex + colorCount/2) % colorCount
                    }
                } else {
                    if  colorIndex >= maxIters {
                        colorIndex = ( Int((XSquare + YSquare) * Double(colorCount-1)) % colorCount-1) + 1
                    } else {
                        colorIndex = colorCount-1
                    }
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
