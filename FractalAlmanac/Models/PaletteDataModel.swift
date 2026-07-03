//
//  PaletteDataModel.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import SwiftUI

enum Palette:String, CaseIterable, ColorSchemeProtocol, Identifiable {
    var id: Self { self }
    
    case Vibrant = "Vibrant"
    case Verdant = "Verdant"
    case Fire = "Fire"
    case Rainbow = "Rainbow"
    case Random = "Roll the dice..."
    case Smooth = "Smooth Jazz"
    case Psychedlic = "Psych out!"
    case Aesthetic = "Forgotten Dream"
    case Pastel = "Unicorn Bath Bomb"
    case Heaven = "Pearly Gates"
    case HighContrast = "High Contrast"
}

enum PaletteStyle: String, CaseIterable {
    case Classic = "Classic"
    case Enhanced = "Enhanced"
    case Custom = "Custom"
}

extension Palette {

    var paletteName: String {
        return rawValue
    }
    
    func schemeColors() -> [UInt32] {
        return colorScheme()
    }
    
    func schemeSystemColors() -> [Color] {
        return colorScheme().map { color in
            color.systemColor
        }
    }
    
    func colorSchemeFilter() -> RenderingFilter {
        return .Off
    }
    
    static func classicPalettes() -> [Palette] {
        return [.Vibrant, .Verdant, .Fire, .Rainbow, .Random, .HighContrast, .Aesthetic, .Pastel]
    }
    
    static func enhancedPalettes() -> [Palette] {
        return [.Heaven, .Smooth, .Psychedlic]
    }
    
    func colorScheme() -> [UInt32] {
        var pallete = [UInt32]()
        var colors  = [PaletteColor]()
        switch self {
            case .Vibrant:
                colors = [.white, .magenta, .fuscia, .red,
                          .yellow, .orange, .pink, .violet,
                          .lime, .purple, .cyan, .leaf,
                          .green, .navy, .blue, .black]
            case .Verdant:
                colors = [.white, .greenLighten5, .greenLighten4, .greenLighten3,
                          .greenLighten2, .greenLighten1, .green, .greenDarken1,
                          .greenDarken2, .greenDarken3, .greenDarken4, .greenAccent1,
                          .greenAccent2, .greenAccent3, .greenAccent4, .black]
            case .Fire:
                colors = [.white, .saffron, .goldenrod, .yellow,
                          .mahogany, .vibrantOrange, .ochre, .darkOrange,
                          .tangerine, .burntOrange, .red, .rust,
                          .firebrick, .bloodRed, .errieBlack, .black]
            case .Rainbow:
                colors = [.palePurple, .dullPink, .blueGreen, .strongCyan,
                          .moderateBlue, .verySoftBlue, .darkModLime, .desatLime,
                          .softGreen, .softYellow, .brightOrange, .dullOrange,
                          .vividOrange, .vividRed, .darkRed, .black]
                
            case .Aesthetic:
                colors = [.lightGreyBlue, .lightGreyCyan, .greyCyan, .veryLiteGrey, .black]
                
            case .Random:
                for _ in 0..<15 {
                    colors.append(PaletteColor.random())
                }
                colors.append(.black)
                
            case .HighContrast:
                colors = [.white, .hcRed, .hcBlue, .hcGreen,
                          .errieBlack, .white, .hcRed, .hcBlue,
                          .hcGreen, .errieBlack, .white, .hcRed,
                          .hcBlue, .hcGreen, .errieBlack, .black]
                
            case .Pastel:
                colors = [.azureishWhite, .aeroBlue, .liteGoldenrod, .palePink, .classicRose, .mauve]
                
            case .Heaven:
                pallete = Palette.Pastel.interpolatedColorScheme(steps: 64)
                
            case .Smooth:
                pallete = Palette.Fire.interpolatedColorScheme(steps: 64)
                
            case .Psychedlic:
                pallete = Palette.Rainbow.interpolatedColorScheme(steps: 64)
        }
        
        if colors.count > 0 {
            pallete = colors.map { $0.rawValue }
        }
        return pallete
    }
    
    func interpolatedColorScheme(steps:Int) -> [UInt32] {
        return colorScheme().interpolateColorScheme(steps: steps)
    }
}
