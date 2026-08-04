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
    
    var body: some View {
        GeometryReader { geometry in
            let canvasSize = geometry.size
            let extents = extents(for: canvasSize)
            
            canvasView(canvas: canvasSize, extents: extents)
                .onAppear {
                    self.canvasSize = geometry.size
                }
                .onChange(of: geometry.size) {_, newSize in
                    self.canvasSize = newSize
                }
        }
        .ignoresSafeArea()
        // Attach the custom overlay toolbar
        .overlay(alignment: .bottomTrailing) {
            ToolbarOverlay(
                modelDelegate: self,
                paletteDelegate: self,
                bookmarkDelegate: self,
                state: state,
                scale: Double(gestureScale),
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
        
        let dragOffsetX = (Double(gestureTranslation.width) * baseDx) / activeScale
        let dragOffsetY = (Double(gestureTranslation.height) * baseDy) / activeScale
        
        let activeCenterReal = state.centerReal - dragOffsetX + zoomOffsetX
        let activeCenterImag = state.centerImag - dragOffsetY - zoomOffsetY
        
        return (baseDx, baseDy, activeCenterReal, activeCenterImag)
    }
    
    @ViewBuilder
    private func canvasView(
        canvas size: CGSize,
        extents: (baseDx: Double, baseDy: Double, activeCenterReal: Double, activeCenterImag: Double)
    ) -> some View {
        Color.black
            .frame(width: canvasSize.width, height: canvasSize.height)
            .colorEffect(
                state.fractalModel.newShader(
                    cyclePalette: state.cyclePalette,
                    activePalette: state.paletteShaderColors,
                    size: size,
                    dx: extents.baseDx / Double(gestureScale),
                    dy: extents.baseDy / Double(gestureScale),
                    activeCenterReal: extents.activeCenterReal,
                    activeCenterImag: extents.activeCenterImag
                )
            )
            .gesture(
                // Pan Gesture
                DragGesture(minimumDistance: 0)
                    .simultaneously(with: MagnifyGesture())
                    .updating($gestureTranslation) { value, state, _ in
                        state = value.first?.translation ?? .zero
                    }
                    .updating($gestureScale) { value, state, _ in
                        state = value.second?.magnification ?? 1.0
                    }
                    .onChanged { value in
                        #if DEBUG
//                        triggerGPUCapture()
                        #endif
                        // 1. Continuously cache drag translation while active
                        if let drag = value.first {
                            state.lastValidTranslation = drag.translation
                        }
                        
                        if let magnify = value.second {
                            state.lastValidScale = magnify.magnification
                            
                            if !state.isPinching {
                                // B. Map that screen point directly into its permanent location in Fractal Space
                                state.zoomAnchorReal = state.centerReal + (Double(magnify.startAnchor.x) * size.width - size.width / 2.0) * extents.baseDx
                                state.zoomAnchorImag = state.centerImag + (size.height / 2.0 - Double(magnify.startAnchor.y) * size.height) * extents.baseDy
                                state.isPinching = true
                            }
                        }
                    }
                    .onEnded { value in
                        // Calculate final states explicitly matching the exact algebra run above
                        let finalScale = Double(state.lastValidScale)
                        let scaleRatio = (1.0 - 1.0 / finalScale)
                        
                        let finalZoomX = state.isPinching ? (state.zoomAnchorReal - state.centerReal) * scaleRatio : 0.0
                        let finalZoomY = state.isPinching ? (state.zoomAnchorImag - state.centerImag) * scaleRatio : 0.0
                        
                        // Mutate camera state precisely once
                        state.centerReal = state.centerReal - ((Double(state.lastValidTranslation.width) * extents.baseDx) / finalScale) + finalZoomX
                        state.centerImag = state.centerImag - ((Double(state.lastValidTranslation.height) * extents.baseDy) / finalScale) - finalZoomY
                        state.baseZoom = state.baseZoom * finalScale
                        
                        // Tear down structural state variables cleanly for the next gesture lifecycle
                        state.isPinching = false
                        state.zoomAnchorReal = 0.0
                        state.zoomAnchorImag = 0.0
                        state.lastValidTranslation = .zero
                        state.lastValidScale = 1.0
                        #if DEBUG
//                        stopGPUCapture()
                        #endif
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
        state.centerReal = centers.centerReal
        state.centerImag = centers.centerImag
        state.baseZoom = 1.0
        state.fractalModel = f
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
