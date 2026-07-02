//
//  ModelPicker.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 7/2/26.
//

import SwiftUI

struct ModelPickerCell: View {
    var model: FractalModel
    
    var body: some View {
        HStack(alignment: .center) {
            Image(model.rawValue)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .padding([.leading, .trailing], 10)
            Text(model.rawValue)
            Spacer()
        }
    }
}

struct ModelPicker: View {
    @State private var selectedModel: FractalModel? = UserDefaults.standard.lastSelectedModel
    @Environment(\.dismiss) var dismiss

    let modelDelegate: ModelProtocol?
    
    var body: some View {
        VStack(alignment: .leading) {
            List(selection: $selectedModel) {
                ForEach(FractalModel.allCases.sorted(by: {$0.rawValue < $1.rawValue})) { model in
                    ModelPickerCell(model: model)
                        .tag(model)
                }
            }
            .onChange(of: selectedModel) { oldModel, newModel in
                if let newModel {
                    modelDelegate?.modelSelectionDidChange(f: newModel)
                    UserDefaults.standard.lastSelectedModel = newModel
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
