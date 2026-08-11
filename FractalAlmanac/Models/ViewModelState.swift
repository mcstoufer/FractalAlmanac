//
//  ViewModelState.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/30/26.
//

import CoreFoundation
import Foundation
import CoreGraphics

struct ViewModelState: Equatable {
    static func == (lhs: ViewModelState, rhs: ViewModelState) -> Bool {
        return lhs.activePalette.stableID == rhs.activePalette.stableID
    }
    
    var centerReal: Double
    var centerImag: Double
    var isPinching: Bool
    var cyclePalette: PaletteCycleStyle
    var baseZoom: Double
    var fractalModel: FractalModel
    var activePalette: any ColorSchemeProtocol {
        didSet {
            if oldValue.stableID != activePalette.stableID {
                _cachedShaderColors = activePalette.paletteShaderColors
            }
        }
    }
    var zoomAnchorReal: Double
    var zoomAnchorImag: Double
    var stableOrbitCenterReal: Double
    var stableOrbitCenterImag: Double
    var lastValidTranslation: CGSize
    var lastValidScale: CGFloat
    var panAnchorReal: Double
    var panAnchorImag: Double
    
    private var _cachedShaderColors: [Float]
    
    init(
        centerReal: Double = 0,
        centerImag: Double = 0,
        isPinching: Bool = false,
        cyclePalette: PaletteCycleStyle = UserDefaults.standard.lastPaletteCycle,
        baseZoom: Double = 1.0,
        fractalModel: FractalModel = UserDefaults.standard.lastSelectedModel,
        activePalette: any ColorSchemeProtocol = UserDefaults.standard.lastSelectedPalette,
        zoomAnchorReal: Double = 0.0,
        zoomAnchorImag: Double = 0.0,
        stableOrbitCenterReal: Double = -0.5,
        stableOrbitCenterImag: Double = 0.0,
        lastValidTranslation: CGSize = .zero,
        lastValidScale: CGFloat = 1.0,
        panAnchorReal: Double = 0.0,
        panAnchorImag: Double = 0.0
    ) {
        self.fractalModel = fractalModel
        self.centerReal = self.fractalModel.initialCenter.centerReal
        self.centerImag = self.fractalModel.initialCenter.centerImag
        self.isPinching = isPinching
        self.cyclePalette = cyclePalette
        self.baseZoom = self.fractalModel.baseZoom
        self.activePalette = activePalette
        self.zoomAnchorReal = zoomAnchorReal
        self.zoomAnchorImag = zoomAnchorImag
        self.stableOrbitCenterReal = stableOrbitCenterReal
        self.stableOrbitCenterImag = stableOrbitCenterImag
        self.lastValidTranslation = lastValidTranslation
        self.lastValidScale = lastValidScale
        self._cachedShaderColors = activePalette.paletteShaderColors
        self.panAnchorReal = panAnchorReal
        self.panAnchorImag = panAnchorImag
    }
    
    var paletteShaderColors: [Float] {
        return _cachedShaderColors
    }
    
    func uniformScale(for canvasSize: CGSize) -> Double {
        return (3.0 / Double(canvasSize.width)) / baseZoom
    }
    
    func scaleWindow(for gestureScale: CGFloat) -> Double {
        let activeScale = Double(gestureScale)
        let totalCurrentZoom = baseZoom * activeScale
        
        // 2. Turn zoom into a decreasing coordinate scale window (decreases as you zoom in)
        // 3.0 represents the standard horizontal width box of the Mandelbrot set
        return 3.0 / totalCurrentZoom
    }
}
