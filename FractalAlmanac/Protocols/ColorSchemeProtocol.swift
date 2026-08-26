//
//  ColorSchemeProtocol.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 6/29/26.
//

import SwiftUI

enum RenderingFilter:Int {
    case Glow=0
    case Blur
    case Off
}

protocol ColorSchemeProtocol: Identifiable, Equatable {
    var stableID: String { get }
    
    var paletteName: String { get }
    var paletteShaderColors: [Float] { get }
    func schemeColors() -> [UInt32]
    func schemeSystemColors() -> [Color]
    func colorSchemeFilter() -> RenderingFilter
}
