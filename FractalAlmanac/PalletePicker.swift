//
//  PalletePicker.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/1/26.
//

import SwiftUI

struct PalettePickerCell: View {
    var palette: Palette
    
    var body: some View {
        HStack(alignment: .center) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: palette.schemeSystemColors(),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 40, height: 36)
                .padding([.leading, .trailing], 10)
            
            Text(palette.paletteName)
            Spacer()
        }
    }
}

struct PalettePicker: View {
    @State private var selectedPalette: Palette? = (UserDefaults.standard.lastSelectedPalette as! Palette)
    @Environment(\.dismiss) var dismiss
    
    let paletteDelegate:PaletteProtocol?
    
    var body: some View {
        VStack(alignment: .leading) {
            List(selection: $selectedPalette) {
                ForEach(Palette.allCases) { palette in
                    PalettePickerCell(palette: palette)
                        .tag(palette)
                }
            }
            .onChange(of: selectedPalette) { oldPalette, newPalette in
                if let newPalette {
                    paletteDelegate?.palleteSelectionDidChange(p: newPalette)
                    UserDefaults.standard.lastSelectedPalette = newPalette
                    dismiss()
                }
            }
            Divider()
            Button("Dismiss") {
                dismiss() // Closes the modal
            }
            .padding()
        }
    }
}
