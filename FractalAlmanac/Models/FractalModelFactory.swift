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
        
        let shaderArguments = [
            .float4(cRealSplit.hi, cRealSplit.lo, 0.0, 0.0), // Center Real
            .float4(cImagSplit.hi, cImagSplit.lo, 0.0, 0.0), // Center Imag
            .float4(dxSplit.hi, dxSplit.lo, dySplit.hi, dySplit.lo), // Step delta sizes
            self.cConstants,
            .float2(Float(canvasSize.width), Float(canvasSize.height)),
            .float(Float(self.iterationCount)),
            .float(cyclePalette.shaderValue),
            .floatArray(activePalette)
        ]
        return shaderArguments
    }

    func pertubationShaderArguments(cyclePalette: PaletteCycleStyle,
                                    activePalette: [Float],
                                    size canvasSize: CGSize,
                                    scale: Double,
                                    activeCenterReal: Double,
                                    activeCenterImag: Double,
                                    stableCenterReal: Double,
                                    stableCenterImag: Double
    ) -> [Shader.Argument] {
        var orbit = [SIMD2<Float>]()
        orbit.reserveCapacity(self.iterationCount)
        
        var z = SIMD2<Float>(0, 0)
        let c = SIMD2<Float>(Float(stableCenterReal), Float(stableCenterImag))
        
        for _ in 0..<self.iterationCount {
            // Standard Mandelbrot iteration: z = z^2 + c
            let nextX = (z.x * z.x) - (z.y * z.y) + c.x
            let nextY = (2.0 * z.x * z.y) + c.y
            z = SIMD2<Float>(nextX, nextY)
            orbit.append(z)
        }
        
        // Convert the contiguous array into raw byte Data for SwiftUI Shader
        let refBuffer = orbit.withUnsafeBytes { Data($0) }

        let shaderArguments: [Shader.Argument] = [
            // Position auto injected by Shader init
            // curentColor auto injected by Shader init
            .float2(Float(canvasSize.width), Float(canvasSize.height)),  // Size
            .float(Float(scale)),                                        // Current Scale
            .float2(Float(activeCenterReal), Float(activeCenterImag)),   // Current center
            .float2(Float(stableCenterReal), Float(stableCenterImag)),   // Stable Center
            .float(cyclePalette.shaderValue),                            // Palette Cycle mode
            .float(Float(self.iterationCount)),                          // Max Iterations
            .floatArray(activePalette),                                  // Active color palette. colorsCount auto injected by Shader init for prior pointer array
            .data(refBuffer)                                             // Pertubation Reference Orbit Buffer
        ]
        return shaderArguments
    }
    
    func newShader(cyclePalette: PaletteCycleStyle,
                   activePalette: [Float],
                   zoom baseZoom: Double,
                   size canvasSize: CGSize,
                   dx: Double, dy: Double,
                   activeCenterReal: Double,
                   activeCenterImag: Double,
                   stableCenterReal: Double,
                   stableCenterImag: Double) -> Shader {
        
        var shaderArguments: [Shader.Argument] = []
        if self == .Mandelbrot {
            shaderArguments = pertubationShaderArguments(
                cyclePalette: cyclePalette,
                activePalette: activePalette,
                size: canvasSize,
                scale: baseZoom,
                activeCenterReal: activeCenterReal,
                activeCenterImag: activeCenterImag,
                stableCenterReal: stableCenterReal,
                stableCenterImag: stableCenterImag
            )
        } else {
            shaderArguments = syntheticShaderArguments(
                cyclePalette: cyclePalette,
                activePalette: activePalette,
                size: canvasSize,
                dx: dx,
                dy: dy,
                activeCenterReal: activeCenterReal,
                activeCenterImag: activeCenterImag
            )
        }
        switch self {
            case .Mandelbrot:
                return Shader(function: ShaderLibrary.mandelbrot_pertubation, arguments: shaderArguments)
            case .JuliaA, .JuliaB, .JuliaC, .JuliaD, .JuliaG, .JuliaH, .JuliaL, .JuliaN, .JuliaO:
                return Shader(function: ShaderLibrary.julia, arguments: shaderArguments)
            case .Phoenix, .PhoenixJ, .PhoenixM:
                return Shader(function: ShaderLibrary.phoenix, arguments: shaderArguments)
            case .Dragon:
                return Shader(function: ShaderLibrary.dragon, arguments: shaderArguments)
            case .SanMarcos:
                return Shader(function: ShaderLibrary.sanmarcos, arguments: shaderArguments)
        }
    }
    
    var initialCenter: (centerReal: Double, centerImag: Double) {
        switch self {
            case .Mandelbrot:
                return (-0.5, 0.0)
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
            case .PhoenixJ, .Phoenix:
                return .float4(0.56667, 0.0, -0.5, 0.0)
            case .PhoenixM:
                return .float4(0.356338, 0.0, -1.209169, 0.0)
            case .Dragon:
                return .float4(-0.12375, 0.0, 0.74486, 0.0)
            case .SanMarcos:
                return .float4(2.998122, 0.0, 0.004298, 0)
            default:
                return .float4(0.0, 0.0, 0.0, 0.0)
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
