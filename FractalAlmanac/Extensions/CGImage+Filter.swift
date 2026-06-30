//
//  CGImage+Filter.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import CoreGraphics
import CoreImage


extension CGImage {
    func applyFilter(filter:RenderingFilter) -> CGImage? {
        switch filter {
            case .Glow:
                return self.bloomedImage(radius: 3.45, intensity: 1.125)
            case .Blur:
                return self.blurredImage(radius: 0.45)
            default:
                return self
        }
    }
    
    func blurredImage(radius: CGFloat) -> CGImage? {
        let ciImage = CIImage(cgImage: self)
        let coreImageContext = CIContext()
        let blurredImage = ciImage
            .clampedToExtent()
            .applyingFilter(
                "CIGaussianBlur",
                parameters: [
                    kCIInputRadiusKey: radius,
                ]
            )
            .cropped(to: ciImage.extent)
        
        return coreImageContext.createCGImage(blurredImage, from: blurredImage.extent)
    }
    
    func bloomedImage(radius: CGFloat, intensity: CGFloat) -> CGImage? {
        let ciImage = CIImage(cgImage: self)
        let coreImageContext = CIContext()
        let bloomedImage = ciImage
            .clampedToExtent()
            .applyingFilter(
                "CIBloom",
                parameters: [
                    kCIInputRadiusKey: radius,
                    kCIInputIntensityKey: intensity
                ]
            )
            .cropped(to: ciImage.extent)
        
        return coreImageContext.createCGImage(bloomedImage, from: bloomedImage.extent)
    }
    
    func scaledImage(scale:CGFloat) -> CGImage? {
        let ciImage = CIImage(cgImage: self)
        let coreImageContext = CIContext()
        let scaledImage = ciImage
            .applyingFilter(
                "CILanczosScaleTransform",
                parameters: [
                    kCIInputScaleKey: scale,
                    kCIInputAspectRatioKey: NSNumber(value: 1)
                ]
            )
        
        return coreImageContext.createCGImage(scaledImage, from: scaledImage.extent)
    }
}
