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
