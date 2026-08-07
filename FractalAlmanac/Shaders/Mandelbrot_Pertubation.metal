//
//  Mandelbrot_Pertubation.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 8/5/26.
//

#include <metal_stdlib>
#include "DualFloatShaderUtilities.metal"

using namespace metal;


[[ stitchable ]] half4 mandelbrot_pertubation(float2 position,              // Auto injected by Shader init
                                              half4 currentColor,           // Auto injected by Shader init
                                              float2 size,                  // Size
                                              float scale,                  // Current Scale
                                              float2 activeCenter,          // Current Center
                                              float2 stableOrbitCenter,          // Frozen anchor point used for CPU orbit (c_ref)
                                              float cycle,                  // Palette Cycle mode
                                              float iterationCount,         // Max Iterations
                                              constant const float *colors, // Active Color Palette
                                              int colorsCount,              // Auto injected by Shader init for prior pointer array
                                              device const void *refOrbitData,  // Pertubation reference orbit
                                              int refOrbitDataCount             // AUTO-INJECTED for the refOrbit buffer
                                              ) {
    float minDimension = min(size.x, size.y);
    float2 centerOffset = size * 0.5;
    int maxIt = int(iterationCount);
    int iteration = -1;
    float escapeThresholdSq = 4.0;
    
    // --- HYBRID SWITCH POINT ---
    // If the scale is wide (zoomed out), use high-speed standard Mandelbrot math.
    // Perturbation theory is only required when scale is small (zoomed in deeply).
    if (scale > 0.25) {
        // Calculate raw complex plane coordinate for this specific pixel
        // Centered around an assumed baseline offset matching your CPU center context (-0.5, 0)
        float2 c = activeCenter + (position - centerOffset) / minDimension * scale;
        float2 z = float2(0.0, 0.0);
        
        for (int i = 0; i < maxIt; ++i) {
            float nextX = z.x * z.x - z.y * z.y + c.x;
            float nextY = 2.0 * z.x * z.y + c.y;
            z = float2(nextX, nextY);
            
            if ((z.x * z.x + z.y * z.y) > escapeThresholdSq) {
                iteration = i;
                break;
            }
        }
    }
    // Otherwise, utilize high-precision Perturbation Theory
    else {
        device const float2 *refOrbit = (device const float2 *)refOrbitData;
        float2 pixelOffset = (position - centerOffset) / minDimension * scale;
        float2 dc = (activeCenter - stableOrbitCenter) + pixelOffset;
        float2 dz = dc;
        
        for (int i = 0; i < refOrbitDataCount; ++i) {
            float2 refZ = refOrbit[i];
            // --- SAFE FALLBACK GUARD ---
            // If the reference orbit has already escaped (|refZ| > 2), it is exhausted.
            // Convert the remaining iterations into standard per-pixel Mandelbrot math to stop the leak.
            if ((refZ.x * refZ.x + refZ.y * refZ.y) > escapeThresholdSq) {
                // Calculate the absolute position of this pixel in complex space
                float2 trueC = stableOrbitCenter + dc;
                // Reconstruct absolute Z from our last valid relative state: Z = refZ + dz
                float2 trueZ = refZ + dz;
                
                // Finish the remaining iterations using native standard loop math
                for (int j = i; j < maxIt; ++j) {
                    float nextX = trueZ.x * trueZ.x - trueZ.y * trueZ.y + trueC.x;
                    float nextY = 2.0 * trueZ.x * trueZ.y + trueC.y;
                    trueZ = float2(nextX, nextY);
                    
                    if ((trueZ.x * trueZ.x + trueZ.y * trueZ.y) > escapeThresholdSq) {
                        iteration = j;
                        break;
                    }
                }
                break; // Exit the perturbation loop cleanly
            }
            
            float2 totalZ = refOrbit[i] + dz;
            if ((totalZ.x * totalZ.x + totalZ.y * totalZ.y) > escapeThresholdSq) {
                iteration = i;
                break;
            }
            
            float dx = 2.0 * (refZ.x * dz.x - refZ.y * dz.y) + (dz.x * dz.x - dz.y * dz.y) + dc.x;
            float dy = 2.0 * (refZ.x * dz.y + refZ.y * dz.x) + (2.0 * dz.x * dz.y) + dc.y;
            dz = float2(dx, dy);
        }
    }
    
    if (iteration == -1) {
        return half4(0.0, 0.0, 0.0, 1.0);
    }
    
    if (iteration == -1) return half4(0, 0, 0, 1); // black
    int totalColors = colorsCount / 4;
//    int paletteIndex = (iteration + int(cycle)) % totalColors;
//    int idx = paletteIndex * 3;
//    return half4(half(colors[idx]), half(colors[idx+1]), half(colors[idx+2]), 1.0);
    return color_lookup(colors, iteration, iterationCount, totalColors, colorsCount, cycle);
}

