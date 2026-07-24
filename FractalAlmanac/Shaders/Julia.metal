//
//  Julia.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/23/26.
//

#include <metal_stdlib>
#include "ShaderUtilities.metal"

using namespace metal;


[[ stitchable ]] half4 julia(float2 position,
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
    uint32_t maxIterations = static_cast<uint32_t>(tuningData.x);
    
    float offsetX = position.x - (size.x * 0.5f);
    float offsetY = position.y - (size.y * 0.5f);
    
    df_float c_real_center = { centerRealSplit.x, centerRealSplit.y };
    df_float c_imag_center = { centerImagSplit.x, centerImagSplit.y };
    
    df_float dx = { scaleSplit.x, scaleSplit.y };
    df_float dy = { scaleSplit.z, scaleSplit.w };
    
    df_float offset_x_df = { offsetX, 0.0f };
    df_float offset_y_df = { offsetY, 0.0f };
    
    // In Julia Set, the pixel positions determine the starting Z values (zx, zy)
    df_float zx = df_add(c_real_center, df_mul(offset_x_df, dx));
    df_float zy = df_add(c_imag_center, df_mul(offset_y_df, dy));
    
    // The constant C is passed uniformly and stays fixed for all pixels
    df_float cx = { cConstantSplit.x, cConstantSplit.y };
    df_float cy = { cConstantSplit.z, cConstantSplit.w };
    
    uint32_t i = 0;
    
    for (; i < maxIterations; i++) {
        df_float zx2 = df_mul(zx, zx);
        df_float zy2 = df_mul(zy, zy);
        
        if ((zx2.hi + zy2.hi) >= 4.0f) {
            break;
        }
        
        df_float two_zx = df_add(zx, zx);
        zy = df_add(df_mul(two_zx, zy), cy);
        
        df_float neg_zy2 = { -zy2.hi, -zy2.lo };
        zx = df_add(df_add(zx2, neg_zy2), cx);
    }
    if (i == maxIterations) return half4(0.0,0.0,0.0,1.0); // black
    
    int colorIndex = 0;
    if (cycle == 1) {
        colorIndex = i % totalColors;
    } else {
        colorIndex = (i * totalColors / maxIterations);
    }
    
    int byteOffset = colorIndex * 4;
    if (byteOffset >= colorsCount - 3) {
        byteOffset = colorsCount - 4;
    }
    
    return half4(colors[byteOffset], colors[byteOffset+1], colors[byteOffset+2], 1.0);
}
