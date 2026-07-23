//
//  PalettePicker.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/1/26.
//

import SwiftUI

struct PalettePickerCell: View {
    var palette: UnifiedRowItem
    
    var body: some View {
        HStack(alignment: .center) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: palette.base.schemeSystemColors(),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 50, height: 28)
                .padding([.top, .bottom], 0)
                .padding([.leading, .trailing], 10)
            
            Text(palette.title)
                .frame(height: 28)
                .font(.body)
            Spacer()
        }
    }
}

struct PalettePicker: View, PaletteBuilderProtocol {
    @State private var selectedPalette: UnifiedRowItem?
    @State private var showBuilderSheet = false
    @State private var cyclePalette = UserDefaults.standard.lastPaletteCycle
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(
            keyPath: \ColorScheme.name,
            ascending: true
        )],
        animation: .default
    )
    private var dynamicPalettes: FetchedResults<ColorScheme>
    let classicPalettes = Palette.classicPalettes()
    let enahncedPalettes = Palette.enhancedPalettes()
    
    private var combinedItems: [String: [UnifiedRowItem]] {
        return [PaletteStyle.Classic.rawValue: classicPalettes.map { UnifiedRowItem($0) },
                PaletteStyle.Enhanced.rawValue: enahncedPalettes.map { UnifiedRowItem($0) },
                PaletteStyle.Custom.rawValue: dynamicPalettes.map { UnifiedRowItem($0) }]
    }
    
    let paletteDelegate:PaletteProtocol?
    
    var body: some View {
        VStack(alignment: .leading) {
            Toggle("Cycle Palette Colors", isOn: $cyclePalette)
                .padding([.top, .leading, .trailing], 10)
                .onChange(of: cyclePalette) { oldValue, newValue in
                    paletteDelegate?.paletteCycleDidChange(b: newValue)
                    UserDefaults.standard.lastPaletteCycle = newValue
                    dismiss()
                }
            
            List(selection: $selectedPalette) {
                Section(header: Text(PaletteStyle.Classic.rawValue)
                    .font(.title3)
                    .bold()
                ) {
                    ForEach(combinedItems[PaletteStyle.Classic.rawValue] ?? []) { palette in
                        PalettePickerCell(palette: palette)
                            .listRowInsets(EdgeInsets())
                            .tag(palette)
                    }
                }
                Section(header: Text(PaletteStyle.Enhanced.rawValue)
                    .font(.title3)
                    .bold()
                ) {
                    ForEach(combinedItems[PaletteStyle.Enhanced.rawValue] ?? []) { palette in
                        PalettePickerCell(palette: palette)
                            .listRowInsets(EdgeInsets())
                            .tag(palette)
                    }
                }
                if dynamicPalettes.count > 0 {
                    Section(header: Text(PaletteStyle.Custom.rawValue)
                        .font(.title3)
                        .bold()
                    ) {
                        ForEach(combinedItems[PaletteStyle.Custom.rawValue] ?? []) { palette in
                            PalettePickerCell(palette: palette)
                                .listRowInsets(EdgeInsets())
                                .tag(palette)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.defaultMinListRowHeight, 34)
            .onChange(of: selectedPalette) { oldPalette, newPalette in
                if let newPalette = newPalette?.base as? any ColorSchemeProtocol {
                    paletteDelegate?.paletteSelectionDidChange(p: newPalette )
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
        .sheet(isPresented: $showBuilderSheet) {
            PaletteBuilder(pbDelegate: self)
                .frame(width: 750)
                .presentationSizing(.fitted)
        }
    }
    
    // MARK: - PaletteBuilderProtocol
    func didUpdateExistingPalette() {
        //
    }
    
    func didCreateNewPalette() {
        //
    }
}
