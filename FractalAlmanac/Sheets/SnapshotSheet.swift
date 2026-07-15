//
//  SnapshotSheet.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/15/26.
//
import SwiftUI

struct SnapshotSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Button("Dismiss") {
            dismiss() // Closes the modal
        }
        .padding()
    }
}
