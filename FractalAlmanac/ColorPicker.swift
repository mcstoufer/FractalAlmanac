//
//  ColorPicker.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/2/26.
//
import SwiftUI

struct ColorPickerCell: View {
    var color: PaletteColor
    
    var body: some View {
        HStack(alignment: .center) {
            Rectangle()
                .background(color.systemColor)
                .frame(width: 40, height: 36)
                .cornerRadius(16)
                .padding([.leading, .trailing], 10)
            Text(color.naturalDescription)
            Spacer()
        }
    }
}

struct ColorPicker: View {
    @State private var selectedColor: PaletteColor? = .clear
    @Environment(\.dismiss) var dismiss

    var colorPickerDelegate:ColorPickerSelectionProtocol?
    
    var body: some View {
        VStack(alignment: .leading) {
            List(selection: $selectedColor) {
                ForEach(PaletteColor.allColorsSorted()) { paletteColor in
                    ColorPickerCell(color: paletteColor)
                        .tag(paletteColor)
                }
            }
            .onChange(of: selectedColor) { oldColor, newColor in
                if let newColor {
                    colorPickerDelegate?.didSelect(color: newColor, forIndex: 0)
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
