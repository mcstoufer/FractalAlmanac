//
//  ContentView.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import SwiftUI
import Metal
import Foundation

struct ContentView: View, PaletteProtocol, ModelProtocol, BookmarkProtocol {
    @State private var state = ViewModelState()
    @State private var engine = MandelbrotEngine()
    @State private var mState = MandelbrotState()
    @State private var canvasSize: CGSize = .zero
    @State private var iterationRestoreTimer: Timer?

    @GestureState private var gestureTranslation: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            resolveCanvasContext(for: geometry.size)
        }
        .edgesIgnoringSafeArea(.all)
        .onDisappear {
            iterationRestoreTimer?.invalidate()
        }
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
    
    @ViewBuilder
    private func resolveCanvasContext(for canvasSize: CGSize) -> some View {
        switch state.fractalModel {
            case .Mandelbrot:
                let currentCenterX = state.centerReal
                let currentCenterY = state.centerImag
                let currentIterations = mState.maxIterations
                let uniformScale = mState.uniformScale(for: canvasSize)
                
                ZStack {
                    MetalMandelbrotView(
                        engine: engine,
                        state: mState,
                        centerX: currentCenterX,
                        centerY: currentCenterY,
                        referenceCenterX: state.referenceCenterReal,
                        referenceCenterY: state.referenceCenterImag,
                        scale: uniformScale,
                        maxIterations: currentIterations,
                        cyclePalette: state.cyclePalette.shaderValue,
                        paletteShaderColors: state.paletteShaderColors
                    )
                    mandelbrotView(canvas: canvasSize, scale: uniformScale)
                }
                .overlay(alignment: .bottom) {
                    VStack(spacing: 4) {
                        Text(String(format: "X: %.6f, Y: %.6f", state.centerReal, state.centerImag))
                        Text(String(format: "Zoom: %.2e (Iter: %d)", mState.scale, mState.maxIterations))
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white)
                    .padding()
                    .background(.black.opacity(0.75))
                    .cornerRadius(8)
                    .padding()
                }
            default:
                canvasView(canvas: canvasSize, extents: extents(for: canvasSize))
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
    private func mandelbrotView(canvas size: CGSize, scale: Double) -> some View {
        Color.clear
        .contentShape(Rectangle()) // FIX: Forces the hit-testing matrix to trap actions
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !state.isPinching else { return }
                    scheduleFullQualityRenderAfterIdle()
                    state.centerReal = state.dragAnchorReal - (Double(value.translation.width) * scale)
                    state.centerImag = state.dragAnchorImag + (Double(value.translation.height) * scale)
                }
                .onEnded { value in
                    guard !state.isPinching else { return }
                    state.dragAnchorReal = state.centerReal
                    state.dragAnchorImag = state.centerImag
                    state.resetReferenceCenter()
                    scheduleFullQualityRenderAfterIdle()
                }
                .simultaneously(with: MagnifyGesture()
                    .onChanged { value in
                        self.state.isPinching = true
                        scheduleFullQualityRenderAfterIdle()
                        let currentZoom = state.zoomAnchor * Double(value.magnification)
                        let scaleBefore = (3.0 / Double(size.width)) / state.zoomAnchor
                        let scaleNow = (3.0 / Double(size.width)) / currentZoom
                        
                        let pinchOffsetX = Double(value.startLocation.x - size.width / 2.0)
                        let pinchOffsetY = Double(value.startLocation.y - size.height / 2.0)
                        
                        state.centerReal = state.dragAnchorReal + pinchOffsetX * (scaleBefore - scaleNow)
                        state.centerImag = state.dragAnchorImag - pinchOffsetY * (scaleBefore - scaleNow)
                        
                        mState.scale = currentZoom
                    }
                    .onEnded { _ in
                        state.zoomAnchor = mState.scale
                        state.dragAnchorReal = state.centerReal
                        state.dragAnchorImag = state.centerImag
                        state.resetReferenceCenter()
                        scheduleFullQualityRenderAfterIdle()
                        
                        state.isPinching = false
                    }
            )
        )
    }
    
    private func scheduleFullQualityRenderAfterIdle() {
        mState.usesInteractionIterationLimit = true
        iterationRestoreTimer?.invalidate()
        iterationRestoreTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            mState.usesInteractionIterationLimit = false
        }
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
                        
                        state.centerReal = state.dragAnchorReal - deltaX
                        state.centerImag = state.fractalModel == .Mandelbrot
                        ? state.dragAnchorImag + deltaY
                        : state.dragAnchorImag - deltaY
                    }
                    .onEnded { value in
                        guard !state.isPinching else { return }
                        
                        state.dragAnchorReal = state.centerReal
                        state.dragAnchorImag = state.centerImag
                    }
                    .simultaneously(with: MagnifyGesture()
                        .onChanged { value in
                            state.isPinching = true
                            let currentZoom = state.zoomAnchor * Double(value.magnification)
                            
                            let scaleBefore = (3.0 / Double(canvasSize.width)) / state.zoomAnchor
                            let scaleNow = (3.0 / Double(canvasSize.width)) / state.baseZoom
                            
                            let pinchOffsetX = Double(value.startLocation.x - canvasSize.width / 2.0)
                            let pinchOffsetY = Double(value.startLocation.y - canvasSize.height / 2.0)
                            
                            state.centerReal = state.dragAnchorReal + pinchOffsetX * (scaleBefore - scaleNow)
                            state.centerImag = state.fractalModel == .Mandelbrot
                            ? state.dragAnchorImag - pinchOffsetY * (scaleBefore - scaleNow)
                            : state.dragAnchorImag + pinchOffsetY * (scaleBefore - scaleNow)
                            
                            state.baseZoom = currentZoom
                        }
                        .onEnded { _ in
                            state.zoomAnchor = state.baseZoom
                            // Release pan lock and sync dragging coordinates
                            state.dragAnchorReal = state.centerReal
                            state.dragAnchorImag = state.centerImag
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
    
//    func triggerGPUCapture() {
//        let captureManager = MTLCaptureManager.shared()
//        guard !captureManager.isCapturing else { return }
//        
//        let captureDescriptor = MTLCaptureDescriptor()
//        // Capture the default system device used by SwiftUI
//        if let defaultDevice = MTLCreateSystemDefaultDevice() {
//            captureDescriptor.captureObject = defaultDevice
//            captureDescriptor.destination = .developerTools
//            
//            do {
//                try captureManager.startCapture(with: captureDescriptor)
//                print("GPU Capture Started via Drag Event")
//            } catch {
//                print("Failed to start programmatic GPU capture: \(error)")
//            }
//        }
//    }
//    
//    func stopGPUCapture() {
//        let captureManager = MTLCaptureManager.shared()
//        
//        // Only stop if a capture is currently running
//        if captureManager.isCapturing {
//            captureManager.stopCapture()
//            print("GPU Capture Stopped — Tracing in Xcode")
//        }
//    }
    
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
        state.zoomAnchor = 1.0
        state.dragAnchorReal = state.centerReal
        state.dragAnchorImag = state.centerImag

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
        state.zoomAnchor = snapshot.zoom()
        state.activePalette = snapshot.colorScheme()
        state.fractalModel = fractalModel
        UserDefaults.standard.lastSelectedModel = fractalModel
        UserDefaults.standard.lastSelectedPalette = state.activePalette
    }
}

#Preview {
    ContentView()
}
