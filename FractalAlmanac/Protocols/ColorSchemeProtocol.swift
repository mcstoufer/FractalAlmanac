//
//  ColorSchemeProtocol.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

enum RenderingFilter:Int {
    case Glow=0
    case Blur
    case Off
}

protocol ColorSchemeProtocol {
    func colorSchemeName() -> String
    func colorSchemeColors() -> [UInt32]
    func colorSchemeFilter() -> RenderingFilter
}
