//
//  FractalDataModel.swift
//  Fractal
//
//  Created by Martin Stoufer on 8/13/20.
//

import Foundation
import UIKit

final class MandelbrotDataModel: FractalDataModel {
    private var Q = [Double]()
    
    required init(withExtents extents:ConvolutionalExtent, listener:DataModelRenderProtocol?) {
        super.init(withExtents: extents, listener: listener)
        Q.reserveCapacity(Int(extents.bufferSize.width))
        model = .Mandelbrot
    }
    
    override func assemble() async -> Data {
        rendering = true
        
        Q.removeAll()
        pixelData.removeAll()
        
        wideBuffer = [Data](repeating: Data(), count: Int(bufferSize.width))

        let deltaP = (currentExtent.XMax - currentExtent.XMin)/Double(bufferSize.width)
        let deltaQ = (currentExtent.YMax - currentExtent.YMin)/Double(bufferSize.height)
        
        var X:Double
        var Y:Double
        var XSquare:Double
        var YSquare:Double
        var colorIndex:Int
        let maxSize:Double = 4.0
        var P:Double = currentExtent.XMin
        Q.append(currentExtent.YMax)
        for _ in 1...Int(bufferSize.height) {
            if let lastValue = Q.last {
                Q.append(lastValue - deltaQ)
            }
        }
        
        let colorCount = colorPalette.colorSchemeColors().count
        for col in 0..<Int(bufferSize.width) {
            for row in 0..<Int(bufferSize.height) {
                X = 0
                Y = 0
                XSquare = 0
                YSquare = 0
                colorIndex = 0
                while (colorIndex < maxIters) && ((XSquare + YSquare) < maxSize) {
                    XSquare = X * X
                    YSquare = Y * Y
                    Y *= X
                    Y += Y + Q[row]
                    X = XSquare - YSquare + P
                    colorIndex += 1
                }
                var resolvedColorIndex = colorIndex % colorCount
                if colorIndex == maxIters {
                    resolvedColorIndex = colorCount-1 // Default to black
                } else if resolvedColorIndex == colorCount-1 {
                    resolvedColorIndex = 0 // Reset back to first color if we are going to use black here.
                }
                writeToBuffer(col: col, colorIndex: resolvedColorIndex)
            }
            P += deltaP
            await renderingListener?.updateRenderingProgress(progress: Float(col) / Float(bufferSize.height))
        }
        coallesceData()
        rendering = false
        return pixelData
    }
}
