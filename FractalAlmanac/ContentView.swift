//
//  ContentView.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import SwiftUI
import Metal

struct ContentView: View, PaletteProtocol, ModelProtocol, BookmarkProtocol {
    @Environment(\.displayScale) private var displayScale
    
    @State private var state = ViewModelState()
    @State private var canvasSize: CGSize = .zero
    
    @GestureState private var gestureTranslation: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    
    @State private var dragAnchorX: Double = -0.7
    @State private var dragAnchorY: Double = 0.0
    
    @State private var zoomAnchor: Double = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            let canvasSize = geometry.size
            canvasView(canvas: canvasSize, extents: extents(for: canvasSize))
        }
        .edgesIgnoringSafeArea(.all)
        .overlay(alignment: .bottomTrailing) {
            ToolbarOverlay(
                modelDelegate: self,
                paletteDelegate: self,
                bookmarkDelegate: self,
                state: state,
                size: canvasSize,
                renderBlueprint: { size in
                    canvasView(canvas: size, extents: extents(for: size))
                }
            )
        }
    }
    
    private func extents(for canvasSize: CGSize) -> (
        baseDx: Double,
        baseDy: Double,
        activeCenterReal: Double,
        activeCenterImag: Double
    ) {
        let baseDx = 3.0 / (canvasSize.width * state.baseZoom)
        let baseDy = 3.0 / (canvasSize.height * state.baseZoom)
        
        let activeScale = Double(gestureScale)
        
        let zoomOffsetX = state.isPinching ? (state.zoomAnchorReal - state.centerReal) * (1.0 - 1.0 / activeScale) : 0.0
        let zoomOffsetY = state.isPinching ? (state.zoomAnchorImag - state.centerImag) * (1.0 - 1.0 / activeScale) : 0.0
        
        let minDimension = min(Double(canvasSize.width), Double(canvasSize.height))
        let currentScaleWindow = 3.0 / (state.baseZoom * activeScale)
        
        let dragOffsetX = (Double(gestureTranslation.width) / minDimension) * currentScaleWindow
        let dragOffsetY = (Double(gestureTranslation.height) / minDimension) * currentScaleWindow
        
        let activeCenterReal = state.centerReal - dragOffsetX + zoomOffsetX
        let activeCenterImag = state.centerImag - dragOffsetY - zoomOffsetY
        
        return (baseDx, baseDy, activeCenterReal, activeCenterImag)
    }
    
    @ViewBuilder
    private func canvasView(
        canvas size: CGSize,
        extents: (baseDx: Double, baseDy: Double, activeCenterReal: Double, activeCenterImag: Double)
    ) -> some View {
        
        Color.black // Canvas layer that the shader will redraw over
            .onAppear {
                self.canvasSize = size
            }
            .onChange(of: size) {_, newSize in
                self.canvasSize = newSize
            }
            .layerEffect(
                state.fractalModel.newShader(
                    cyclePalette: state.cyclePalette,
                    activePalette: state.activePalette.paletteShaderColors,
                    zoom: state.baseZoom,
                    size: canvasSize,
                    dx: extents.baseDx,
                    dy: extents.baseDy,
                    activeCenterReal: state.centerReal,
                    activeCenterImag: state.centerImag
                ),
                maxSampleOffset: .zero
            )
            .gesture(
                // Drag to pan the reference center
                DragGesture()
                    .onChanged { value in
                        guard !state.isPinching else { return }
                        
                        let uniformScale = state.uniformScale(for: canvasSize)
                        
                        let deltaX = Double(value.translation.width) * uniformScale
                        let deltaY = Double(value.translation.height) * uniformScale
                        
                        state.centerReal = dragAnchorX - deltaX
                        state.centerImag = state.fractalModel == .Mandelbrot
                        ? dragAnchorY + deltaY
                        : dragAnchorY - deltaY
                    }
                    .onEnded { value in
                        guard !state.isPinching else { return }
                        
                        dragAnchorX = state.centerReal
                        dragAnchorY = state.centerImag
                    }
                    .simultaneously(with: MagnifyGesture()
                        .onChanged { value in
                            state.isPinching = true
                            let currentZoom = zoomAnchor * Double(value.magnification)
                            
                            let scaleBefore = (3.0 / Double(canvasSize.width)) / zoomAnchor
                            let scaleNow = (3.0 / Double(canvasSize.width)) / state.baseZoom
                            
                            let pinchOffsetX = Double(value.startLocation.x - canvasSize.width / 2.0)
                            let pinchOffsetY = Double(value.startLocation.y - canvasSize.height / 2.0)
                            
                            state.centerReal = dragAnchorX + pinchOffsetX * (scaleBefore - scaleNow)
                            state.centerImag = state.fractalModel == .Mandelbrot
                            ? dragAnchorY - pinchOffsetY * (scaleBefore - scaleNow)
                            : dragAnchorY + pinchOffsetY * (scaleBefore - scaleNow)
                            
                            state.baseZoom = currentZoom
                        }
                        .onEnded { _ in
                            zoomAnchor = state.baseZoom
                            // Release pan lock and sync dragging coordinates
                            dragAnchorX = state.centerReal
                            dragAnchorY = state.centerImag
                            state.isPinching = false
                        }
                    )
                    .updating($gestureTranslation) { value, state, _ in
                        state = value.first?.translation ?? .zero
                    }
                    .updating($gestureScale) { value, state, _ in
                        state = value.second?.magnification ?? 1.0
                    }
            )
    }
    
    func triggerGPUCapture() {
        let captureManager = MTLCaptureManager.shared()
        guard !captureManager.isCapturing else { return }
        
        let captureDescriptor = MTLCaptureDescriptor()
        // Capture the default system device used by SwiftUI
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            captureDescriptor.captureObject = defaultDevice
            captureDescriptor.destination = .developerTools
            
            do {
                try captureManager.startCapture(with: captureDescriptor)
                print("GPU Capture Started via Drag Event")
            } catch {
                print("Failed to start programmatic GPU capture: \(error)")
            }
        }
    }
    
    func stopGPUCapture() {
        let captureManager = MTLCaptureManager.shared()
        
        // Only stop if a capture is currently running
        if captureManager.isCapturing {
            captureManager.stopCapture()
            print("GPU Capture Stopped — Tracing in Xcode")
        }
    }
    
    // MARK - Palette Protocol
    func paletteSelectionDidChange(p:any ColorSchemeProtocol) {
        state.activePalette = p
    }
    
    func paletteCycleDidChange(b: PaletteCycleStyle) {
        state.cyclePalette = b
    }
    
    func lastSelectedPalette() -> (any ColorSchemeProtocol)? {
        return nil
    }
    
    // MARK - Model Protocol
    func modelSelectionDidChange(f: FractalModel) {
        UserDefaults.standard.lastSelectedModel = f
        let centers = f.initialCenter
        state.fractalModel = f
        state.centerReal = centers.centerReal
        state.centerImag = centers.centerImag
        state.baseZoom = 1.0
        zoomAnchor = 1.0
        dragAnchorX = state.centerReal
        dragAnchorY = state.centerImag

    }
    
    func lastSelectedModel() -> FractalModel? {
        return UserDefaults.standard.lastSelectedModel
    }
    
    // MARK - Bookmark Protocol
    func shouldLoadBookmark(_ snapshot: any BookmarkObject) {
        let fractalModel = FractalModel(rawValue: snapshot.modelName())!
        state.centerReal = snapshot.center().centerReal
        state.centerImag = snapshot.center().centerImag
        state.baseZoom = snapshot.zoom()
        state.activePalette = snapshot.colorScheme()
        state.fractalModel = fractalModel
        UserDefaults.standard.lastSelectedModel = fractalModel
        UserDefaults.standard.lastSelectedPalette = state.activePalette
    }
}

#Preview {
    ContentView()
}
