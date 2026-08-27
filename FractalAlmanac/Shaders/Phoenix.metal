//
//  Phoenix.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/26/26.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
#include "Helpers/DualFloatShaderUtilities.metal"

using namespace metal;


[[ stitchable ]] half4 phoenix(float2 position,
                               SwiftUI::Layer layer,
                               float2 centerRealSplit,   // centerReal.hi, centerReal.lo
                               float2 centerImagSplit,   // centerImag.hi, centerImag.lo
                               float4 scaleSplit,        // dx.hi, dx.lo, dy.hi, dy.lo (Precalculated pixel step size)
                               float2 cConstantSplit,    // c.hi, c.lo (Phoenix C constant), p.hi, p.lo (Phoenix P parameter)
                               float2 size,
                               float tuningData,
                               float cycle,
                               constant const float *colors,
                               int colorsCount) {
    int totalColors = colorsCount / 4;
    uint32_t maxIterations = static_cast<uint32_t>(tuningData);
    
    float offsetX = position.x - (size.x * 0.5f);
    float offsetY = position.y - (size.y * 0.5f);
    
    df_float c_real_center = { centerRealSplit.x, centerRealSplit.y };
    df_float c_imag_center = { centerImagSplit.x, centerImagSplit.y };
    
    df_float dx = { scaleSplit.x, scaleSplit.y };
    df_float dy = { scaleSplit.z, scaleSplit.w };
    
    df_float offset_x_df = { offsetX, 0.0f };
    df_float offset_y_df = { offsetY, 0.0f };
    
    // For Phoenix mapped as a Julia-style variant, pixel coordinates map to initial Z_0
    df_float zx = df_add(c_real_center, df_mul(offset_x_df, dx));
    df_float zy = df_add(c_imag_center, df_mul(offset_y_df, dy));
    
    // Extract Phoenix formula constants from cConstantSplit
    df_float cx = { cConstantSplit.x, 0.0f }; // Phoenix Real Constant (C)
    df_float cy = { cConstantSplit.y, 0.0f }; // Phoenix Feedback Parameter (P)
    
    // Z_(n-1) track variables initialized to 0
    df_float zx_prev = { 0.0f, 0.0f };
    df_float zy_prev = { 0.0f, 0.0f };
    
    uint32_t i = 0;
    float escapeRadiusSq = 65536.0f;

    for (; i < maxIterations; i++) {
        df_float zx2 = df_mul(zx, zx);
        df_float zy2 = df_mul(zy, zy);
        
        if ((zx2.hi + zy2.hi) >= escapeRadiusSq) {
            break;
        }
        
        // Save current Z_n before overwriting it, to become Z_(n-1) in the next loop
        df_float next_zx_prev = zx;
        df_float next_zy_prev = zy;
        
        // Compute standard Julia/Mandelbrot expansion: Z_n^2 + C
        df_float standard_real = df_add(df_sub(zx2, zy2), cx);
        df_float standard_imag = df_add(df_mul({2.0f, 0.0f}, df_mul(zx, zy)), {0.0f, 0.0f}); // cy handled via feedback loop below
        
        // Compute Phoenix feedback loop: P * Z_(n-1)
        // Note: For standard Phoenix, P is usually real-only (e.g., P = -0.5)
        df_float feedback_real = df_mul(cy, zx_prev);
        df_float feedback_imag = df_mul(cy, zy_prev);
        
        // Complete the Phoenix equation: Z_(n+1) = Z_n^2 + C + (P * Z_(n-1))
        zx = df_add(standard_real, feedback_real);
        zy = df_add(standard_imag, feedback_imag);
        
        // Commit history shift
        zx_prev = next_zx_prev;
        zy_prev = next_zy_prev;
        }
    
    return smoothable_color_lookup(colors, i, zx, zy, maxIterations, totalColors, colorsCount, cycle);
}
