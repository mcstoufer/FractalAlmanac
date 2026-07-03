//
//  ColorPickerSelectionProtocol.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/2/26.
//


protocol ColorPickerSelectionProtocol: AnyObject {
    func didSelect(color c:PaletteColor, forIndex index:Int)
}
