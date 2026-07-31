//
//  Dragon.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/27/26.
//

#include <metal_stdlib>
#include "ShaderUtilities.metal"

using namespace metal;

[[ stitchable ]] half4 dragon(float2 position,
                             half4 currentColor,
                             float4 centerRealSplit,   // centerReal.hi, centerReal.lo
                             float4 centerImagSplit,   // centerImag.hi, centerImag.lo
                             float4 scaleSplit,        // dx.hi, dx.lo, dy.hi, dy.lo (Precalculated pixel step size)
                             float4 cConstantSplit,    // cConstantReal.hi, cConstantReal.lo, cConstantImag.hi, cConstantImag.lo
                             float2 size,
                             float2 tuningData,
                             float cycle,
                             device const float *colors,
                             int colorsCount) {
    int totalColors = colorsCount / 4;
    uint32_t baseIterations = static_cast<uint32_t>(tuningData.x);
    uint32_t maxIterations = scaled_iterations(baseIterations, scaleSplit, size);
    
    float offsetX = position.x - (size.x * 0.5f);
    float offsetY = position.y - (size.y * 0.5f);
    
    df_float c_real_center = { centerRealSplit.x, centerRealSplit.y };
    df_float c_imag_center = { centerImagSplit.x, centerImagSplit.y };
    
    df_float dx = { scaleSplit.x, scaleSplit.y };
    df_float dy = { scaleSplit.z, scaleSplit.w };
    
    df_float offset_x_df = { offsetX, 0.0f };
    df_float offset_y_df = { offsetY, 0.0f };
    
    // For a Dragon (Julia) set, pixel positions map to the starting variables Z_0
    df_float zx = df_add(c_real_center, df_mul(offset_x_df, dx));
    df_float zy = df_add(c_imag_center, df_mul(offset_y_df, dy));
    
    // The C constant is fixed across all pixels to define the specific Dragon variant
    df_float cx = { cConstantSplit.x, cConstantSplit.y };
    df_float cy = { cConstantSplit.z, cConstantSplit.w };
    
    uint32_t i = 0;
    float escapeRadiusSq = 65536.0f;

    for (; i < maxIterations; i++) {
        df_float zx2 = df_mul(zx, zx);
        df_float zy2 = df_mul(zy, zy);
        
        // Escape condition check using high-precision components
        if ((zx2.hi + zy2.hi) >= escapeRadiusSq) {
            break;
        }
        
        // Compute standard complex squaring + constant mapping: Z_{n+1} = Z_n^2 + C
        // Real part: zx^2 - zy^2 + cx
        df_float real_next = df_add(df_sub(zx2, zy2), cx);
        
        // Imaginary part: 2 * zx * zy + cy
        df_float two_zx = df_add(zx, zx);
        df_float imag_next = df_add(df_mul(two_zx, zy), cy);
        
        // Update states
        zx = real_next;
        zy = imag_next;
    }
//    float smoothIteration = smoother(i, maxIterations, zx, zy);
    return color_lookup(colors, i, maxIterations, totalColors, colorsCount, cycle);
}
