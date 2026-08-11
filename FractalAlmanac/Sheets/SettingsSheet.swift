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
            HStack(alignment: .top) {
                Text("Center (Real)")
                    .frame(width: 200, alignment: .leading)
                Text(String(format: "%.16g", state.centerReal))
            }
            HStack(alignment: .top) {
                Text("Center (Imag)")
                    .frame(width: 200, alignment: .leading)
                Text(String(format: "%.16g", state.centerImag))
            }
            HStack(alignment: .top) {
                Text("Magnification")
                    .frame(width: 200, alignment: .leading)
                Text(formatScale(state.baseZoom))
            }
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
    
    private func formatScale(_ rawScale: Double) -> String {
        if rawScale <= 1.0 {
            return String(format: "%.2f", 1.0/rawScale)
        } else {
            let adustedScale = -(1.0/rawScale)
            if adustedScale > 0.01 {
                return String(format: "%.5f", adustedScale)
            } else {
                return String(format: "%.5e", adustedScale)
            }
        }
    }
}
