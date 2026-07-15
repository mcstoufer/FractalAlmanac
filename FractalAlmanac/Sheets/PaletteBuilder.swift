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
                .fill(color.rawValue.systemColor)
                .frame(width: 40, height: 22)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
            Text(color.naturalDescription)
                .padding(.leading, 8)
        }
        .border(Color.black.opacity(0.2), width: 1)
    }
}

struct PaletteBuilder: View {
    
    let paletteBuilderDelegate: PaletteBuilderProtocol?
    var filters = ["Glow", "Soften", "Off"]
    var columns = [
        GridItem(
            .adaptive(minimum: 100, maximum: 150),
            spacing: 16,
            alignment: .leading
        )
    ]
    
    private var candidateColorPalette = Array(0...15).map {index in
        ColorPaletteItem(color: index == 0 ? .red : index == 15 ? .black : .clear)
    }
    
    @State private var paletteName = ""
    @State private var filterSwitch = "Off"
    @State private var isInterpolateEnabled = false
    @State private var interpolateValue = 16.0

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
            
            ScrollView(.vertical) { // 2. Wrap the grid in a scroll view
                LazyVGrid(columns: columns, spacing: 16) { // 3. Use LazyVGrid for lazy-loading cells
                    ForEach(candidateColorPalette, id: \.self) { $0 }
                }
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
}

#Preview {
    PaletteBuilder()
}
