//
//  PaletteDataModel.swift
//  FractalAlmanac
//
//  Created by Dragon Admin on 6/29/26.
//

import SwiftUI

enum Palette:String, CaseIterable {
    var id: UUID {
        UUID()
    }
    
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

extension Palette: ColorSchemeProtocol {
    var stableID: String {
        self.id.uuidString
    }
    
    var paletteName: String {
        return rawValue
    }
    
    var paletteShaderColors: [Float] {
        return self.colorScheme().map { $0.shaderColor}.flatMap{ $0 }
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
}

extension Palette {
    static func classicPalettes() -> [Palette] {
        return [.Vibrant, .Verdant, .Fire, .Rainbow, .Random, .HighContrast, .Aesthetic, .Pastel]
    }
    
    static func enhancedPalettes() -> [Palette] {
        return [.Heaven, .Smooth, .Psychedlic]
    }
    
    func colorScheme() -> [UInt32] {
        var colors  = [PaletteColor]()
        switch self {
            case .Vibrant:
                colors = [.white, .magenta, .fuscia, .red,
                          .yellow, .orange, .pink, .violet,
                          .lime, .purple, .cyan, .leaf,
                          .green, .navy, .blue]
            case .Verdant:
                colors = [.white, .greenLighten5, .greenLighten4, .greenLighten3,
                          .greenLighten2, .greenLighten1, .green, .greenDarken1,
                          .greenDarken2, .greenDarken3, .greenDarken4, .greenAccent1,
                          .greenAccent2, .greenAccent3, .greenAccent4]
            case .Fire:
                colors = [.white, .saffron, .goldenrod, .yellow,
                          .mahogany, .vibrantOrange, .ochre, .darkOrange,
                          .tangerine, .burntOrange, .red, .rust,
                          .firebrick, .bloodRed, .errieBlack]
            case .Rainbow:
                colors = [.palePurple, .dullPink, .vermillion, .strongCyan,
                          .moderateBlue, .verySoftBlue, .darkModLime, .desatLime,
                          .softGreen, .softYellow, .brightOrange, .dullOrange,
                          .vividOrange, .vividRed, .darkRed]
                
            case .Aesthetic:
                colors = [.lightGreyBlue, .lightGreyCyan, .greyCyan, .veryLiteGrey]
                
            case .Random:
                colors = (0..<15).map { _ in PaletteColor.random() }.appending(.black)
                
            case .HighContrast:
                colors = [.white, .hcRed, .hcBlue, .hcGreen,
                          .errieBlack, .white, .hcRed, .hcBlue,
                          .hcGreen, .errieBlack, .white, .hcRed,
                          .hcBlue, .hcGreen, .errieBlack]
                
            case .Pastel:
                colors = [.azureishWhite, .aeroBlue, .liteGoldenrod, .palePink, .classicRose, .mauve]
                
            case .Heaven:
                return  Palette.Pastel.interpolatedColorScheme(steps: 64)
                
            case .Smooth:
                return Palette.Fire.interpolatedColorScheme(steps: 64)
                
            case .Psychedlic:
                return Palette.Rainbow.interpolatedColorScheme(steps: 64)
        }
        
        return colors.appending(.black).asNumeric
    }
    
    func interpolatedColorScheme(steps:Int) -> [UInt32] {
        return colorScheme().interpolateColorScheme(steps: steps)
    }
}
