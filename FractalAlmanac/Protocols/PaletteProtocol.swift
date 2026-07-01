//
//  PaletteProtocol.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/1/26.
//


protocol PaletteProtocol: AnyObject {
    func palleteSelectionDidChange(p:ColorSchemeProtocol)
    func lastSelectedPallete() -> (ColorSchemeProtocol)?
}
