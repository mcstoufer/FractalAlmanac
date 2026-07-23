//
//  RenderModel.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import UIKit
internal import Combine
import SwiftUI


class RenderModel: ObservableObject, DataModelRenderProtocol, PaletteProtocol, ModelProtocol {
   
    @Published var isRendering = false
    @Published var renderingProgress:Float = 0.0
    @Published var newImage: Image? = nil
    
    var extents = Extent.newExtentFrom(rect: CGRectZero)

    lazy var dataModel = UserDefaults.standard.lastSelectedModel.newDataModel(
        forSize: CGSize(
            width: minExtent,
            height: minExtent
        ),
        listener:self
    )

//    private var pastImages = [UIImage]()
    private var currentPallete:(any ColorSchemeProtocol)?
    private var currentModel:FractalModel?
    private let service: DrawActor
    
    init(service:DrawActor = DrawActor()) {
        self.service = service
    }
    
    private var minExtent:CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return 0 }
        let bounds = windowScene.effectiveGeometry.coordinateSpace.bounds
        return min(bounds.width, bounds.height)
    }
    
    private var windowInterfaceOrientation: UIInterfaceOrientation? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return .unknown
        }
        return scene.effectiveGeometry.interfaceOrientation
    }
    
    func startRendering() {
        Task {
            if self.isRendering == true {
                return
            }
            
            //        let start = DispatchTime.now()
            guard let renderedImage = await service.draw(
                width: Int(self.minExtent),
                height: Int(self.minExtent),
                dataModel: dataModel
            ) else {
                return
            }
            
            dataModel.release()
            //        let end = DispatchTime.now()
            self.newImage = Image(uiImage: renderedImage)
            self.isRendering = false
        }
    }
    
    // MARK: - DataModelRenderProtocol
    func renderingHasBegun() {
        isRendering = true
    }
    
    func renderingHasEnded() {
//        isRendering = false
    }
    
    func updateRenderingProgress(progress: Float) async {
        await MainActor.run {
            renderingProgress = progress
        }
    }
    
    func precisionExtentsReached() {
        print("Max precision reached")
    }
    
    func extentsHaveRefreshed() async {
        startRendering()
    }
    
    // MARK: - PaletteProtocol
    func paletteSelectionDidChange(p: any ColorSchemeProtocol) {
        currentPallete = p
        renderingProgress = 0.0
        dataModel.setNewPallete(p: p)
        newImage = nil
//        Task {
//            startRendering()
//        }
    }
    
    func paletteCycleDidChange(b: Bool) {
        //
    }
    
    func lastSelectedPalette() -> (any ColorSchemeProtocol)? {
        return currentPallete
    }
    
    // MARK: - ModelProtocol
    func modelSelectionDidChange(f: FractalModel) {
        currentModel = f
        renderingProgress = 0.0
        dataModel = f.newDataModel(forSize: CGSize(width: minExtent, height: minExtent), listener: self)
        newImage = nil
        Task {
            startRendering()
        }
    }
    
    func lastSelectedModel() -> FractalModel? {
        return currentModel
    }
}
