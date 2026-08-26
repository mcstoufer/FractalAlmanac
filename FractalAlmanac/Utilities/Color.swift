//
//  Color.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 6/29/26.
//

import UIKit
import SwiftUI


enum PaletteColor: UInt32, CaseIterable, Identifiable, Hashable, NumericColorProtocol { // All 4 bytes long with full opacity
    var id: Self { self }
    
    // R G B A
    case white   = 4294967295 // 0xFFFFFFFF
    case magenta = 4278255615
    case fuscia  = 4278223103
    case red     = 4278190335   // 0xFF0000FF
    case yellow  = 4294902015
    case orange  = 4291559679
    case pink    = 4290825215
    case vibrantOrange = 4285858047
    case brightOrange  = 4234232063
    case palePink      = 4192131071
    case saffron       = 4189991679
    case liteGoldenrod = 4176991743
    case softYellow    = 4159723519
    case classicRose   = 4123909887
    case dullOrange    = 4069731839
    case violet        = 4001558271
    case greenLighten5 = 3908430335
    case vividOrange   = 3898612991
    case lightGreyCyan = 3823626239
    case mauve         = 3804164607
    case goldenrod     = 3751618559
    case veryLiteGrey  = 3722305023
    case vividRed      = 3674606591
    case lightGreyBlue = 3537364991
    case palePurple    = 3535525887
    case greyCyan      = 3521109759
    case ochre         = 3514902015
    case darkOrange    = 3479574015
    case azureishWhite = 3437359871
    case softGreen     = 3403787519
    case greenLighten4 = 3370568191
    case aeroBlue      = 3338200575
    case tangerine     = 3226341631
    case mahogany      = 3225420031
    case greenAccent1  = 3119958783
    case hcRed         = 3037069567
    case burntOrange   = 2973175039
    case greyBlue      = 2948383231
    case firebrick     = 2938643967
    case dullPink      = 2926945023
    case greenLighten3 = 2782308351
    case rust          = 2720008447
    case brown         = 2521497855
    case bloodRed      = 2466776063
    case desatLime     = 2429060863
    case vermillion    = 2284679679
    case greenLighten2 = 2177336575
    case lime          = 2164195583
    case purple        = 2147516671
    case verySoftBlue  = 2075189247
    case darkRed       = 1897467391
    case greenAccent2  = 1777381119
    case greenLighten1 = 1723558655
    case moderateBlue  = 1368049407
    case darkModLime   = 1303536895
    case greenDarken1  = 1134577663
    case greenDarken2  = 948845823
    case greenDarken3  = 779956991
    case errieBlack    = 538515455
    case greenDarken4  = 459153663
    case strongCyan    = 426029311
    case cyan          = 16777215
    case leaf          = 16744703
    case green         = 16711935
    case greenAccent3  = 15103743
    case greenAccent4  = 13128703
    case navy          = 8454143
    case hcGreen       = 6703103
    case hcBlue        = 6196479
    case blue          = 65535 // 0x0000FFFF
    case black         = 255   // 0x000000FF
    case clear         = 0     // 0x00000000
    
    static func allColorsSorted() -> [PaletteColor] {
        return  PaletteColor.allCases.sorted(by: { $0.rawValue.hue < $1.rawValue.hue} )
    }
    
    static func random<G: RandomNumberGenerator>(using generator: inout G) -> PaletteColor {
        let color = PaletteColor.allCases.randomElement(using: &generator)!
        if color == .clear {
            return PaletteColor.random(using: &generator)
        }
        return color
    }
    
    static func random() -> PaletteColor {
        var g = SystemRandomNumberGenerator()
        return PaletteColor.random(using: &g)
    }
    
    var uiColor: UIColor {
        return rawValue.uiColor
    }
    
    var systemColor: Color {
        return rawValue.systemColor
    }
    
    var naturalDescription: String {
        return String(describing: self).replacingOccurrences(of: "([A-Z])", with: " $1", options: [.regularExpression]).capitalized
    }
}
