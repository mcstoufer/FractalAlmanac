//
//  ShaderUtilities.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/23/26.
//

#include <metal_stdlib>
using namespace metal;

inline uint32_t scaled_iterations(uint32_t baseIterations, float4 scaleSplit, float2 size) {
    float currentScaleWidth = scaleSplit.x * size.x;
    float zoomDepth = log10(1.0f / max(currentScaleWidth, 1e-7f));
    float scalingFactor = 250.0f;
    return static_cast<uint32_t>(clamp(baseIterations + (scalingFactor * zoomDepth), 100.0f, 10000.0f));
}

inline half4 color_lookup(constant float *colors, int i,
                          float maxIterations, int totalColors,
                          int colorsCount, float cycle) {
    if (i == maxIterations) return half4(0.0,0.0,0.0,1.0); // black
    
    int colorIndex = 0;
    if (cycle == 0) {
        colorIndex = (i * totalColors / maxIterations);
    } else if (cycle == 1) {
        colorIndex = i % totalColors;
    }
    
    int byteOffset = colorIndex * 4;
    if (byteOffset >= colorsCount - 3) {
        byteOffset = colorsCount - 4;
    }
    return half4(colors[byteOffset], colors[byteOffset+1], colors[byteOffset+2], 1.0);
}
