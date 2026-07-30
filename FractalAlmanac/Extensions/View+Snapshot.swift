//
//  View+Snapshot.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/30/26.
//
import SwiftUI
import UIKit

extension View {
    @MainActor
    func snapshot() -> UIImage? {
        // Wrap the SwiftUI view inside a UIKit controller
        let controller = UIHostingController(rootView: self)
        let view = controller.view
        
        // Set bounds based on the view's layout size
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .black
        
        // Create the image renderer using the correct device screen scale
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            // drawHierarchy forces the GPU layer pipeline to rasterize correctly
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
