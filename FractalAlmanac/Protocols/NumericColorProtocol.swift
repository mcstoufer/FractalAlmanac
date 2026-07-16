//
//  NumericColorProtocol.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/15/26.
//

import SwiftUI

protocol NumericColorProtocol: Hashable {
    var naturalDescription: String { get }
    var systemColor: Color { get }
}
