//
//  UserDefaults+Model.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import Foundation

let kLastSelectedModel = "lastSelectedModel"
let kLastSelectedPalette = "lastSelectedPalette"
let kFirstLaunch = "has_launch_before"
extension UserDefaults {
    
    var hasLaunchedBefore: Bool {
        get {
            return self.bool(forKey: kFirstLaunch)
        }
        set {
            self.set(newValue, forKey: kFirstLaunch)
        }
    }
    
    var lastSelectedModel: FractalModelFactory {
        get {
            guard let f = UserDefaults.standard.string(forKey: kLastSelectedModel) else {
                return .Mandelbrot
            }
            guard let pr = FractalModelFactory(rawValue: f) else {
                return .Mandelbrot
            }
            return pr
        }
        set(newModel) {
            UserDefaults.standard.set(newModel.rawValue, forKey: kLastSelectedModel)
        }
    }

    var lastSelectedPalette: ColorSchemeProtocol {
        get {
            guard let p = UserDefaults.standard.string(forKey: kLastSelectedPalette) else {
                return Palette(rawValue:"Vibrant")!
            }
            guard let pr = Palette(rawValue: p) else {
                return Palette(rawValue:"Vibrant")!
            }
            return pr
        }
        set(newPalette) {
            UserDefaults.standard.set(newPalette.colorSchemeName(), forKey: kLastSelectedPalette)
        }
    }
}
