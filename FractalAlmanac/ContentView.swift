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

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject var renderModel = RenderModel()
    @State private var activeSheet: ActiveSheet?
    
    @State private var centerReal: Double = -0.5
    @State private var centerImag: Double = 0.0
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
                    let viewport = calculateViewport(for: size)
                    
                    // Split boundaries into high/low components
                    let minRealSplit = splitDouble(viewport.minReal)
                    let maxRealSplit = splitDouble(viewport.maxReal)
                    let minImagSplit = splitDouble(viewport.minImag)
                    let maxImagSplit = splitDouble(viewport.maxImag)
                    
                    Canvas { context, size in
                        guard size.width > 0, size.height > 0 else { return }
                        
                        let scaleX = size.width / (viewport.maxReal - viewport.minReal)
                        let scaleY = size.height / (viewport.maxImag - viewport.minImag)
                        
                        let complexViewportRect = CGRect(
                            x: viewport.minReal,
                            y: viewport.minImag,
                            width: viewport.maxReal - viewport.minReal,
                            height: viewport.maxImag - viewport.minImag
                        )
                        
                        context.transform = CGAffineTransform(translationX: -viewport.minReal, y: -viewport.minImag)
                            .concatenating(CGAffineTransform(scaleX: scaleX, y: scaleY))
                        
                        let colors:[Float] = [Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple, Color.pink].map {
                            $0.toFloat()
                        }.flatMap { $0 }
                        
                        // Fetch the metal function from ShaderLibrary
                        let mandelbrotShader = Shader(
                            function: ShaderLibrary.mandelbrot,
                            arguments:[
                                .float4(minRealSplit.hi, minRealSplit.lo, maxRealSplit.hi, maxRealSplit.lo),
                                .float4(minImagSplit.hi, minImagSplit.lo, maxImagSplit.hi, maxImagSplit.lo),
                                .float2(Float(size.width), Float(size.height)),
                                .float2(0, 0),
                                .floatArray(colors)
                            ]
                        )
                        
                        // Render the shader to fill the full bounds
                        context.fill(Path(complexViewportRect), with: .shader(mandelbrotShader))
                    }
                    .ignoresSafeArea()
                    .gesture(
                        SimultaneousGesture(
                            // Pan Gesture
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    let aspect = size.width > 0 ? size.width / size.height : 1.0
                                    let xRange = zoomRadius * max(aspect, 1.0)
                                    let yRange = zoomRadius * max(1.0 / aspect, 1.0)
                                    
                                    // Commit the final translation change directly to state coordinates
                                    centerReal -= (Double(value.translation.width) / Double(size.width)) * xRange * 2
                                    centerImag -= (Double(value.translation.height) / Double(size.height)) * yRange * 2
                                    dragOffset = .zero // Reset translation buffer
                                },
                            // Pinch to Zoom Gesture
                            MagnifyGesture()
                                .onChanged { value in
                                    let aspect = size.width > 0 ? size.width / size.height : 1.0

                                    if zoomAnchorReal == nil {
                                        let xRangeAtStart = zoomRadius * max(aspect, 1.0)
                                        let yRangeAtStart = zoomRadius * max(1.0 / aspect, 1.0)
                                        
                                        let centerRealAtStart = centerReal - (Double(dragOffset.width) / Double(size.width)) * xRangeAtStart * 2
                                        let centerImagAtStart = centerImag - (Double(dragOffset.height) / Double(size.height)) * yRangeAtStart * 2
                                        
                                        let pctX = Double(value.startLocation.x / size.width)
                                        let pctY = Double(value.startLocation.y / size.height)
                                        
                                        zoomAnchorReal = centerRealAtStart - xRangeAtStart + (pctX * xRangeAtStart * 2)
                                        zoomAnchorImag = centerImagAtStart + yRangeAtStart - (pctY * yRangeAtStart * 2)
                                    }
                                    activeMagnification = value.magnification
                                }
                                .onEnded { value in
                                    let aspect = size.width > 0 ? size.width / size.height : 1.0
                                    
                                    if let anchorR = zoomAnchorReal, let anchorI = zoomAnchorImag {
                                        let newZoomRadius = zoomRadius / Double(value.magnification)
                                        let newXRange = newZoomRadius * max(aspect, 1.0)
                                        let newYRange = newZoomRadius * max(1.0 / aspect, 1.0)
                                        
                                        let pctX = Double(value.startLocation.x / size.width)
                                        let pctY = Double(value.startLocation.y / size.height)
                                        
                                        // Recalculate where the center must be so the anchor keeps its position relative to the screen layout percentages
                                        centerReal = anchorR - (pctX * newXRange * 2) + newXRange
                                        centerImag = anchorI + (pctY * newYRange * 2) - newYRange
                                        zoomRadius = newZoomRadius
                                    }
                                    
                                    // Commit zoom changes securely to prevent drift jump
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
    
    private func splitDouble(_ value: Double) -> (hi: Float, lo: Float) {
        let hi = Float(value)
        let lo = Float(value - Double(hi))
        return (hi, lo)
    }
    
    private struct ViewportBounds {
        let minReal: Double
        let maxReal: Double
        let minImag: Double
        let maxImag: Double
    }
    
    private func calculateViewport(for size: CGSize) -> ViewportBounds {
        let aspectRatio = size.width > 0 ? Double(size.width / size.height) : 1.0
        let effectiveZoom = zoomRadius / Double(activeMagnification)
        let xRange = effectiveZoom * max(aspectRatio, 1.0)
        let yRange = effectiveZoom * max(1.0 / aspectRatio, 1.0)
        
        // If we are pinching, compute the offset center relative to our frozen target anchor point
        if activeMagnification != 1.0, let anchorR = zoomAnchorReal, let anchorI = zoomAnchorImag {
            let currentXRange = zoomRadius * max(aspectRatio, 1.0)
            let currentYRange = zoomRadius * max(1.0 / aspectRatio, 1.0)
            let currentCenterReal = centerReal - (Double(dragOffset.width) / Double(size.width)) * currentXRange * 2
            let currentCenterImag = centerImag + (Double(dragOffset.height) / Double(size.height)) * currentYRange * 2
            
            return ViewportBounds(
                minReal: anchorR - (xRange * 2 * (anchorR - (currentCenterReal - xRange)) / (xRange * 2 * Double(activeMagnification))),
                maxReal: anchorR + (xRange * 2 * ((currentCenterReal + xRange) - anchorR) / (xRange * 2 * Double(activeMagnification))),
                minImag: anchorI - (yRange * 2 * (anchorI - (currentCenterImag - yRange)) / (yRange * 2 * Double(activeMagnification))),
                maxImag: anchorI + (yRange * 2 * ((currentCenterImag + yRange) - anchorI) / (yRange * 2 * Double(activeMagnification)))
            )
        }
        
        // Default standard state calculations used during basic pans
        let currentCenterReal = centerReal - (Double(dragOffset.width) / Double(size.width)) * xRange * 2
        let currentCenterImag = centerImag - (Double(dragOffset.height) / Double(size.height)) * yRange * 2
        
        return ViewportBounds(
            minReal: currentCenterReal - xRange,
            maxReal: currentCenterReal + xRange,
            minImag: currentCenterImag - yRange,
            maxImag: currentCenterImag + yRange
        )
    }
}

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
