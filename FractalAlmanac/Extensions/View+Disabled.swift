//
//  View+Disabled.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/20/26.
//

import SwiftUI

extension View {
    @ViewBuilder
    func greyOutDisabled(_ isDisabled: Bool) -> some View {
        self
            .foregroundStyle(isDisabled ? .gray : .primary)
            .disabled(isDisabled)
    }
}
