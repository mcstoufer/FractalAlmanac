//
//  ContentView.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var renderModel = RenderModel()
    @State private var renderedImage: Image? = nil
    
    //    @FetchRequest(
//        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
//        animation: .default)
//    private var items: FetchedResults<Item>

    var body: some View {
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
                    await renderModel.startRendering()
                }
            }
        }
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
