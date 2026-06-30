//
//  Array+Double+Extent.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//
import CoreGraphics

extension Array where Element == Double {
    func toExtent() -> Extent {
        guard self.count == 4 else {
            return CGRectZero.toExtent()
        }
        return Extent(XMin: self[0], XMax: self[1], YMin: self[2], YMax: self[3])
    }
}
