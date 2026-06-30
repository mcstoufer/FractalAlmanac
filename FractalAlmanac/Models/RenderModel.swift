//
//  RenderModel.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import UIKit
internal import Combine
import SwiftUI


class RenderModel: ObservableObject, DataModelRenderProtocol {
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
//    private var currentPallete:ColorSchemeProtocol?
//    private var currentModel:FractalModelFactory?
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
    
    func startRendering() async {
        Task.detached(priority: .utility) {
            if await self.isRendering == true {
                return
            }
            
            //        let start = DispatchTime.now()
            guard let renderedImage = await self.draw(width: Int(self.minExtent), height: Int(self.minExtent)) else {
                return
            }
            
            //        let end = DispatchTime.now()
            await MainActor.run {
                self.newImage = Image(uiImage: renderedImage)
                self.isRendering = false
            }
        }
    }
    
    @discardableResult
    func draw(width:Int,height:Int) async -> UIImage?
    {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var cgImage:CGImage?
        
        var pixelData = await dataModel.assemble()
        pixelData.withUnsafeMutableBytes( { (rawBufferPtr: UnsafeMutableRawBufferPointer) in
            if let rawPtr = rawBufferPtr.baseAddress {
                let bitmapContext = CGContext(data: rawPtr,
                                              width: width,
                                              height: height,
                                              bitsPerComponent: 8,
                                              bytesPerRow: 4*width,
                                              space: colorSpace,
                                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                cgImage = bitmapContext?.makeImage()
            }
        })
        if let filteredImage = cgImage?.applyFilter(filter: dataModel.colorPalette.colorSchemeFilter()) {
            dataModel.release()
            return UIImage(cgImage: filteredImage)
        } else {
            return nil
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
        await startRendering()
    }
}
