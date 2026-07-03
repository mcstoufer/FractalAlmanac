//
//  PaletteBuilder.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/2/26.
//

import SwiftUI

struct ColorPaletteItem: View, Hashable {
    var color: PaletteColor
    
    var body: some View {
        HStack(alignment: .center) {
            Rectangle()
                .frame(width: 40, height: 22)
                .cornerRadius(12)
                .border(Color(uiColor: .lightGray), width: 1.0)
                .background(color.rawValue.systemColor)
                .padding([.leading, .trailing], 10)
            Text(color.naturalDescription)
        }
    }
}

struct PaletteBuilder: View {
    
    var paletteBuilderDelegate: PaletteBuilderProtocol?
    var filters = ["Glow", "Soften", "Off"]
    var columns = [
        GridItem(.fixed(100), spacing: 16)
    ]
    
    private var candidateColorPalette = Array(1...16).map {index in
        ColorPaletteItem(color: index == 0 ? .red : index == 15 ? .black : .clear)
    }
    
    @State private var paletteName = ""
    @State private var filterSwitch = "Off"
    @State private var isInterpolateEnabled = false
    @State private var interpolateValue = 16.0

    @Environment(\.dismiss) var dismiss

    public init(pbDelegate: PaletteBuilderProtocol) {
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
            //                ScrollView(.vertical) { // 2. Wrap the grid in a scroll view
            //                    LazyVGrid(columns: columns, spacing: 16) { // 3. Use LazyVGrid for lazy-loading cells
            //                       ForEach(candidateColorPalette, id: \.self) { item in
            //                           Text(item.color.naturalDescription)
            //                               .frame(maxWidth: 132, minHeight: 31)
            //                               .background(item)
            //                               .cornerRadius(8)
            //                        }
            //                    }
            //                    .frame(width: 568, height: 153)
            //                    .padding()
            //                }
            
            //                HStack(alignment: .top) {
            //                    Toggle("Interpolate", isOn: $isInterpolateEnabled)
            //                        .padding()
            //                    Spacer()
            //                    Text("\(Int(interpolateValue))")
            //                    Slider(value: $interpolateValue, in: 16...64, step: 1.0)
            //                }
            //                .padding()
            //
            
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
