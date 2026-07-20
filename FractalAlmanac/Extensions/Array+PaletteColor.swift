//
//  Array+PaletteColor.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/17/26.
//

extension Array where Element == PaletteColor {
    var asNumeric: [UInt32] {
        return self.map { $0.rawValue }
    }
}
