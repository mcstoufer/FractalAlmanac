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

struct ViewModelState: Equatable {
    var centerReal: Double = FractalModel.initialCenter(model: UserDefaults.standard.lastSelectedModel).centerReal
    var centerImag: Double = FractalModel.initialCenter(model: UserDefaults.standard.lastSelectedModel).centerImag
    var isPinching: Bool = false
    var cyclePalette: Bool = UserDefaults.standard.lastPaletteCycle
    var baseZoom: Double = 1.0
    var fractalModel: FractalModel = UserDefaults.standard.lastSelectedModel
    var activePalette: [Float] = UserDefaults.standard.lastSelectedPalette.paletteShaderColors
    var zoomAnchorReal: Double = 0.0
    var zoomAnchorImag: Double = 0.0
    var lastValidTranslation: CGSize = .zero
    var lastValidScale: CGFloat = 1.0
}

struct ContentView: View, PaletteProtocol, ModelProtocol {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject var renderModel = RenderModel()
    @State private var activeSheet: ActiveSheet?
    @State private var state = ViewModelState()
    
    @GestureState private var gestureTranslation: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            let canvasSize = geometry.size
            
            let baseDx = 3.0 / (canvasSize.width * state.baseZoom)
            let baseDy = 3.0 / (canvasSize.height * state.baseZoom)
            
            let activeScale = Double(gestureScale)

            let zoomOffsetX = state.isPinching ? (state.zoomAnchorReal - state.centerReal) * (1.0 - 1.0 / activeScale) : 0.0
            let zoomOffsetY = state.isPinching ? (state.zoomAnchorImag - state.centerImag) * (1.0 - 1.0 / activeScale) : 0.0
            
            let dragOffsetX = (Double(gestureTranslation.width) * baseDx) / activeScale
            let dragOffsetY = (Double(gestureTranslation.height) * baseDy) / activeScale
            
            let activeCenterReal = state.centerReal - dragOffsetX + zoomOffsetX
            let activeCenterImag = state.centerImag - dragOffsetY - zoomOffsetY
            
            let dx = baseDx / activeScale
            let dy = baseDy / activeScale
            
            // Fetch the metal function from ShaderLibrary
            let shader = state.fractalModel.newShader(
                cyclePalette: state.cyclePalette,
                activePalette: state.activePalette,
                size: canvasSize,
                dx: dx,
                dy: dy,
                activeCenterReal: activeCenterReal,
                activeCenterImag: activeCenterImag
            )
            
            Color.black
                .colorEffect(shader)
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
                                state.lastValidTranslation = drag.translation
                            }
                            
                            if let magnify = value.second {
                                state.lastValidScale = magnify.magnification
                                
                                if !state.isPinching {
                                    let screenX = magnify.startAnchor.x * canvasSize.width
                                    let screenY = magnify.startAnchor.y * canvasSize.height
                                    
                                    // B. Map that screen point directly into its permanent location in Fractal Space
                                    state.zoomAnchorReal = state.centerReal + Double(screenX - canvasSize.width / 2) * baseDx
                                    state.zoomAnchorImag = state.centerImag + Double(canvasSize.height / 2 - screenY) * baseDy
                                    state.isPinching = true
                                }
                            }
                        }
                        .onEnded { value in
                            // Calculate final states explicitly matching the exact algebra run above
                            let finalScale = Double(state.lastValidScale)
                            
                            let finalZoomX = state.isPinching ? (state.zoomAnchorReal - state.centerReal) * (1.0 - 1.0 / finalScale) : 0.0
                            let finalZoomY = state.isPinching ? (state.zoomAnchorImag - state.centerImag) * (1.0 - 1.0 / finalScale) : 0.0
                            
                            let finalDragX = (Double(state.lastValidTranslation.width) * baseDx) / finalScale
                            let finalDragY = (Double(state.lastValidTranslation.height) * baseDy) / finalScale
                            
                            // Mutate camera state precisely once
                            state.centerReal = state.centerReal - finalDragX + finalZoomX
                            state.centerImag = state.centerImag - finalDragY - finalZoomY
                            state.baseZoom = state.baseZoom * finalScale
                            
                            // Tear down structural state variables cleanly for the next gesture lifecycle
                            state.isPinching = false
                            state.zoomAnchorReal = 0.0
                            state.zoomAnchorImag = 0.0
                            state.lastValidTranslation = .zero
                            state.lastValidScale = 1.0
                        }
                )
        }
        .ignoresSafeArea()
        // Attach the custom overlay toolbar
        .overlay(alignment: .bottomTrailing) {
            floatingToolbar
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
                    ModelPicker(modelDelegate: self)
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
        state.activePalette = p.paletteShaderColors
    }
    
    func paletteCycleDidChange(b: Bool) {
        state.cyclePalette = b
    }
    
    func lastSelectedPalette() -> (any ColorSchemeProtocol)? {
        return nil
    }
    
    // MARK - Model Protocol
    func modelSelectionDidChange(f: FractalModel) {
        UserDefaults.standard.lastSelectedModel = f
        let centers = FractalModel.initialCenter(model: f)
        state.centerReal = centers.centerReal
        state.centerImag = centers.centerImag
        state.baseZoom = 1.0
        state.fractalModel = f
    }
    
    func lastSelectedModel() -> FractalModel? {
        return UserDefaults.standard.lastSelectedModel
    }
    
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
