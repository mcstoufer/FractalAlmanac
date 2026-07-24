//
//  FractalModelFactory.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import Foundation
import UIKit
import SwiftUI

enum FractalModel: String, CaseIterable, Identifiable {
    var id: Self { self }

    case Mandelbrot = "Mandelbrot"
    case JuliaA = "Julia 'A'"
    case JuliaB = "Julia 'B'"
    case JuliaC = "Julia 'C'"
    case JuliaD = "Julia 'D'"
    case JuliaG = "Julia 'G'"
    case JuliaH = "Julia 'H'"
    case JuliaL = "Julia 'L'"
    case JuliaN = "Julia 'N'"
    case JuliaO = "Julia 'O'"
    case Dragon = "Dragon"
    case SanMarcos = "San Marcos"
    case Phoenix = "Phoenix"
    case PhoenixM = "Phoenix 'M'"
    case PhoenixJ = "Phoenix 'J'"
}

extension FractalModel {
    
//    func indexPath() -> IndexPath {
//        let row = FractalModel.allCases.firstIndex(of: self) ?? 0
//        return IndexPath(row: row, section: 0)
//    }
//    
    func newShader(cyclePalette: Bool,
                   activePalette: [Float],
                   size canvasSize: CGSize,
                   dx: Double, dy: Double,
                   activeCenterReal: Double,
                   activeCenterImag: Double) -> Shader {
        let dxSplit = dx.splitDouble
        let dySplit = dy.splitDouble
        let cRealSplit = activeCenterReal.splitDouble
        let cImagSplit = activeCenterImag.splitDouble
        
        let shaderArguments = [
            .float4(cRealSplit.hi, cRealSplit.lo, 0.0, 0.0), // Center Real
            .float4(cImagSplit.hi, cImagSplit.lo, 0.0, 0.0), // Center Imag
            .float4(dxSplit.hi, dxSplit.lo, dySplit.hi, dySplit.lo), // Step delta sizes
            self.cConstants,
            .float2(Float(canvasSize.width), Float(canvasSize.height)),
            self.iterationCount,
            .float(cyclePalette ? 1.0 : 0.0),
            .floatArray(activePalette)
        ]
        
        switch self {
            case .Mandelbrot:
                return Shader(function: ShaderLibrary.mandelbrot, arguments: shaderArguments)
            case .JuliaA, .JuliaB, .JuliaC, .JuliaD, .JuliaG, .JuliaH, .JuliaL, .JuliaN, .JuliaO:
                return Shader(function: ShaderLibrary.julia, arguments: shaderArguments)
            default:
                return Shader(function: ShaderLibrary.mandelbrot, arguments: shaderArguments)
        }
    }
    
    static func initialCenter(model: FractalModel) -> (centerReal: Double, centerImag: Double) {
        switch model {
            case .Mandelbrot:
                return (-0.7, 0.0)
            case .JuliaA:
                return (0.0, 0.0)
            default:
                return (0.0, 0.0)
        }
    }
    
    var cConstants: Shader.Argument {
        switch self {
            case .JuliaA:
                return .float4(0.238498, 0.0, 0.519198, 0.0)
            case .JuliaB:
                return .float4(-0.743036, 0.0, 0.113467, 0.0)
            case .JuliaC:
                return .float4(-0.192175, 0.0, 0.656734, 0.0)
            case .JuliaD:
                return .float4(0.108294, 0.0, -0.670487, 0.0)
            case .JuliaG:
                return .float4(0.138341, 0.0, 0.649857, 0.0)
            case .JuliaH:
                return .float4(0.278560, 0.0, -0.003483, 0.0)
            case .JuliaL:
                return .float4(0.268545, 0.0, -0.003483, 0.0)
            case .JuliaN:
                return .float4(0.318623, 0.0, -0.044699, 0.0)
            case .JuliaO:
                return .float4(0.318623, 0.0, -0.429799, 0.0)
            default:
                return .float4(0.0, 0.0, 0.0, 0.0)
        }
    }
    
    var iterationCount: Shader.Argument {
        switch self {
            case .Mandelbrot:
                return .float2(150, 0)
            case .JuliaA:
                return .float2(128, 0)
            case .JuliaB:
                return .float2(96, 0)
            case .JuliaC:
                return .float2(64, 0)
            case .JuliaD:
                return .float2(32, 0)
            case .JuliaG:
                return .float2(32, 0)
            case .JuliaH:
                return .float2(24, 0)
            case .JuliaL:
                return .float2(64, 0)
            case .JuliaN:
                return .float2(256, 0)
            case .JuliaO:
                return .float2(48, 0)
            default:
                return .float2(150, 0)
        }
    }
    
//    func newDataModel(forSize size:CGSize, listener:DataModelRenderProtocol) -> FractalDataModel {
//        switch self {
//            case .Mandelbrot:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 512, defaultSpan: 2.8, minXExtent: -2.1, minYExtent: -1.4)
//                return MandelbrotDataModel(withExtents: extents, listener: listener)
//                
//            case .JuliaA:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 128, defaultSpan: 2.8, minXExtent: -1.4, minYExtent: -1.4)
//                let jModel = JuliaDataModel(withExtents: extents, listener: listener)
//                jModel.P = 0.238498
//                jModel.Q = 0.519198
//                jModel.model = self
//                return jModel
//                
//            case .JuliaB:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 96, defaultSpan: 3.2, minXExtent: -1.6, minYExtent: -1.6)
//                let jModel = JuliaDataModel(withExtents: extents, listener: listener)
//                jModel.P = -0.743036
//                jModel.Q = 0.113467
//                jModel.model = self
//                return jModel
//                
//            case .JuliaC:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 64, defaultSpan: 3.2, minXExtent: -1.6, minYExtent: -1.6)
//                let jModel = JuliaDataModel(withExtents: extents, listener: listener)
//                jModel.P = -0.192175
//                jModel.Q = 0.656734
//                jModel.model = self
//                return jModel
//                
//            case .JuliaD:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 32, defaultSpan: 2.8, minXExtent: -1.4, minYExtent: -1.4)
//                let jModel = JuliaDataModel(withExtents: extents, listener: listener)
//                jModel.P = 0.108294
//                jModel.Q = -0.670487
//                jModel.model = self
//                return jModel
//                
//            case .JuliaG:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 32, defaultSpan: 2.8, minXExtent: -1.4, minYExtent: -1.4)
//                let jModel = JuliaDataModel(withExtents: extents, listener: listener)
//                jModel.P = 0.138341
//                jModel.Q = 0.649857
//                jModel.model = self
//                return jModel
//                
//            case .JuliaH:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 24, defaultSpan: 2.8, minXExtent: -1.4, minYExtent: -1.4)
//                let jModel = JuliaDataModel(withExtents: extents, listener: listener)
//                jModel.P = 0.278560
//                jModel.Q = -0.003483
//                jModel.model = self
//                return jModel
//                
//            case .JuliaL:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 64, defaultSpan: 0.5, minXExtent: -0.673239, minYExtent: 0.178928)
//                let jModel = JuliaDataModel(withExtents: extents, listener: listener)
//                jModel.P = 0.268545
//                jModel.Q = -0.003483
//                jModel.model = self
//                return jModel
//                
//            case .JuliaN:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 256, defaultSpan: 2.6, minXExtent: -1.3, minYExtent: -1.3)
//                let jModel = JuliaDataModel(withExtents: extents, listener: listener)
//                jModel.P = 0.318623
//                jModel.Q = -0.044699
//                jModel.model = self
//                return jModel
//                
//            case .JuliaO:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 48, defaultSpan: 2.8, minXExtent: -1.4, minYExtent: -1.4)
//                let jModel = JuliaDataModel(withExtents: extents, listener: listener)
//                jModel.P = 0.318623
//                jModel.Q = -0.429799
//                jModel.model = self
//                return jModel
//                
//            case .Dragon:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 256, defaultSpan: 1.4, minXExtent: -0.2, minYExtent: -0.7)
//                let dModel = DragonDataModel(withExtents: extents, listener: listener)
//                dModel.P = 1.646009
//                dModel.Q = 0.967049
//                dModel.model = self
//                return dModel
//                
//            case .SanMarcos:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 64, defaultSpan: 1.8, minXExtent: -0.4, minYExtent: -0.9)
//                let dModel = DragonDataModel(withExtents: extents, listener: listener)
//                dModel.P = 2.998122
//                dModel.Q = 0.004298
//                dModel.renderAsSanMarcos = true
//                dModel.model = self
//                return dModel
//                
//            case .Phoenix:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 128, defaultSpan: 3.0, minXExtent: -1.5, minYExtent: -1.5)
//                let pModel = PhoenixDataModel(withExtents: extents, listener: listener)
//                pModel.P = 0.56667
//                pModel.Q = -0.5
//                pModel.model = self
//                return pModel
//                
//            case .PhoenixM:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 64, defaultSpan: 3.0, minXExtent: -1.5, minYExtent: -1.5)
//                let pModel = PhoenixDataModel(withExtents: extents, listener: listener)
//                pModel.P = 0.356338
//                pModel.Q = -1.209169
//                pModel.coloringTechnique = "Mandelbrot"
//                pModel.model = self
//                return pModel
//                
//            case .PhoenixJ:
//                let extents = ConvolutionalExtent(bufferSize: size, maxIters: 8, defaultSpan: 3.0, minXExtent: -1.5, minYExtent: -1.5)
//                let pModel = PhoenixDataModel(withExtents: extents, listener: listener)
//                pModel.P = 0.356338
//                pModel.Q = -1.209169
//                pModel.coloringTechnique = "Julia"
//                pModel.model = self
//                return pModel
//        }
//    }
}
