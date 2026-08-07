//
//  Settings.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/15/26.
//
import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let state: ViewModelState
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Center (Real) \(state.centerReal.formatted())")
            Text("Center (Imag) \(state.centerImag.formatted())")
            Text("Base Zoom \(state.baseZoom)")
            Spacer()
            Divider()
            HStack(alignment: .top) {
                Spacer()
                Button("Dismiss") {
                    dismiss() // Closes the modal
                }
                .padding(.trailing, 15)
            }
            .padding(.bottom, 8)
        }
        .padding()
    }
}
