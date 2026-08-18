//
//  MetalMandelbrotView.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 8/11/26.
//

import SwiftUI
import MetalKit

struct MetalMandelbrotView: UIViewRepresentable {
    var engine: MandelbrotEngine
    var state: MandelbrotState
    
    var centerX: Double
    var centerY: Double
    var referenceCenterX: Double
    var referenceCenterY: Double
    var scale: Double
    var maxIterations: Int
    var cyclePalette: Float
    var paletteShaderColors: [Float]
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView(frame: .zero, device: engine.device)
        mtkView.delegate = context.coordinator
        
        mtkView.framebufferOnly = false // Required to allow texture write operations
        mtkView.autoResizeDrawable = true
        
        mtkView.isPaused = true
        
        mtkView.enableSetNeedsDisplay = true // Only redraws when states update
        mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.updateParams(
            centerX: centerX,
            centerY: centerY,
            referenceCenterX: referenceCenterX,
            referenceCenterY: referenceCenterY,
            scale: scale,
            maxIterations: maxIterations,
            cyclePalette: cyclePalette,
            paletteShaderColors: paletteShaderColors
        )
        DispatchQueue.main.async {
            uiView.setNeedsDisplay()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            engine: engine,
            maxIterations: maxIterations
        )
    }
    
    class Coordinator: NSObject, MTKViewDelegate {
        let engine: MandelbrotEngine

        private var centerX: Double = 0.0
        private var centerY: Double = 0.0
        private var referenceCenterX: Double = 0.0
        private var referenceCenterY: Double = 0.0
        private var scale: Double = 1.0
        private var maxIterations: Int
        private var cyclePalette: Float = 0.0
        private var paletteShaderColors: [Float] = []
        
        init(engine: MandelbrotEngine, maxIterations: Int = 200) {
            self.engine = engine
            self.maxIterations = maxIterations
        }
        
        func updateParams(
            centerX: Double,
            centerY: Double,
            referenceCenterX: Double,
            referenceCenterY: Double,
            scale: Double,
            maxIterations: Int,
            cyclePalette: Float,
            paletteShaderColors: [Float]
        ) {
            self.centerX = centerX
            self.centerY = centerY
            self.referenceCenterX = referenceCenterX
            self.referenceCenterY = referenceCenterY
            self.scale = scale
            self.maxIterations = maxIterations
            self.cyclePalette = cyclePalette
            self.paletteShaderColors = paletteShaderColors
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            view.setNeedsDisplay()
        }
        
        func draw(in view: MTKView) {
            autoreleasepool {
                guard let drawable = view.currentDrawable else { return }
                
                engine.encode(
                    to: drawable.texture,
                    centerX: self.centerX,
                    centerY: self.centerY,
                    referenceCenterX: self.referenceCenterX,
                    referenceCenterY: self.referenceCenterY,
                    scale: self.scale,
                    maxIterations: self.maxIterations,
                    cyclePalette: self.cyclePalette,
                    paletteShaderColors: self.paletteShaderColors
                )
                drawable.present()
            }
        }
    }
}
