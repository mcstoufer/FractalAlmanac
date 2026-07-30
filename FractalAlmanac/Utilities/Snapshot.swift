//
//  Snapshot.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import UIKit

@propertyWrapper
struct ScaledThumbnail {
    private var thumbnail: UIImage
    init(_ image:UIImage) { self.thumbnail = image }
    var wrappedValue: UIImage {
        get { return thumbnail }
        set { if let scaledImage = newValue.cgImage?.scaledImage(scale: 0.125) {
            thumbnail = UIImage(cgImage: scaledImage)
        }}
    }
}

