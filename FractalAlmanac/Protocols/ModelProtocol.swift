//
//  ModelProtocol.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/2/26.
//


protocol ModelProtocol {
    func modelSelectionDidChange(f:FractalModel)
    func lastSelectedModel() -> (FractalModel)?
}
