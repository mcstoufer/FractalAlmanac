//
//  UnifiedRowItem.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/20/26.
//

internal import CoreData
import SwiftUI

struct UnifiedRowItem: Identifiable, Hashable {
    let id: String
    let title: String
    let base: any ColorSchemeProtocol
    
    init(_ item: some ColorSchemeProtocol) {
        self.id = item.stableID
        self.title = item.paletteName
        self.base = item
    }
    
    static func == (lhs: UnifiedRowItem, rhs: UnifiedRowItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
