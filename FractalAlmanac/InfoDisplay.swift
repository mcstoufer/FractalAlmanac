//
//  InfoDisplay.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/30/26.
//

import SwiftUI

struct InfoDisplay: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var fileContent: AttributedString = "Loading..."

    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                Text(fileContent)
                    .padding()
            }
            .onAppear() {
                loadBundleFile()
            }
            Divider()
            HStack(alignment: .bottom) {
                Spacer()
                Button("Dismiss") {
                    hasSeenOnboarding = true
                }
                .padding([.trailing, .bottom], 8)
            }
            .frame(height: 45)
        }
        .background(.white)
        .padding()
    }
    
    func loadBundleFile() {
        // 1. Locate the file in the app bundle
        guard let fileURL = Bundle.main.url(forResource: "infoView", withExtension: "html") else {
            fileContent = "Error: File not found in bundle."
            return
        }
        
        // 2. Read the content of the file
        do {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            if let attributedString = try? AttributedString(
                NSAttributedString(
                    data: Data(contents.utf8),
                    options: [
                        .documentType: NSAttributedString.DocumentType.html,
                        .characterEncoding: String.Encoding.utf8.rawValue
                    ],
                    documentAttributes: nil
                )
            ) {
                fileContent = attributedString // Renders natively in SwiftUI
            } else {
                fileContent = AttributedString(stringLiteral: contents) // Fallback to plain text
            }
        } catch {
            fileContent = AttributedString(stringLiteral:"Error: Could not read file content. \(error.localizedDescription)")
        }
    }
}
