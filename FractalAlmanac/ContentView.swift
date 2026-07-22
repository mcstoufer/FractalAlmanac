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
    @State private var centerReal: Double = -0.743643887037158704752191506114774
    @State private var centerImag: Double = 0.131825904205311970493132056385139
    @State private var zoomRadius: Double = 1.2
    
    // 2. Gesture tracking states to handle active drag/zoom interaction offsets
    @State private var dragOffset: CGSize = .zero
    @State private var activeMagnification: CGFloat = 1.0
    
    @State private var zoomAnchorReal: Double? = nil
    @State private var zoomAnchorImag: Double? = nil
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geometry in
                let size = geometry.size
                
                // 1. Calculate active real-time viewport details in 64-bit Double depth
                let aspect = size.width > 0 ? Double(size.width / size.height) : 1.0
                let effectiveZoom = zoomRadius / Double(activeMagnification)
                
                let xSpan = effectiveZoom * max(aspect, 1.0) * 2.0
                let ySpan = effectiveZoom * max(1.0 / aspect, 1.0) * 2.0
                
                // Live center adjustments reflecting dragging actions
                let liveCenterReal = centerReal - (Double(dragOffset.width) / Double(size.width)) * xSpan
                let liveCenterImag = centerImag - (Double(dragOffset.height) / Double(size.height)) * ySpan
                
                // 2. Compute exact step adjustments per physical device pixel
                let dx = xSpan / Double(size.width)
                let dy = ySpan / Double(size.height)
                
                // Split parameters carefully to prevent bits dropping during transmission
                let cRealSplit = liveCenterReal.splitDouble
                let cImagSplit = liveCenterImag.splitDouble
                let dxSplit = dx.splitDouble
                let dySplit = dy.splitDouble
                
                Canvas { context, canvasSize in
                    guard size.width > 0, size.height > 0 else { return }
                    let depthFactor = max(0, -log10(zoomRadius))
                    let dynamicIterations = Float(150 + Int(depthFactor * 75.0))
                    
                    // Fetch the metal function from ShaderLibrary
                    let mandelbrotShader = Shader(
                        function: ShaderLibrary.mandelbrot,
                        arguments:[
                            .float4(cRealSplit.hi, cRealSplit.lo, 0.0, 0.0), // Center Real
                            .float4(cImagSplit.hi, cImagSplit.lo, 0.0, 0.0), // Center Imag
                            .float4(dxSplit.hi, dxSplit.lo, dySplit.hi, dySplit.lo), // Step delta sizes
                            .float2(Float(canvasSize.width), Float(canvasSize.height)),
                            .float2(dynamicIterations, 0.0),
                            .floatArray(activePalette)
                        ]
                    )
                    
                    // Render the shader to fill the full bounds
                    context.fill(Path(CGRect(origin: .zero, size: canvasSize)), with: .shader(mandelbrotShader))
                }
                .ignoresSafeArea()
                .gesture(
                    SimultaneousGesture(
                        // Pan Gesture
                        DragGesture(minimumDistance: 0)
                            .onChanged { dragOffset = $0.translation }
                            .onEnded { value in
                                // Commit the final translation change directly to state coordinates
                                centerReal -= (Double(value.translation.width) / Double(size.width)) * xSpan
                                centerImag -= (Double(value.translation.height) / Double(size.height)) * ySpan
                                dragOffset = .zero // Reset translation buffer
                            },
                        // Pinch to Zoom Gesture
                        MagnifyGesture()
                            .onChanged { value in
                                if zoomAnchorReal == nil {
                                    let pctX = Double(value.startLocation.x / size.width)
                                    let pctY = Double(value.startLocation.y / size.height)
                                    zoomAnchorReal = liveCenterReal - (xSpan * 0.5) + (pctX * xSpan)
                                    zoomAnchorImag = liveCenterImag + (ySpan * 0.5) - (pctY * ySpan)
                                }
                                activeMagnification = value.magnification
                            }
                            .onEnded { value in
                                if let anchorR = zoomAnchorReal, let anchorI = zoomAnchorImag {
                                    let newZoomRadius = zoomRadius / Double(value.magnification)
                                    let newXSpan = newZoomRadius * max(aspect, 1.0) * 2.0
                                    let newYSpan = newZoomRadius * max(1.0 / aspect, 1.0) * 2.0
                                    
                                    let pctX = Double(value.startLocation.x / size.width)
                                    let pctY = Double(value.startLocation.y / size.height)
                                    
                                    centerReal = anchorR + (0.5 - pctX) * newXSpan
                                    centerImag = anchorI - (0.5 - pctY) * newYSpan
                                    zoomRadius = newZoomRadius
                                }
                                activeMagnification = 1.0
                                zoomAnchorReal = nil
                                zoomAnchorImag = nil
                                dragOffset = .zero
                            }
                    )
                )
            }
            // Attach the custom overlay toolbar
            .overlay(alignment: .bottomTrailing) {
                floatingToolbar
            }
        }
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
    
    func lastSelectedPalette() -> (any ColorSchemeProtocol)? {
        return nil
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
