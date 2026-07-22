//
//  PaletteProtocol.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/1/26.
//


protocol PaletteProtocol {
    func paletteSelectionDidChange(p:any ColorSchemeProtocol)
    func lastSelectedPalette() -> (any ColorSchemeProtocol)?
}
