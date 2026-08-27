//
//  Comparable+Clamping.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 8/27/26.
//

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
