//
//  SnapshotProtocol.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import UIKit


protocol BookmarkProtocol {
    func shouldLoadBookmark(_ snapshot:BookmarkObject)
}

protocol BookmarkObject {
    func bookmarkName() -> String
    func modelName() -> String
    func colorScheme() -> any ColorSchemeProtocol
    func image() -> UIImage
    func center() -> (centerReal: Double, centerImag: Double)
    func zoom() -> Double
}
