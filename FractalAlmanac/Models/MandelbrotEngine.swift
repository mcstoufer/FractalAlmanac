//
//  MandelbrotEngine.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 8/11/26.
//

import Algorithms
import Foundation
import Metal
import MetalKit
import simd

@Observable
class MandelbrotState {
    var scale: Double = 1.75
    var usesInteractionIterationLimit = false
    
    func uniformScale(for canvasSize: CGSize) -> Double {
        (3.0 / Double(canvasSize.width)) / self.scale
    }
    
    var maxIterations: Int {
        let calculatedIterations: Int
        guard scale > 1200 else { return 150 }
        
        let zoomDepth = log10(max(1.0, scale))
        calculatedIterations = min(1200, 200 + Int(zoomDepth * 160.0))
        
        return usesInteractionIterationLimit ? min(299, calculatedIterations) : calculatedIterations
    }
}

@Observable
class MandelbrotEngine {
    
    let device: MTLDevice
    private var commandQueue: MTLCommandQueue!
    private var computePipelineState: MTLComputePipelineState!
    
    init() {
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
        
        let library = device.makeDefaultLibrary()!
        let kernelFunction = library.makeFunction(name: "mandelbrotComputePerturbation")!
        self.computePipelineState = try! device.makeComputePipelineState(function: kernelFunction)
    }
    
    // CPU High-Precision absolute orbit calculation
    func generateReferenceOrbit(centerX: Double, centerY: Double, maxIterations: Int) -> (orbit: [SIMD4<Float>], escapeIteration: Int?) {
        var orbit = [SIMD4<Float>]()
        orbit.reserveCapacity(maxIterations)
        var escapeIteration: Int?
        
        var zx = 0.0
        var zy = 0.0
        
        for iteration in 0..<maxIterations {
            if zx.isNaN || zy.isNaN || zx.isInfinite || zy.isInfinite {
                zx = 0.0
                zy = 0.0
            }
            
            let zxSplit = zx.splitSIMD2
            let zySplit = zy.splitSIMD2
            orbit.append(SIMD4<Float>(zxSplit.x, zxSplit.y, zySplit.x, zySplit.y))
            
            let r2 = zx * zx
            let i2 = zy * zy

            if (r2 + i2) > 4.0 {
                escapeIteration = iteration
                break
            }
            
            let xtemp = r2 - i2 + centerX
            zy = 2.0 * zx * zy + centerY
            zx = xtemp
        }
        
        // Pad the remainder if orbit escapes early
        while orbit.count < maxIterations {
            let zxSplit = zx.splitSIMD2
            let zySplit = zy.splitSIMD2
            orbit.append(SIMD4<Float>(zxSplit.x, zxSplit.y, zySplit.x, zySplit.y))
        }
        
        return (orbit, escapeIteration)
    }
    
    private func generateBestReferenceOrbit(
        centerX: Double,
        centerY: Double,
        scale: Double,
        textureWidth: Int,
        textureHeight: Int,
        maxIterations: Int
    ) -> (orbit: [SIMD4<Float>], centerX: Double, centerY: Double) {
        let sampleFractions = [0.0, -0.25, 0.25, -0.5, 0.5]
        var bestOrbit: [SIMD4<Float>] = []
        var bestCenterX = centerX
        var bestCenterY = centerY
        var bestEscapeIteration = -1
        
        for fraction in sampleFractions.permutations(ofCount: 2) {
            let candidateCenterX = centerX + (Double(textureWidth) * fraction[0] * scale)
            let candidateCenterY = centerY - (Double(textureHeight) * fraction[1] * scale)
            let result = generateReferenceOrbit(
                centerX: candidateCenterX,
                centerY: candidateCenterY,
                maxIterations: maxIterations
            )
            
            if result.escapeIteration == nil {
                return (result.orbit, candidateCenterX, candidateCenterY)
            }
            
            let escapeIteration = result.escapeIteration ?? 0
            if escapeIteration > bestEscapeIteration {
                bestOrbit = result.orbit
                bestCenterX = candidateCenterX
                bestCenterY = candidateCenterY
                bestEscapeIteration = escapeIteration
            }
        }
        
        return (bestOrbit, bestCenterX, bestCenterY)
    }
    
    func encode(
        to drawableTexture: MTLTexture,
        centerX: Double,
        centerY: Double,
        referenceCenterX: Double,
        referenceCenterY: Double,
        scale: Double,
        maxIterations: Int,
        cyclePalette: Float,
        paletteShaderColors: [Float]
    ) {
        guard drawableTexture.width > 0 && drawableTexture.height > 0,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return }
        
        // 1. Calculate and bind Reference Orbit array
        let referenceOrbit = generateBestReferenceOrbit(
            centerX: centerX,
            centerY: centerY,
            scale: scale,
            textureWidth: drawableTexture.width,
            textureHeight: drawableTexture.height,
            maxIterations: maxIterations
        )
        let orbitBufferSize = referenceOrbit.orbit.count * MemoryLayout<SIMD4<Float>>.stride
        let orbitBuffer = device.makeBuffer(bytes: referenceOrbit.orbit, length: orbitBufferSize, options: .storageModeShared)
        
        // 2. Bind parameters
        var scaleVector = SIMD2<Float>(Float(scale), Float(scale))
        var iterationsFloat = Float(maxIterations)
        var centerXSplit = centerX.splitSIMD2
        var centerYSplit = centerY.splitSIMD2
        var referenceCenterXSplit = referenceOrbit.centerX.splitSIMD2
        var referenceCenterYSplit = referenceOrbit.centerY.splitSIMD2
        var cyclePalette = cyclePalette
        var colorsCount = Int32(paletteShaderColors.count)
        
        guard !paletteShaderColors.isEmpty,
              let paletteBuffer = device.makeBuffer(
                bytes: paletteShaderColors,
                length: paletteShaderColors.count * MemoryLayout<Float>.stride,
                options: .storageModeShared
              ) else { return }
        
        encoder.setComputePipelineState(computePipelineState)
        encoder.setTexture(drawableTexture, index: 0)
        encoder.setBuffer(orbitBuffer, offset: 0, index: 0)
        encoder.setBytes(&scaleVector, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        encoder.setBytes(&iterationsFloat, length: MemoryLayout<Float>.size, index: 2)
        encoder.setBytes(&cyclePalette, length: MemoryLayout<Float>.size, index: 3)
        encoder.setBytes(&centerXSplit, length: MemoryLayout<SIMD2<Float>>.size, index: 4)
        encoder.setBytes(&centerYSplit, length: MemoryLayout<SIMD2<Float>>.size, index: 5)
        encoder.setBytes(&referenceCenterXSplit, length: MemoryLayout<SIMD2<Float>>.size, index: 6)
        encoder.setBytes(&referenceCenterYSplit, length: MemoryLayout<SIMD2<Float>>.size, index: 7)
        encoder.setBuffer(paletteBuffer, offset: 0, index: 8)
        encoder.setBytes(&colorsCount, length: MemoryLayout<Int32>.size, index: 9)

        
        // 3. Thread Group Calculations Configuration
        let threadGroupWidth = computePipelineState.threadExecutionWidth
        let threadGroupHeight = computePipelineState.maxTotalThreadsPerThreadgroup / threadGroupWidth
        let threadsPerThreadgroup = MTLSize(width: threadGroupWidth, height: threadGroupHeight, depth: 1)
        
        let groupsPerGridX = (drawableTexture.width + threadGroupWidth - 1) / threadGroupWidth
        let groupsPerGridY = (drawableTexture.height + threadGroupHeight - 1) / threadGroupHeight
        let threadgroupsPerGrid = MTLSize(width: groupsPerGridX, height: groupsPerGridY, depth: 1)
        
        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        encoder.endEncoding()
        
        commandBuffer.commit()
    }
}
