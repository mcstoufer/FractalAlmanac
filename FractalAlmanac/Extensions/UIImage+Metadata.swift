//
//  UIImage+Metadata.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 8/19/26.
//

import UIKit
import Photos
import ImageIO

extension UIImage {
    
    func saveImageWithMetadata(
        caption: String,
        cameraModel: String,
        lensInfo: String,
        onComplete: ((Error?) -> Void)? = nil
    ) {
        guard let data = self.jpegData(compressionQuality: 0.9) else { return }
        
        // Create temporary file URL
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        
        // Build metadata dictionary
        let tiffDict: [String: Any] = [kCGImagePropertyTIFFModel as String: cameraModel]
        let exifDict: [String: Any] = [kCGImagePropertyExifLensModel as String: lensInfo]
        let iptcDict: [String: Any] = [kCGImagePropertyIPTCCaptionAbstract as String: caption]
        
        let metadata: [String: Any] = [
            kCGImagePropertyTIFFDictionary as String: tiffDict,
            kCGImagePropertyExifDictionary as String: exifDict,
            kCGImagePropertyIPTCDictionary as String: iptcDict
        ]
        
        // Write metadata to file destination
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let destination = CGImageDestinationCreateWithURL(tempURL as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else { return }
        
        CGImageDestinationAddImageFromSource(destination, source, 0, metadata as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return }
        
        // Save to Photo Library using PhotoKit
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: .photo, fileURL: tempURL, options: nil)
        }) { success, error in
            
            try? FileManager.default.removeItem(at: tempURL)
            
            DispatchQueue.main.async {
                onComplete?(error)
            }
        }
    }
}
