//
//  ContentView.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import SwiftUI
import CoreData

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

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var renderModel = RenderModel()
    @State private var renderedImage: Image? = nil
    @State private var activeSheet: ActiveSheet?
    
    //    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
//        animation: .default)
//    private var items: FetchedResults<Item>

    let backgroundGradient = LinearGradient(
        colors: [Color.white, Color.gray],
        startPoint: .top, endPoint: .bottom
    )
    
    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea() // Forces color to fill the top/bottom edges

            VStack(alignment: .leading) {
                if UserDefaults.standard.hasLaunchedBefore {
                    Text("Prior fractal here")
                } else {
                    Group {
                        if let renderedImage = renderModel.newImage {
                            renderedImage
                                .resizable()
                                .scaledToFit()
                        } else {
                            ProgressView("Rendering",
                                         value: renderModel.renderingProgress,
                                         total: 1.0
                            )
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                            .frame(width: 200, height: 200)
                        }
                    }
                    .task {
                        renderModel.startRendering()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Attach the custom overlay toolbar
            .overlay(alignment: .bottomTrailing) {
                if !renderModel.isRendering {
                    floatingToolbar
                }
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
            .padding(.bottom, 5)
            
            Button(action: {
                activeSheet = .palette
            }) {
                Image(systemName: "swatchpalette.fill")
            }
            .padding(.bottom, 5)

            Button(action: {
                activeSheet = .bookmark
            }) {
                Image(systemName: "bookmark.fill")
            }
            .padding(.bottom, 5)
            
            Button(action: {
                activeSheet = .snapshot
            }) {
                Image(systemName: "photo.badge.arrow.down.fill")
            }
            .padding(.bottom, 5)
            
            Button(action: {
                activeSheet = .settings
            }) {
                Image(systemName: "gearshape.2.fill")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
                case .model:
                    ModelPicker(modelDelegate: renderModel)
                case .palette:
                    PalettePicker(paletteDelegate: renderModel)
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
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
