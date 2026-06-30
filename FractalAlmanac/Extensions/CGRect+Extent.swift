//
//  CGRect+Extent.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//
import CoreGraphics

extension CGRect {
    func toExtent() -> Extent {
        return Extent(XMin: self.minX, XMax: self.maxX, YMin: self.minY, YMax: self.maxY)
    }
}
