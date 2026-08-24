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
        snapshot(size: nil)
    }
    
    @MainActor
    func snapshot(size explicitSize: CGSize?) -> UIImage? {
        // Wrap the SwiftUI view inside a UIKit controller
        let controller = UIHostingController(rootView: self.ignoresSafeArea())
        let view = controller.view
        
        let targetSize = explicitSize ?? controller.view.intrinsicContentSize
        guard targetSize.width > 0, targetSize.height > 0 else { return nil }
        
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.frame = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .black
        view?.layoutMargins = .zero
        view?.directionalLayoutMargins = .zero
        view?.insetsLayoutMarginsFromSafeArea = false
        view?.setNeedsLayout()
        view?.layoutIfNeeded()
        
        // Create the image renderer using the correct device screen scale
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            // drawHierarchy forces the GPU layer pipeline to rasterize correctly
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
