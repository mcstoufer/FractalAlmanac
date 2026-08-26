//
//  UserDefaults+Model.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 6/29/26.
//

import Foundation

let kLastSelectedModel = "lastSelectedModel"
let kLastSelectedPalette = "lastSelectedPalette"
let kFirstLaunch = "has_launch_before"
let kLastPaletteCycle = "lastPaletteCycle"

extension UserDefaults {
    
    var hasLaunchedBefore: Bool {
        get {
            return self.bool(forKey: kFirstLaunch)
        }
        set {
            self.set(newValue, forKey: kFirstLaunch)
        }
    }
    
    var lastSelectedModel: FractalModel {
        get {
            guard let f = UserDefaults.standard.string(forKey: kLastSelectedModel) else {
                return .JuliaA
            }
            guard let pr = FractalModel(rawValue: f) else {
                return .JuliaA
            }
            return pr
        }
        set(newModel) {
            UserDefaults.standard.set(newModel.rawValue, forKey: kLastSelectedModel)
        }
    }

    var lastSelectedPalette: any ColorSchemeProtocol {
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
            UserDefaults.standard.set(newPalette.paletteName, forKey: kLastSelectedPalette)
        }
    }
    
    var lastPaletteCycle: PaletteCycleStyle {
        get {
            let p = UserDefaults.standard.integer(forKey: kLastPaletteCycle)
            return PaletteCycleStyle(rawValue: p)!
        }
        set(newCycle) {
            UserDefaults.standard.set(newCycle.rawValue, forKey: kLastPaletteCycle)
        }
    }
}
