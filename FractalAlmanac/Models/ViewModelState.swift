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
    var lastValidTranslation: CGSize
    var lastValidScale: CGFloat
    
    private var _cachedShaderColors: [Float]
    
    init(
        centerReal: Double = 0,
        centerImag: Double = 0,
        isPinching: Bool = false,
        cyclePalette: PaletteCycleStyle = UserDefaults.standard.lastPaletteCycle,
        baseZoom: Double? = 1.0,
        fractalModel: FractalModel = UserDefaults.standard.lastSelectedModel,
        activePalette: any ColorSchemeProtocol = UserDefaults.standard.lastSelectedPalette,
        zoomAnchorReal: Double = 0.0,
        zoomAnchorImag: Double = 0.0,
        lastValidTranslation: CGSize = .zero,
        lastValidScale: CGFloat = 1.0
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
        self.lastValidTranslation = lastValidTranslation
        self.lastValidScale = lastValidScale
        self._cachedShaderColors = activePalette.paletteShaderColors
    }
    
    var paletteShaderColors: [Float] {
        return _cachedShaderColors
    }
}
