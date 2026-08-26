//
//  Array+Double+Extent.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 6/29/26.
//
import CoreGraphics

extension Array {
    func appending(_ element: Element) -> [Element] {
        var copy = self
        copy.append(element)
        return copy
    }
}
