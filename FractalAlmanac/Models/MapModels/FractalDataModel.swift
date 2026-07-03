//
//  FractalDataModel.swift
//  Fractal
//
//  Created by Martin Stoufer on 8/24/20.
//

import Foundation
import UIKit

class FractalDataModel: DataModelProtocol {
    var currentExtent = Extent(XMin: 0, XMax: 0, YMin: 0, YMax: 0)
    var bufferSize = CGSize.zero
    var maxIters = 0
    var defaultSpan = 0.0
    var defaultXExtent = 0.0
    var defaultYExtent = 0.0
    var wideBuffer: [Data]?
    var pixelData = Data()
    var colorPalette = UserDefaults.standard.lastSelectedPalette
    var rendering:Bool {
        didSet {
            rendering == true ? renderingListener?.renderingHasBegun() : renderingListener?.renderingHasEnded()
        }
    }
    var model: FractalModel = .Mandelbrot
    
    weak var renderingListener:DataModelRenderProtocol?
    
    private var pastExtents = [Extent]()
    private var colorSchemeColor = Data()
    private var zoomed = false
    
    required init(withExtents extents:ConvolutionalExtent, listener:DataModelRenderProtocol?) {
        pixelData.reserveCapacity(Int(extents.bufferSize.width * extents.bufferSize.height))
        bufferSize = extents.bufferSize
        maxIters = extents.maxIters
        defaultSpan = extents.defaultSpan
        defaultXExtent = extents.minXExtent
        defaultYExtent = extents.minYExtent
        renderingListener = listener
        rendering = false
        
        populateColorScheme(colors: UserDefaults.standard.lastSelectedPalette.schemeColors())
        configureDefaultExtents()
    }
    
    func configureDefaultExtents() {
        currentExtent = Extent(
            XMin: defaultXExtent,
            XMax: defaultXExtent+defaultSpan,
            YMin: defaultYExtent,
            YMax: defaultYExtent+defaultSpan
        )
    }
    
    var extents: Extent {
        return currentExtent
    }
    
    func setNewPallete(p: any ColorSchemeProtocol) {
        colorPalette = p
        populateColorScheme(colors: p.schemeColors())
    }
    
    func populateColorScheme(colors:[UInt32]) {
        colorSchemeColor.removeAll()
        colors.forEach( { rawValue in
            var rawData = withUnsafeBytes(of:rawValue) { Data($0) }
            rawData.reverse()
            colorSchemeColor.append(rawData)
        })
    }

    func scaleExistingExtent(_ extents: CGRect) async throws -> Bool {
        if extents == CGRect.zero {
            configureDefaultExtents()
            pastExtents.removeAll()
            return false
        }
        zoomed = true
        
        let xMinOffsetScale = Double(extents.origin.x / bufferSize.width)
        let xMaxOffsetScale = Double((bufferSize.width - (extents.origin.x + extents.size.width)) / bufferSize.width)
        let yMaxOffsetScale = Double(extents.origin.y / bufferSize.height)
        let yMinOffsetScale = Double((bufferSize.height - (extents.origin.y+extents.size.height)) / bufferSize.height)
        
        let XSpan = (currentExtent.XMax - currentExtent.XMin)
        let YSpan = (currentExtent.YMax - currentExtent.YMin)
        
        // We can't interpolate properly if the span cannot cover the delta
        if YSpan < 5.0e-13 {
            renderingListener?.precisionExtentsReached()
            return false
        }
        
        pastExtents.append(currentExtent)
        currentExtent = currentExtent.scaleExtent(withMinXScale: xMinOffsetScale,
                                                  withMaxXScale: xMaxOffsetScale,
                                                  withMinYScale: yMinOffsetScale,
                                                  withMaxYScale: yMaxOffsetScale,
                                                  withXSpan: XSpan, withYSpan: YSpan)
        try await renderingListener?.extentsHaveRefreshed()
        return true
    }
    
    func updateWith(newExtent: Extent) async throws {
        pastExtents.append(currentExtent)
        currentExtent = newExtent
        try await renderingListener?.extentsHaveRefreshed()
    }
    
    func assemble() async -> Data {
        assert(false, "This method must implement in a subclass and not called directly.")
        return Data()
    }
    
    func coallesceData() {
        for index in stride(from: 0, to: Int(bufferSize.width*4), by: 4) {
            for dataBlock in wideBuffer! {
//                assert(dataBlock.count >= index + 4, "subdata beyond bounds")
                pixelData.append(dataBlock.subdata(in: index..<index+4))
            }
        }
    }
    
    func writeToBuffer(col:Int, colorIndex:Int) {
        let rawData = [colorSchemeColor[colorIndex*4], colorSchemeColor[colorIndex*4+1], colorSchemeColor[colorIndex*4+2], colorSchemeColor[colorIndex*4+3]]
        wideBuffer?[col].append(contentsOf: rawData)
       
//        let color = colorSchemeColor[colorIndex].littleEndian
//        let rawData = withUnsafeBytes(of:color) { Data($0) }
//        rawData.reverse() // Byte order is reveresed when defined
//        wideBuffer?[col].append(contentsOf: [UInt8(color>>24&0xFF),  UInt8((color>>16)&0xFF), UInt8((color>>8)&0xFF), UInt8((color)&0xFF)])
    }
    
    func loadPreviousExtent() -> Bool {
        guard pastExtents.count > 0 else {
            return false
        }
        
        currentExtent = pastExtents.removeLast()
        return true
    }
    
    func goBack() -> Bool {
        if rendering == true {
            return false
        }
        return loadPreviousExtent()
    }
    
    func reset() -> Bool{
        if  rendering == true || loadPreviousExtent() == false {
            return false
        }
        configureDefaultExtents()
        pastExtents.removeAll()
        return true
    }
    
    func release() {
        wideBuffer?.removeAll()
        pixelData.removeAll()
    }
    
    func hasZoomed() -> Bool {
        return zoomed
    }
    
    func snapshotWithSourceImage(_ image:UIImage) -> SnapshotObject {
        return Snapshot(thumbnail: .init(image), model: model.rawValue, palette: colorPalette, extents: currentExtent)
    }
}
