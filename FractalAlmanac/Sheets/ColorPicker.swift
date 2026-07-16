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
                .fill(color.systemColor)
                .frame(width: 40, height: 36)
                .cornerRadius(16)
                .padding([.leading, .trailing], 10)
            Text(color.naturalDescription)
            Spacer()
        }
    }
}

struct PaletteColorPicker: View {
    @State private var selectedColor: PaletteColor? = nil
//    @State private var selectedSystemColor: Color = .clear
//    @State private var finalSystemColor: Color = .clear
//    @State private var isPickerPresented = false
    
    @Environment(\.dismiss) var dismiss

    var colorPickerDelegate:ColorPickerSelectionProtocol?
    let allSortedColors = PaletteColor.allColorsSorted()
    
    var body: some View {
        VStack(alignment: .leading) {
            List(selection: $selectedColor) {
                ForEach(allSortedColors) { paletteColor in
                    ColorPickerCell(color: paletteColor)
                        .tag(paletteColor)
                }
            }
            .onChange(of: selectedColor) { oldColor, newColor in
                if let newColor {
                    colorPickerDelegate?.didSelect(color: newColor)
                    dismiss()
                }
            }
//            Button("Pick a Color") {
//                isPickerPresented.toggle()
//            }
//            .buttonStyle(.borderedProminent)
           
            Divider()
            Button("Dismiss") {
                dismiss() // Closes the modal
            }
            .padding()
        }
//        .sheet(isPresented: $isPickerPresented,
//               onDismiss: {
//            finalSystemColor = selectedSystemColor
//            colorPickerDelegate?.didSelect(color: finalSystemColor.paletteColor)
//        }, content: {
//            ColorPicker("Select a System Color", selection: $selectedSystemColor)
//                .padding()
//                .presentationDetents([.medium])
//            Spacer()
//        })
    }
}

#Preview {
    PaletteColorPicker()
}
