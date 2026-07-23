//
//  ContentView.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import SwiftUI
internal import CoreData
import Metal

enum ActiveSheet: Identifiable {
    case model
    case palette
    case bookmark
    case settings
    case snapshot
    
    // Conformance to Identifiable is required for .sheet(item:)
    var id: String {
        switch self {
            case .model: return "model"
            case .palette: return "palette"
            case .bookmark: return "bookmark"
            case .settings: return "settings"
            case .snapshot: return "snapshot"
        }
    }
}

struct ContentView: View, PaletteProtocol {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject var renderModel = RenderModel()
    @State private var activeSheet: ActiveSheet?
    @State private var activePalette: [Float] = UserDefaults.standard.lastSelectedPalette.paletteShaderColors
    
    @State private var centerReal: Double = -0.7
    @State private var centerImag: Double = 0.0
    @State private var baseZoom: Double = 1.0
    
    @GestureState private var gestureTranslation: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0

    @State private var zoomAnchorReal: Double = 0.0
    @State private var zoomAnchorImag: Double = 0.0
    @State private var isPinching: Bool = false
    @State private var cyclePalette: Bool = false
    
    // PERSISTENT CACHES: Prevents the .onEnded reset/snapback defect
    @State private var lastValidTranslation: CGSize = .zero
    @State private var lastValidScale: CGFloat = 1.0
    
    var body: some View {
//        VStack(alignment: .leading) {
            GeometryReader { geometry in
                let canvasSize = geometry.size
                
                let baseDx = 3.0 / (canvasSize.width * baseZoom)
                let baseDy = 3.0 / (canvasSize.height * baseZoom)
                
                let activeScale = Double(gestureScale)
 
                let zoomOffsetX = isPinching ? (zoomAnchorReal - centerReal) * (1.0 - 1.0 / activeScale) : 0.0
                let zoomOffsetY = isPinching ? (zoomAnchorImag - centerImag) * (1.0 - 1.0 / activeScale) : 0.0
                
                let dragOffsetX = (Double(gestureTranslation.width) * baseDx) / activeScale
                let dragOffsetY = (Double(gestureTranslation.height) * baseDy) / activeScale
                
                let activeCenterReal = centerReal - dragOffsetX + zoomOffsetX
                let activeCenterImag = centerImag - dragOffsetY - zoomOffsetY
                
                let dx = baseDx / activeScale
                let dy = baseDy / activeScale
                
                let cRealSplit = activeCenterReal.splitDouble
                let cImagSplit = activeCenterImag.splitDouble
                let dxSplit = dx.splitDouble
                let dySplit = dy.splitDouble
//                Canvas { context, canvasSize in
//                    guard size.width > 0, size.height > 0 else { return }
//                let depthFactor = max(0, -log10(dx))
                let dynamicIterations = 150.0 // Float(150 + Int(depthFactor * 75.0))
                
                // Fetch the metal function from ShaderLibrary
                let mandelbrotShader = Shader(
                    function: ShaderLibrary.mandelbrot,
                    arguments:[
                        .float4(cRealSplit.hi, cRealSplit.lo, 0.0, 0.0), // Center Real
                        .float4(cImagSplit.hi, cImagSplit.lo, 0.0, 0.0), // Center Imag
                        .float4(dxSplit.hi, dxSplit.lo, dySplit.hi, dySplit.lo), // Step delta sizes
                        .float2(Float(canvasSize.width), Float(canvasSize.height)),
                        .float2(dynamicIterations, 0.0),
                        .float(cyclePalette ? 1.0 : 0.0),
                        .floatArray(activePalette)
                    ]
                )
                
                Color.black
                    .colorEffect(mandelbrotShader)
//                    .padding(0)
//                    .frame(width: geometry.size.width, height: geometry.size.height)
                    // Render the shader to fill the full bounds
//                    context.fill(Path(CGRect(origin: .zero, size: canvasSize)), with: .shader(mandelbrotShader))
//                }
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
                                // 1. Continuously cache drag translation while active
                                if let drag = value.first {
                                    lastValidTranslation = drag.translation
                                }
                                
                                if let magnify = value.second {
                                    lastValidScale = magnify.magnification
                                    
                                    if !isPinching {
                                        let screenX = magnify.startAnchor.x * canvasSize.width
                                        let screenY = magnify.startAnchor.y * canvasSize.height
                                        
                                        // B. Map that screen point directly into its permanent location in Fractal Space
                                        zoomAnchorReal = centerReal + Double(screenX - canvasSize.width / 2) * baseDx
                                        zoomAnchorImag = centerImag + Double(canvasSize.height / 2 - screenY) * baseDy
                                        isPinching = true
                                    }
                                }
                            }
                            .onEnded { value in
                                // Calculate final states explicitly matching the exact algebra run above
                                let finalScale = Double(lastValidScale)
                                
                                let finalZoomX = isPinching ? (zoomAnchorReal - centerReal) * (1.0 - 1.0 / finalScale) : 0.0
                                let finalZoomY = isPinching ? (zoomAnchorImag - centerImag) * (1.0 - 1.0 / finalScale) : 0.0
                                
                                let finalDragX = (Double(lastValidTranslation.width) * baseDx) / finalScale
                                let finalDragY = (Double(lastValidTranslation.height) * baseDy) / finalScale
                                
                                // Mutate camera state precisely once
                                centerReal = centerReal - finalDragX + finalZoomX
                                centerImag = centerImag - finalDragY - finalZoomY
                                baseZoom = baseZoom * finalScale
                                
                                // Tear down structural state variables cleanly for the next gesture lifecycle
                                isPinching = false
                                zoomAnchorReal = 0.0
                                zoomAnchorImag = 0.0
                                lastValidTranslation = .zero
                                lastValidScale = 1.0
                            }
                    )
            }
            .ignoresSafeArea()
            // Attach the custom overlay toolbar
            .overlay(alignment: .bottomTrailing) {
                floatingToolbar
            }
//        }
    }
    
    private var floatingToolbar: some View {
        VStack(alignment: .leading) {
            Button(action: {
                activeSheet = .model
            }) {
                Image(systemName: "map.fill")
            }
            .tint(.white)
            .padding(.bottom, 5)
            
            Button(action: {
                activeSheet = .palette
            }) {
                Image(systemName: "swatchpalette.fill")
            }
            .tint(.white)
            .padding(.bottom, 5)
            
            Button(action: {
                activeSheet = .bookmark
            }) {
                Image(systemName: "bookmark.fill")
            }
            .tint(.white)
            .padding(.bottom, 5)
            
            Button(action: {
                activeSheet = .snapshot
            }) {
                Image(systemName: "photo.badge.arrow.down.fill")
            }
            .tint(.white)
            .padding(.bottom, 5)
            
            Button(action: {
                activeSheet = .settings
            }) {
                Image(systemName: "gearshape.2.fill")
            }
            .tint(.white)
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
                case .model:
                    ModelPicker(modelDelegate: renderModel)
                case .palette:
                    PalettePicker(paletteDelegate: self)
                case .bookmark:
                    BookmarkSheet()
                case .settings:
                    SettingsSheet()
                case .snapshot:
                    SnapshotSheet()
            }
        }
        .font(.title2)
        .padding(.horizontal, 25)
        .padding(.vertical, 15)
        .background(.ultraThinMaterial) // Gives a blur effect overlaying content
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .padding([.bottom, .trailing], 10) // Push it slightly away from the screen edge
    }
    
    // MARK - Palette Protocol
    func paletteSelectionDidChange(p:any ColorSchemeProtocol) {
        activePalette = p.paletteShaderColors
    }
    
    func paletteCycleDidChange(b: Bool) {
        cyclePalette = b
    }
    
    func lastSelectedPalette() -> (any ColorSchemeProtocol)? {
        return nil
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
