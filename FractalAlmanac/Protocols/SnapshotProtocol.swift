//
//  SnapshotProtocol.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import UIKit


protocol SnapshotProtocol {
    func shouldLoadNewSnapshot(_ snapshot:SnapshotObject)
}

protocol SnapshotObject {
    func snapshotName() -> String
    func modelName() -> String
    func colorScheme() -> any ColorSchemeProtocol
    func image() -> UIImage
}
