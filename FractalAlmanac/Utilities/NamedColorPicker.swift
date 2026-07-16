//
//  NamedColorPicker.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/15/26.
//
import SwiftUI

struct NamedColorPicker: View {
    @Binding var selection: Color
    @Binding var colorName: String?
    
    // Fallback display title when colorName is nil or empty
    private var displayLabel: String {
        if let name = colorName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        return "Unnamed Color"
    }
    
    var body: some View {
        HStack {
            if colorName != nil {
                // Editable text field wrapped in an optional binding proxy
                TextField("Color Name", text: Binding(
                    get: { colorName ?? "" },
                    set: { colorName = $0 }
                ))
                .textFieldStyle(.plain)
            } else {
                // Static fallback text if the name binding is completely absent
                Text(displayLabel)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Native SwiftUI ColorPicker with hidden system text label
            ColorPicker("", selection: $selection)
                .labelsHidden()
        }
    }
}

#Preview {
    NamedColorPicker(selection: .constant(.red), colorName: .constant("My Color"))
}
