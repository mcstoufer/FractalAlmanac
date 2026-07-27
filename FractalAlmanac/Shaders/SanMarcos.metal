//
//  SanMarcos.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/27/26.
//

#include <metal_stdlib>
#include "ShaderUtilities.metal"

using namespace metal;

inline float2 quickTwoSum(float a, float b) {
    float s = a + b;
    float v = s - a;
    float e = (a - (s - v)) + (b - v);
    return float2(s, e);
}

[[ stitchable ]] half4 sanmarcos(float2 position,
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
    // Extract iteration limit from parameters
    int maxIterations = int(tuningData.x);
    
    // 1. Calculate relative screen offset from center pixel (size * 0.5)
    float2 deltaPixels = position - (size * 0.5);
    
    // 2. Compute high-precision Initial Z coordinate using Split-Precision math
    // Z_real = centerReal + deltaPixels.x * scale_dx
    float dx_prod_hi = deltaPixels.x * scaleSplit.x;
    float dx_prod_lo = deltaPixels.x * scaleSplit.y;
    float2 zr_split  = quickTwoSum(centerRealSplit.x, dx_prod_hi);
    float z_real     = zr_split.x + (zr_split.y + centerRealSplit.y + dx_prod_lo);
    
    // Z_imag = centerImag + deltaPixels.y * scale_dy
    float dy_prod_hi = deltaPixels.y * scaleSplit.z;
    float dy_prod_lo = deltaPixels.y * scaleSplit.w;
    float2 zi_split  = quickTwoSum(centerImagSplit.x, dy_prod_hi);
    float z_imag     = zi_split.x + (zi_split.y + centerImagSplit.y + dy_prod_lo);
    
    // 3. Extract the locked San Marcos constant components
    float c_real = cConstantSplit.x + cConstantSplit.y;
    float c_imag = cConstantSplit.z + cConstantSplit.w;
    
    // 4. Run the Core Fractal Escape Loop
    int iteration = 0;
    float zr2 = z_real * z_real;
    float zi2 = z_imag * z_imag;
    
    while (iteration < maxIterations && (zr2 + zi2) < 4.0) {
        float next_real = zr2 - zi2 + c_real;
        z_imag = 2.0 * z_real * z_imag + c_imag;
        z_real = next_real;
        
        zr2 = z_real * z_real;
        zi2 = z_imag * z_imag;
        iteration++;
    }
    
    // 5. If it stays inside the set, return background/inner color
    if (iteration == maxIterations) {
        return half4(0.0h, 0.0h, 0.0h, 1.0h);
    }
    
    // 6. Calculate Smooth / Continuous Iteration Count
    // Formula: nu = log(log(modulus) / log(2)) / log(2)
    float log_zn = log(zr2 + zi2) / 2.0;
    float nu = log(log_zn / log(2.0)) / log(2.0);
    
    // Smooth iteration value can fall slightly between discrete steps
    float smooth_iteration = float(iteration) + 1.0 - nu;
    
    // Prevent negative bounds or overflows out of the iteration space
    smooth_iteration = max(0.0, smooth_iteration);
    
    // 7. Map smooth iteration count to the 1D Color Buffer array
    // Normalize step using cycle offset parameter
    float norm_t = smooth_iteration / float(maxIterations);
    float mapped_index = fract(norm_t + cycle) * float(colorsCount - 1);
    
    int idx0 = int(floor(mapped_index));
    int idx1 = min(idx0 + 1, colorsCount - 1);
    float interpolation_factor = fract(mapped_index);
    
    // Fetch elements assuming 1D float array stores packed RGB sequences [R0,G0,B0,R1,G1,B1...]
    int base0 = idx0 * 3;
    int base1 = idx1 * 3;
    
    half3 color0 = half3(colors[base0], colors[base0 + 1], colors[base0 + 2]);
    half3 color1 = half3(colors[base1], colors[base1 + 1], colors[base1 + 2]);
    half3 final_rgb = mix(color0, color1, half(interpolation_factor));
    
    return half4(final_rgb, 1.0h);
}
