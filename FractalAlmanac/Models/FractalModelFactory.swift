//
//  FractalModelFactory.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 6/29/26.
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

    func syntheticShaderArguments(cyclePalette: PaletteCycleStyle,
                                  activePalette: [Float],
                                  size canvasSize: CGSize,
                                  dx: Double, dy: Double,
                                  activeCenterReal: Double,
                                  activeCenterImag: Double) -> [Shader.Argument] {
        let dxSplit = dx.splitDouble
        let dySplit = dy.splitDouble
        let cRealSplit = activeCenterReal.splitDouble
        let cImagSplit = activeCenterImag.splitDouble
        let tuningData = Float(shaderIterationCount(dx: dx, canvasWidth: canvasSize.width))
        
        let shaderArguments = [
            // Position auto injected by Shader init
            // currentcolor auto injected by Shader init
            .float2(cRealSplit.hi, cRealSplit.lo), // Center Real
            .float2(cImagSplit.hi, cImagSplit.lo), // Center Imag
            .float4(dxSplit.hi, dxSplit.lo, dySplit.hi, dySplit.lo), // Step delta sizes
            self.cConstants,
            .float2(Float(canvasSize.width), Float(canvasSize.height)),
            .float(tuningData),
            .float(cyclePalette.shaderValue),
            .floatArray(activePalette)
            // colorsCount auto injected by Shader init
        ]
        return shaderArguments
    }
    
    func newShader(cyclePalette: PaletteCycleStyle,
                   activePalette: [Float],
                   zoom baseZoom: Double,
                   size canvasSize: CGSize,
                   dx: Double, dy: Double,
                   activeCenterReal: Double,
                   activeCenterImag: Double) -> Shader {
        switch self {
            case .Mandelbrot:
                // Mandelbrot rendering is handled by MetalMandelbrotView's compute pipeline.
                // This layerEffect path is retained only to satisfy the shared canvas flow.
                return Shader(function: ShaderLibrary.nullShader, arguments: [])
            case .JuliaA, .JuliaB, .JuliaC, .JuliaD, .JuliaG, .JuliaH, .JuliaL, .JuliaN, .JuliaO, .Phoenix, .PhoenixJ, .PhoenixM, .Dragon, .SanMarcos:
                let shaderArguments = syntheticShaderArguments(
                    cyclePalette: cyclePalette,
                    activePalette: activePalette,
                    size: canvasSize,
                    dx: dx,
                    dy: dy,
                    activeCenterReal: activeCenterReal,
                    activeCenterImag: activeCenterImag
                )
                
                switch self {
                    case .JuliaA, .JuliaB, .JuliaC, .JuliaD, .JuliaG, .JuliaH, .JuliaL, .JuliaN, .JuliaO:
                        let function = usesSinglePrecisionJulia(dx: dx) ? ShaderLibrary.juliaFast : ShaderLibrary.julia
                        return Shader(function: function, arguments: shaderArguments)
                    case .Phoenix, .PhoenixJ, .PhoenixM:
                        return Shader(function: ShaderLibrary.phoenix, arguments: shaderArguments)
                    case .Dragon:
                        return Shader(function: ShaderLibrary.dragon, arguments: shaderArguments)
                    case .SanMarcos:
                        return Shader(function: ShaderLibrary.sanmarcos, arguments: shaderArguments)
                    default:
                        fatalError("Unhandled shader dispatch is handled before synthetic arguments are built.")
                }
        }
    }
    
    var initialCenter: (centerReal: Double, centerImag: Double) {
        switch self {
            case .Mandelbrot:
                return (-0.743643887037158704752191506114774, 0.131825904205311970493132056385139)
            case .JuliaA, .JuliaB, .JuliaC, .JuliaD, .JuliaG, .JuliaH, .JuliaL, .JuliaN, .JuliaO:
                return (0.0, 0.0)
            case .SanMarcos:
                return (0.5, 0.0)
            default:
                return (0.0, 0.0)
        }
    }
    
    var baseZoom: Double {
        switch self {
            case .Mandelbrot:
                return 1.0
            case .JuliaA:
                return 1.2
            case .JuliaB:
                return 0.7
            case .SanMarcos:
                return 2.65
            default:
                return 1.0
        }
    }
    
    var cConstants: Shader.Argument {
        switch self {
            case .JuliaA:
                return .float2(0.238498, 0.519198)
            case .JuliaB:
                return .float2(-0.743036, 0.113467)
            case .JuliaC:
                return .float2(-0.192175, 0.656734)
            case .JuliaD:
                return .float2(0.108294, -0.670487)
            case .JuliaG:
                return .float2(0.138341, 0.649857)
            case .JuliaH:
                return .float2(0.278560, -0.003483)
            case .JuliaL:
                return .float2(0.268545, -0.003483)
            case .JuliaN:
                return .float2(0.318623, -0.044699)
            case .JuliaO:
                return .float2(0.318623, -0.429799)
            case .PhoenixJ, .Phoenix:
                return .float2(0.56667, -0.5)
            case .PhoenixM:
                return .float2(0.356338, -1.209169)
            case .Dragon:
                return .float2(-0.12375, 0.74486)
            case .SanMarcos:
                return .float2(2.998122, 0.004298)
            default:
                return .float2(0.0, 0.0)
        }
    }
    
    private var isJuliaFamily: Bool {
        switch self {
            case .JuliaA, .JuliaB, .JuliaC, .JuliaD, .JuliaG, .JuliaH, .JuliaL, .JuliaN, .JuliaO:
                return true
            default:
                return false
        }
    }
    
    func usesSinglePrecisionJulia(dx: Double) -> Bool {
        isJuliaFamily && dx > 1e-7
    }
    
    func shaderIterationCount(dx: Double, canvasWidth: CGFloat) -> Int {
        switch self {
            case .Dragon, .JuliaA, .JuliaB, .JuliaC, .JuliaD, .JuliaG, .JuliaH, .JuliaL, .JuliaN, .JuliaO, .Phoenix, .PhoenixJ, .PhoenixM:
                let currentScaleWidth = dx * Double(canvasWidth)
                let zoomDepth = log10(1.0 / max(currentScaleWidth, 1e-7))
                let scalingFactor = 250.0
                return Int((Double(iterationCount) + (scalingFactor * zoomDepth)).clamped(to: 100.0...10000.0))
            default:
                return iterationCount
        }
    }
    
    var iterationCount: Int {
        switch self {
            case .Mandelbrot:
                return 250
            case .JuliaA:
                return 128
            case .JuliaB:
                return 96
            case .JuliaC:
                return 64
            case .JuliaD:
                return 256
            case .JuliaG:
                return 32
            case .JuliaH:
                return 256
            case .JuliaL:
                return 64
            case .JuliaN:
                return 256
            case .JuliaO:
                return 48
            case .Phoenix:
                return 256
            case .PhoenixJ:
                return 256
            case .PhoenixM:
                return 256
            case .Dragon:
                return 256
            case .SanMarcos:
                return 128
        }
    }
}
