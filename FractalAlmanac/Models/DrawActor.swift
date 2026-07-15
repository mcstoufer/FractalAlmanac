//
//  DrawActor.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/15/26.
//

import UIKit

actor DrawActor {
    func draw(width:Int,height:Int, dataModel:FractalDataModel) async -> UIImage?
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
        if let filteredImage = await cgImage?.applyFilter(filter: dataModel.colorPalette.colorSchemeFilter()) {
            return UIImage(cgImage: filteredImage)
        } else {
            return nil
        }
    }
}
