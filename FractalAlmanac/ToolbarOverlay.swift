//
//  ToolbarOverlay.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/29/26.
//

import SwiftUI

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

enum SnapshotState: String {
    case Save = "photo.badge.arrow.down.fill"
    case Success = "checkmark.circle"
    
    var tintColor:Color {
        switch self {
            case .Save:
                return .white
            case .Success:
                return .green
        }
    }
}

struct ToolbarOverlay<Canvas: View>: View {
    @State private var activeSheet: ActiveSheet?
    @State private var snapshotState: SnapshotState = .Save
    @State private var animationTrigger: Int = 0
    
    private let modelDelegate: ModelProtocol?
    private let paletteDelegate: PaletteProtocol?
    private let bookmarkDelegate: BookmarkProtocol?
    private let state: ViewModelState
    private let size: CGSize
    private let renderBlueprint: (CGSize) -> Canvas
    
    public init(
        activeSheet: ActiveSheet? = nil,
        modelDelegate: ModelProtocol?,
        paletteDelegate: PaletteProtocol?,
        bookmarkDelegate: BookmarkProtocol?,
        state: ViewModelState,
        size: CGSize,
        renderBlueprint: @escaping (CGSize) -> Canvas
    ) {
        self.activeSheet = activeSheet
        self.modelDelegate = modelDelegate
        self.paletteDelegate = paletteDelegate
        self.bookmarkDelegate = bookmarkDelegate
        self.state = state
        self.size = size
        self.renderBlueprint = renderBlueprint
    }
    
    var body: some View {
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
                exportCanvasData()
            }) {
                Image(systemName: snapshotState.rawValue)
                    .contentTransition(.symbolEffect(.replace))
                    .symbolEffect(.wiggle.byLayer, options: .nonRepeating, value: animationTrigger)
            }
            .tint(snapshotState.tintColor)
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
                    ModelPicker(modelDelegate: modelDelegate)
                case .palette:
                    PalettePicker(paletteDelegate: paletteDelegate)
                case .bookmark:
                    BookmarkSheet(
                        bookmarkModel: state.fractalModel,
                        bookmarkPalette: state.activePalette,
                        bookmarkDelegate: bookmarkDelegate,
                        realCenter: state.centerReal,
                        imagCenter: state.centerImag,
                        zoom: state.baseZoom,
                        size: size,
                        renderBlueprint: renderBlueprint
                    )
                case .snapshot:
                    EmptyView()
                case .settings:
                    SettingsSheet(state: state)
                        .presentationDetents([.medium, .height(300)])
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
    
    @MainActor
    private func generateBlueprintImage(for size: CGSize) -> UIImage? {
        return renderBlueprint(size).snapshot()
    }
    
    @MainActor
    private func exportCanvasData() {
        // Reconstruct the layout using the exact snapshot values saved from screen
        guard let imageToSave = generateBlueprintImage(for: size) else {
            print("Failed to rasterize shader view.")
            return
        }

        imageToSave.saveImageWithMetadata(
            caption: "\(state.fractalModel.rawValue): \(state.centerReal), \(state.centerImag)",
            cameraModel: "FractalAlmanac",
            lensInfo: "\(self.state.uniformScale(for: size))") { error in
                if let error {
                    print("Failed to save to photo album: \(error.localizedDescription)")
                } else {
                    withAnimation(.default) {
                        snapshotState = .Success
                        animationTrigger += 1
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.default) {
                            snapshotState = .Save
                        }
                    }
                }
            }
    }
}
