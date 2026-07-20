//
//  Array+ColorPaletteItem.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/20/26.
//

import SwiftUI

extension Array where Element == ColorPaletteItem {
    func filterOutColor(color: Color) -> Self {
        self.filter { color in
            color.color != .clear
        }
    }
    
    func toRawColors() -> [UInt32] {
        return self.compactMap { color in
            color.color.toUInt32()
        }
    }
}
