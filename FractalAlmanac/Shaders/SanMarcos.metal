//
//  SanMarcos.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/27/26.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
#include "Helpers/DualFloatShaderUtilities.metal"
#include "Helpers/Float2ShaderUtilities.metal"

using namespace metal;

// Helper function to reconstruct an emulated double from high and low float components
inline float floatFromSplit(float2 split) {
    return split.x + split.y;
}

[[ stitchable ]] half4 sanmarcos(float2 position,
                                 SwiftUI::Layer layer,
                              float2 centerRealSplit,   // centerReal.hi, centerReal.lo
                              float2 centerImagSplit,   // centerImag.hi, centerImag.lo
                              float4 scaleSplit,        // dx.hi, dx.lo, dy.hi, dy.lo (Precalculated pixel step size)
                              float2 cConstantSplit,    // cConstantReal.hi, cConstantReal.lo, cConstantImag.hi, cConstantImag.lo
                              float2 size,
                              float tuningData,
                              float cycle,
                              constant const float *colors,
                                 int colorsCount) {
    // Extract emulated double constants from your split float structures
    float2 P  = { cConstantSplit.x, 0.0f };
    float2 Q  = { cConstantSplit.y, 0.0f };
    
    int maxIters = int(tuningData);
    
    // Core Image coordinate setup: calculate pixel offset from the viewport center
    float2 pixelOffset = position - size * 0.5f;
    
    // Map current coordinate using emulated high-precision delta scales
    // X = centerReal + (offset.x * dx)
    float2 X = f2_add(centerRealSplit.xy, f2_mul(float2(pixelOffset.x, 0.0f), scaleSplit.xy));
    // Core Image matches UIKit coordinate spaces (Y is flipped relative to raw Metal)
    // Y = centerImag + (offset.y * dy)
    float2 Y = f2_add(centerImagSplit.xy, f2_mul(float2(pixelOffset.y, 0.0f), scaleSplit.zw));
    
    bool isInitiallyPositiveY = (Y.x > 0.0f);
    
    float2 XSquare = float2(0.0f, 0.0f);
    float2 YSquare = float2(0.0f, 0.0f);
    int colorIndex = 0;
    
    // Core high-precision fractal computation loop
    while (colorIndex < maxIters && (XSquare.x + YSquare.x) < 4.0f) {
        XSquare = f2_mul(X, X);
        YSquare = f2_mul(Y, Y);
        
        float2 temp_sq = f2_sub(YSquare, XSquare);
        float2 temp_xy = f2_mul(float2(2.0f, 0.0f), f2_mul(X, Y));
        
        // YTemp = (Q * (temp_sq + X)) - (P * (temp_xy - Y))
        float2 termY1 = f2_mul(Q, f2_add(temp_sq, X));
        float2 termY2 = f2_mul(P, f2_sub(temp_xy, Y));
        float2 YTemp  = f2_sub(termY1, termY2);
        
        // X = (P * (temp_sq + X)) + (Q * (temp_xy - Y))
        float2 termX1 = f2_mul(P, f2_add(temp_sq, X));
        float2 termX2 = f2_mul(Q, f2_sub(temp_xy, Y));
        X = f2_add(termX1, termX2);
        
        Y = YTemp;
        colorIndex++;
    }
    
    // Dynamic palette colors count calculation (Assuming RGBA float buffer -> 4 elements per palette color)
    int paletteCount = colorsCount / 4;
    
    if (colorIndex >= maxIters) {
        float magnitude = abs(XSquare.x + YSquare.x);
        int magnitudeSq = int(magnitude * 100.0f);
        colorIndex = (magnitudeSq % (paletteCount - 1)) + 1;
    } else {
        colorIndex = paletteCount - 1;
    }
    
    // Mirroring/shifting index modification for upper layout half
    if (isInitiallyPositiveY) {
        int shift = int(cycle) + (paletteCount / 2);
        colorIndex = (colorIndex + shift) % paletteCount;
    }
    
    // Protect color index constraints before palette evaluation
    colorIndex = clamp(colorIndex, 0, paletteCount - 1);
    return smoothable_color_lookup(colors, colorIndex,
                        df_float{0.0, 0.0}, df_float{0.0, 0.0},
                        maxIters, paletteCount, colorsCount, cycle);
}
