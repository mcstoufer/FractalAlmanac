//
//  DataModelProtocol.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import Foundation
import UIKit


protocol DataModelProtocol {
    var pixelData:Data {get}
    init(withExtents extents:ConvolutionalExtent, listener:DataModelRenderProtocol?)
    var extents: Extent { get }
    func setNewPallete(p:ColorSchemeProtocol)
    var colorPalette: ColorSchemeProtocol { get }
    @discardableResult func scaleExistingExtent(_ extent:CGRect) async throws -> Bool
    func updateWith(newExtent:Extent) async throws
    func goBack() -> Bool
    func reset() -> Bool
    func release()
    func loadPreviousExtent() -> Bool
    func hasZoomed() -> Bool
    func snapshotWithSourceImage(_:UIImage) -> SnapshotObject
    /**
     This function implements the specific algorithm(s) that populate the pixelData instance variable.
     
     Check each implementing class for a description on what is being done and how it should be invoked.
     I.e., what happens when its invoked multiple times.
     */
    func assemble() async -> Data
}
