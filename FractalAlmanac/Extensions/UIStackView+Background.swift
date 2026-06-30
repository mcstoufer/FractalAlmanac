//
//  UIStackView+Background.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import UIKit

extension UIStackView {
    
    func addBackground(color: UIColor) {
        let subview = UIView(frame: bounds)
        subview.backgroundColor = color
        subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        subview.layer.cornerRadius = 8.0
        subview.layer.masksToBounds = true;
        insertSubview(subview, at: 0)
    }
}
