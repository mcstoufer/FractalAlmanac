//
//  PalettePicker.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/1/26.
//

import SwiftUI

struct PalettePickerCell: View {
    var palette: any ColorSchemeProtocol
    
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

struct PalettePicker: View, PaletteBuilderProtocol {
    @State private var selectedPalette: Palette? = (UserDefaults.standard.lastSelectedPalette as! Palette)
    @State private var customPalettes: [ColorScheme]? = nil
    @State private var showBuilderSheet = false

    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    let paletteDelegate:PaletteProtocol?
    
    var body: some View {
        VStack(alignment: .leading) {
            List(selection: $selectedPalette) {
                Section(header: Text(PaletteStyle.Classic.rawValue)) {
                    ForEach(Palette.classicPalettes()) { palette in
                        PalettePickerCell(palette: palette)
                            .tag(palette)
                    }
                }
                Section(header: Text(PaletteStyle.Enhanced.rawValue)) {
                    ForEach(Palette.enhancedPalettes()) { palette in
                        PalettePickerCell(palette: palette)
                            .tag(palette)
                    }
                }
                if let customPalettes {
                    Section(header: Text(PaletteStyle.Custom.rawValue)) {
                        ForEach(customPalettes) { palette in
                            PalettePickerCell(palette: palette)
                                .tag(palette)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .onChange(of: selectedPalette) { oldPalette, newPalette in
                if let newPalette {
                    paletteDelegate?.palleteSelectionDidChange(p: newPalette)
                    UserDefaults.standard.lastSelectedPalette = newPalette
                    dismiss()
                }
            }
            Divider()
            HStack(alignment: .center) {
                Button("New...") {
                    showBuilderSheet.toggle()
                }
                Spacer()
                Button("Dismiss") {
                    dismiss() // Closes the modal
                }
            }
            .padding()
        }
        .task {
            loadCustomColors()
        }
        .sheet(isPresented: $showBuilderSheet) {
            PaletteBuilder(pbDelegate: self)
                .frame(width: 750)
                .presentationSizing(.fitted)
        }
    }

    private func loadCustomColors() {
        customPalettes = ColorScheme.allCustomColorSchemes(on: viewContext)
    }
    
    // MARK: - PaletteBuilderProtocol
    func didUpdateExistingPalette(indexPath:IndexPath) {
        loadCustomColors()
    }
    
    func didCreateNewPalette() {
        loadCustomColors()
    }
}
