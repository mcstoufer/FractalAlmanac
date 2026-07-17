//
//  PaletteBuilder.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/2/26.
//

import SwiftUI
internal import CoreData

enum PaletteFilter: Int, CaseIterable, Identifiable, CustomStringConvertible {
    var id: Self { self }
    
    case Glow = 0
    case Soften
    case Off
    
    var description: String {
        switch self {
            case .Glow: return "Glow"
            case .Soften: return "Soften"
            case .Off: return "Off"
        }
    }
}

typealias ValidationContent = (title: String, message: String, ok: String)
enum ValidationState {
    
    case Failure(ValidationContent)
    case Override(ValidationContent)
    case Success
    
    var buttonRole: ButtonRole {
        switch self {
            case .Failure: return .cancel
            case .Override: return .destructive
            case .Success: return .confirm
        }
    }
    
    var buttonText: String {
        switch self {
            case .Failure(let content): return content.ok
            case .Override(let content): return content.ok
            case .Success: return "OK"
        }
    }
    
    var alertTitle: String {
        switch self {
            case .Failure(let content): return content.title
            case .Override(let content): return content.title
            case .Success: return "Success"
        }
    }
    
    var alertMessage: String {
        switch self {
            case .Failure(let content): return content.message
            case .Override(let content): return content.message
            case .Success: return "Your changes have been saved."
        }
    }
}

struct ColorPaletteItem: View, Hashable, Identifiable {
    let id = UUID()
    
    var color: Color
    var name: String
    
    var body: some View {
        HStack(alignment: .center) {
            Rectangle()
                .fill(color)
                .frame(width: 40, height: 22)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
            Text(name)
                .padding(.leading, 8)
        }
    }
}

struct PaletteBuilder: View, ColorPickerSelectionProtocol {
    @Environment(\.managedObjectContext) private var viewContext

    let paletteBuilderDelegate: PaletteBuilderProtocol?
    var columns = [
        GridItem(
            .adaptive(minimum: 175, maximum: 225),
            spacing: 16,
            alignment: .leading
        )
    ]
    
    @State private var candidateColorPalette = Array(0...15).map {index in
        ColorPaletteItem(
            color: index == 0 ? PaletteColor.red.systemColor : index == 15 ? PaletteColor.black.systemColor : PaletteColor.clear.systemColor,
            name: index == 0 ? PaletteColor.red.naturalDescription : index == 15 ? PaletteColor.black.naturalDescription : PaletteColor.clear.naturalDescription,
        )
    }
    
    @State private var errorMessage: String? = nil
    @State private var paletteName = ""
    @State private var filterSwitch:PaletteFilter = .Off
    @State private var isInterpolateEnabled = false
    @State private var interpolateValue = 16.0
    @State private var selected: ColorPaletteItem? = nil
    @State private var showingAlert = false
    
    @Environment(\.dismiss) var dismiss

    @State private var validationState: ValidationState = .Success
    
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
                    ForEach(PaletteFilter.allCases, id: \.self) { filter in
                        Text(filter.description).tag(filter)
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
            if errorMessage != nil {
                Text(errorMessage!)
                    .padding([.leading, .trailing], 8)
            }
            HStack(alignment: .top) {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Save") {
                    validationState = save()
                    switch validationState {
                        case .Failure(_):
                            showingAlert.toggle()
                        case .Override(_):
                            showingAlert.toggle()
                        case .Success:
                            paletteBuilderDelegate?.didCreateNewPalette()
                            dismiss()
                    }
                }
            }
            .padding([.leading, .trailing], 16)
            .padding([.top, .bottom], 8)
        }
        .alert(validationState.alertTitle, isPresented: $showingAlert) {
            Button("Cancel", role: .cancel) {
                
            }
            Button(validationState.buttonText, role: validationState.buttonRole) {
                if case .Override = validationState {
                    let colorScheme = ColorScheme.colorScheme(
                        forName:paletteName,
                        on: viewContext
                    ) ??
                    ColorScheme.newColorScheme(
                        on: viewContext
                    )
                    if colorScheme?.value(forKey: "name") != nil {
                        updateAndSave(colorScheme)
                        paletteBuilderDelegate?.didUpdateExistingPalette()
                    }
                }
            }
        } message: {
            Text(validationState.alertMessage)
        }
    }
    
    private func save() -> ValidationState {
        if let validation = validateInput() {
            return .Failure(
                (
                    title: "Error",
                    message: validation,
                    ok: "OK"
                )
            )
        } else {
            let colorScheme = ColorScheme.colorScheme(
                forName:paletteName,
                on: viewContext
            ) ??
            ColorScheme.newColorScheme(
                on: viewContext
            )
            if colorScheme?.value(forKey: "name") != nil {
                return .Override(
                    (
                        title: "Warning",
                        message: "You are attempting to overwrite an existing Palette. The previous colors will be updated with your selection.",
                        ok: "Continue"
                    )
                )
            }
            updateAndSave(colorScheme)
            return .Success
        }
    }
    
    private func validateInput() -> String? {
        if paletteName.count == 0 {
            return "You must provide a Palette name."
        } else if validCandidateColors().count < 6 {
            return "You must provide 6 or more colors for a Palette."
        } else if Palette.allCases.filter( { $0.rawValue == paletteName } ).count > 0 {
            return "You cannot overwrite Classic or Enhanced Palettes. Please select a new name instead."
        }
        return nil
    }
    
    private func updateAndSave(_ colorScheme:ColorScheme?) {
        
        colorScheme?.name = paletteName
        colorScheme?.colors = validCandidateColors()
        colorScheme?.filter = NSDecimalNumber(value:filterSwitch.rawValue)
        do {
            try colorScheme?.managedObjectContext?.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    private func validCandidateColors() -> [UInt32] {
        return candidateColorPalette.filter(
            { $0.color != .clear }
        ).map {
            $0.color.toUInt32()!
        }
    }
    
    private func buildGradientColors() -> [Color] {
        var interpolatedColors = candidateColorPalette.filter { color in
            color.color != .clear
        }.map {
            $0.color.toUInt32()!
        }
        if isInterpolateEnabled {
            interpolatedColors = interpolatedColors.interpolateColorScheme(steps: Int(interpolateValue))
        }
        return interpolatedColors.map { $0.systemColor }
    }
    
    func didSelect(color c: Color, name: String?) {
        if let index = candidateColorPalette.firstIndex(where: { $0.id == selected?.id }) {
            candidateColorPalette[index].color = c.systemColor
            candidateColorPalette[index].name = name ?? c.naturalDescription
        }
    }
}

#Preview {
    PaletteBuilder()
}
