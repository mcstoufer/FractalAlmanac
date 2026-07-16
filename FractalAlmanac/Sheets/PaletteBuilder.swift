//
//  PaletteBuilder.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/2/26.
//

import SwiftUI

struct ColorPaletteItem: View, Hashable, Identifiable {
    let id = UUID()
    
    var color: PaletteColor
    
    var body: some View {
        HStack(alignment: .center) {
            Rectangle()
                .fill(color.systemColor)
                .frame(width: 40, height: 22)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
            Text(color.naturalDescription)
                .padding(.leading, 8)
        }
    }
}

struct PaletteBuilder: View, ColorPickerSelectionProtocol {
    
    let paletteBuilderDelegate: PaletteBuilderProtocol?
    var filters = ["Glow", "Soften", "Off"]
    var columns = [
        GridItem(
            .adaptive(minimum: 175, maximum: 225),
            spacing: 16,
            alignment: .leading
        )
    ]
    
    @State private var candidateColorPalette = Array(0...15).map {index in
        ColorPaletteItem(
            color: index == 0 ? PaletteColor.red : index == 15 ? PaletteColor.black : PaletteColor.clear
        )
    }
    
    @State private var paletteName = ""
    @State private var filterSwitch = "Off"
    @State private var isInterpolateEnabled = false
    @State private var interpolateValue = 16.0
    @State private var selected: ColorPaletteItem? = nil
    
    @Environment(\.dismiss) var dismiss

    public init(pbDelegate: PaletteBuilderProtocol? = nil) {
        paletteBuilderDelegate = pbDelegate
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                Spacer()
                TextField(text: $paletteName, prompt: Text("New Palette Name")) {
                    Text("New Palette Name")
                }
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                Picker("", selection: $filterSwitch) {
                    ForEach(filters, id: \.self) { filter in
                        Text(filter).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
            }
            .padding([.leading, .trailing], 16)
            .padding(.top, 8)
            
            ScrollView(.vertical) {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(candidateColorPalette, id: \.self) { item in
                        Button(action: {
                            selected = item
                        }) {
                            item.tag(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }.sheet(item: $selected) { item in
                PaletteColorPicker(colorPickerDelegate: self)
            }
            .padding()
            
            Spacer()
            HStack(alignment: .center) {
                Toggle("Interpolate", isOn: $isInterpolateEnabled)
                    .frame(width: 200)
                Spacer()
                Text("\(Int(interpolateValue))")
                Slider(value: $interpolateValue, in: 16...64, step: 1.0)
                    .frame(width: 200)
            }
            .padding()
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: buildGradientColors(),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 50)
                .padding([.leading, .trailing], 16)
            
            Spacer()
            Divider()
            HStack(alignment: .top) {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Save") {
                    paletteBuilderDelegate?.didCreateNewPalette()
                    dismiss()
                }
            }
            .padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 8)
        }
    }
    
    private func buildGradientColors() -> [Color] {
        var interpolatedColors = candidateColorPalette.filter { color in
            color.color != .clear
        }.map {
            $0.color.rawValue
        }
        if isInterpolateEnabled {
            interpolatedColors = interpolatedColors.interpolateColorScheme(steps: Int(interpolateValue))
        }
        return interpolatedColors.map { $0.systemColor }
    }
    
    func didSelect(color c: PaletteColor) {
        if let index = candidateColorPalette.firstIndex(where: { $0.id == selected?.id }) {
            candidateColorPalette[index].color = c
        }
    }
}

#Preview {
    PaletteBuilder()
}
