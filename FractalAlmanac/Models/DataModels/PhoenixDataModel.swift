//
//  PhoenixDataModel.swift
//  Fractal
//
//  Created by Martin Stoufer on 8/25/20.
//

import Foundation

final class PhoenixDataModel: JuliaDataModel {
    
    var coloringTechnique: String?
    
    required init(withExtents extents:ConvolutionalExtent, listener:DataModelRenderProtocol?) {
        super.init(withExtents: extents, listener: listener)
    }
    
    override func assemble() async -> Data {
        rendering = true
        
        let deltaX = (currentExtent.YMax - currentExtent.YMin)/(Double(bufferSize.height) - 1.0)
        let deltaXi = (currentExtent.XMax - currentExtent.XMin)/(Double(bufferSize.width) - 1.0)
        let maxSize:Double = 4.0
        let YSquare = 0.0
        
        var XSquare:Double
        var XiSquare:Double
        var Y:Double
        var Yi:Double
        var X:Double
        var Xi:Double
        var colorIndex = 0
        var XTemp:Double
        var XiTemp:Double
        
        pixelData.removeAll()
        wideBuffer = [Data](repeating: Data(), count: Int(bufferSize.width))
        
        let colorCount = colorPalette.colorSchemeColors().count
        let colorStep = Double(maxIters)/Double(colorCount).rounded(.awayFromZero)
        
        for col in 0..<Int(bufferSize.width) {
            for row in 0..<Int(bufferSize.height) {
                Y = 0
                Yi = 0
                X = currentExtent.YMax - Double(row) * deltaX
                Xi = currentExtent.XMin + Double(col) * deltaXi
                colorIndex = 0
                XSquare = 0
                XiSquare = 0
                while colorIndex < maxIters && (XSquare + XiSquare) < maxSize{
                    XSquare = X * X
                    XiSquare = Xi * Xi
                    XTemp = XSquare - XiSquare + P + Q * Y
                    XiTemp = 2 * X * Xi + Q * Yi
                    Y = X
                    Yi = Xi
                    X = XTemp
                    Xi = XiTemp
                    colorIndex += 1
                }
                
                if coloringTechnique == "Mandelbrot" {
                    var resolvedColorIndex = colorIndex % colorCount
                    if colorIndex >= maxIters {
                        resolvedColorIndex = colorCount-1 // Default to black
                    } else if resolvedColorIndex == colorCount-1 {
                        resolvedColorIndex = 0 // Reset back to first color if we are going to use black here.
                    }
                    colorIndex = resolvedColorIndex
                } else if coloringTechnique == "Julia" {
                    if colorIndex >= maxIters {
                        colorIndex = ( Int((XSquare + YSquare) * Double(colorCount-1)) % colorCount-1) + 1
                        if colorIndex == colorCount - 1 {
                            colorIndex = 0
                        }
                    } else {
                        colorIndex = colorCount - 1 // Reset back to first color if we are going to use black here.
                    }
                } else {
                    if colorIndex >= maxIters {
                        colorIndex = 0
                    } else if colorIndex <= 16 {
                        colorIndex = colorCount-1
                    }
                    else {
                        colorIndex = Int(ceilf(Float(colorIndex)/Float(colorStep)))-1
                        if colorIndex == 0 {
                            colorIndex = colorCount-1
                        }
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
