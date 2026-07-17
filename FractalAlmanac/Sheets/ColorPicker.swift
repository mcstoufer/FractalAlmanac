//
//  ColorPicker.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/2/26.
//
import SwiftUI

struct ColorPickerCell: View {
    var color: any NumericColorProtocol
    
    var body: some View {
        HStack(alignment: .center) {
            Rectangle()
                .fill(color.systemColor)
                .frame(width: 50, height: 28)
                .cornerRadius(14)
                .padding([.leading, .trailing], 10)
            
            Text(color.naturalDescription)
                .frame(height: 28)
            Spacer()
        }
    }
}

struct PaletteColorPicker: View {
    @State private var selectedColor: PaletteColor? = .clear
    @State private var selectedSystemColor: Color = .clear
    @State private var customSystemColorName: String? = "New Color name" // Can be edited or wiped
    @State private var debounceTask: Task<Void, Never>? = nil
    
    @Environment(\.dismiss) var dismiss

    var colorPickerDelegate:ColorPickerSelectionProtocol?
    let allSortedColors = PaletteColor.allColorsSorted()
    
    var body: some View {
        VStack(alignment: .leading) {
            List(selection: $selectedColor) {
                ForEach(allSortedColors) { paletteColor in
                    ColorPickerCell(color: paletteColor)
                        .listRowInsets(EdgeInsets())
                        .tag(paletteColor)
                }
            }
            .onChange(of: selectedColor) { _, newColor in
                if let newColor {
                    colorPickerDelegate?.didSelect(color: newColor.systemColor, name: newColor.naturalDescription)
                    dismiss()
                }
            }
            .environment(\.defaultMinListRowHeight, 34)
            
            NamedColorPicker(
                selection: $selectedSystemColor,
                colorName: $customSystemColorName
            )
                .padding()
                .presentationDetents([.medium])
                .onChange(of: selectedSystemColor) {
                    _,
                    newColor in
                    // Cancel the previous task if the user is still dragging
                    debounceTask?.cancel()
                    
                    // Start a new task that waits for the user to stop dragging
                    debounceTask = Task {
                        do {
                            // Wait for 0.3 seconds of inactivity
                            try await Task.sleep(for: .seconds(0.3))
                            
                            // Check if the task was cancelled before assigning
                            if !Task.isCancelled {
//                                finalSystemColor = newColor
                                colorPickerDelegate?.didSelect(
                                    color: selectedSystemColor,
                                    name: customSystemColorName
                                )
                            }
                        } catch {
                            // Task was cancelled because a new color was picked
                        }
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

#Preview {
    PaletteColorPicker()
}
