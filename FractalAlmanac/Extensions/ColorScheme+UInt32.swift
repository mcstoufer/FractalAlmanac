//
//  ColorScheme+UInt32.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/20/26.
//

import SwiftUI
internal import CoreData

extension ColorScheme {
    // Convert [UInt32] to Data to save in Core Data
    public var colorsArray: [UInt32] {
        get {
            guard let data = self.colors else { return [] } // 'rawData' is your Binary Data attribute
            return data.withUnsafeBytes { buffer in
                Array(buffer.bindMemory(to: UInt32.self))
            }
        }
        set {
            self.colors = newValue.withUnsafeBytes { Data($0) }
        }
    }
}
