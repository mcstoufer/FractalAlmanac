//
//  PaletteProtocol.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/1/26.
//


protocol PaletteProtocol {
    func paletteSelectionDidChange(p:any ColorSchemeProtocol)
    func paletteCycleDidChange(b: PaletteCycleStyle)
    func lastSelectedPalette() -> (any ColorSchemeProtocol)?
}
