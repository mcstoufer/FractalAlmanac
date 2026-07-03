//
//  PaletteBuilderProtocol.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/2/26.
//

import Foundation


protocol PaletteBuilderProtocol {
    func didCreateNewPalette()
    func didUpdateExistingPalette(indexPath:IndexPath)
}
