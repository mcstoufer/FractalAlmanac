//
//  ShaderUtilities.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/23/26.
//

#include <metal_stdlib>
using namespace metal;

struct df_float {
    float hi;
    float lo;
};

inline half4 smoothed_color_lookup(constant float *colors,
                                   float i,
                                   float maxIterations, int totalColors,
                                   int colorsCount, float cycle) {
    if (i == maxIterations) return half4(0.0,0.0,0.0,1.0); // black
    
    // 1. Calculate a continuous floating-point index mapped to the total color scale
    float continuousIndex = 0.0;
    if (cycle == 2) {
        continuousIndex = (i * (float)totalColors) / maxIterations;
    } else {
        continuousIndex = fmod(i, (float)totalColors);
    }
    
    // 2. Identify the two adjacent color indices to interpolate between
    int index1 = (int)floor(continuousIndex);
    int index2 = (index1 + 1);
    
    // Handle wrapping for cycling palettes, or clamp to the last index
    if (cycle >= 2) {
        index2 = index2 % totalColors;
    } else if (index2 >= totalColors) {
        index2 = totalColors - 1;
    }
    
    // 3. Calculate the fractional blend factor [0.0, 1.0] between the two stops
    float blendFactor = continuousIndex - (float)index1;
    
    // 4. Convert color indices to float array byte offsets (4 floats per color: R, G, B, A)
    int offset1 = index1 * 4;
    int offset2 = index2 * 4;
    
    // Safeguard array bounds based on the passed colorsCount
    if (offset1 >= colorsCount - 3) offset1 = colorsCount - 4;
    if (offset2 >= colorsCount - 3) offset2 = colorsCount - 4;
    
    // 5. Fetch both samples as half3 values (ignoring the Alpha float channel in the array)
    half3 color1 = half3(colors[offset1], colors[offset1+1], colors[offset1+2]);
    half3 color2 = half3(colors[offset2], colors[offset2+1], colors[offset2+2]);
    
    // 6. Linearly interpolate between the colors using the GPU built-in mix function
    half3 finalColor = mix(color1, color2, (half)blendFactor);
    
    return half4(finalColor, 1.0);
}

inline float smoother(uint32_t i, uint32_t maxIterations, df_float zx, df_float zy) {
    float smoothIteration = (float)i;
    if (i < maxIterations) {
        // Calculate the squared magnitude of Z at escape time
        float magSq = zx.hi * zx.hi + zy.hi * zy.hi;
        
        // Log-log fractional iteration correction formula
        // log(2.0) is approximately 0.693147f
        float log_zn = log(magSq) / 2.0f;
        float nu = log(log_zn / 0.693147f) / 0.693147f;
        
        // Subtract the correction factor to find exactly where between steps it escaped
        smoothIteration = smoothIteration + 1.0f - nu;
        
        // Safeguard to prevent negative bounds due to floating point inaccuracies
        if (smoothIteration < 0.0f) {
            smoothIteration = 0.0f;
        }
    }
    return smoothIteration;
}

inline float smoother(uint32_t i, uint32_t maxIterations, float zx, float zy) {
    float smoothIteration = (float)i;
    if (i < maxIterations) {
        // Calculate the squared magnitude of Z at escape time
        float magSq = zx * zx + zy * zy;
        
        // Log-log fractional iteration correction formula
        // log(2.0) is approximately 0.693147f
        float log_zn = log(magSq) / 2.0f;
        float nu = log(log_zn / 0.693147f) / 0.693147f;
        
        // Subtract the correction factor to find exactly where between steps it escaped
        smoothIteration = smoothIteration + 1.0f - nu;
        
        // Safeguard to prevent negative bounds due to floating point inaccuracies
        if (smoothIteration < 0.0f) {
            smoothIteration = 0.0f;
        }
    }
    return smoothIteration;
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

inline half4 smoothable_color_lookup(constant float *colors, uint32_t i,
                                     df_float zx, df_float zy,
                                     float maxIterations, int totalColors,
                                     int colorsCount, float cycle) {
    if (i == maxIterations) return half4(0.0,0.0,0.0,1.0); // black
    
    int colorIndex = 0;
    if (cycle == 0) {
        colorIndex = (i * totalColors / maxIterations);
    } else if (cycle == 1) {
        colorIndex = i % totalColors;
    } else {
        float smoothIteration = smoother(i, maxIterations, zx, zy);
        return smoothed_color_lookup(colors, smoothIteration, maxIterations, totalColors, colorsCount, cycle);
    }
    
    int byteOffset = colorIndex * 4;
    if (byteOffset >= colorsCount - 3) {
        byteOffset = colorsCount - 4;
    }
    return half4(colors[byteOffset], colors[byteOffset+1], colors[byteOffset+2], 1.0);
}

inline half4 smoothable_color_lookup(constant float *colors, uint32_t i,
                                     float zx, float zy,
                                     float maxIterations, int totalColors,
                                     int colorsCount, float cycle) {
    if (i == maxIterations) return half4(0.0,0.0,0.0,1.0); // black
    
    int colorIndex = 0;
    if (cycle == 0) {
        colorIndex = (i * totalColors / maxIterations);
    } else if (cycle == 1) {
        colorIndex = i % totalColors;
    } else {
        float smoothIteration = smoother(i, maxIterations, zx, zy);
        return smoothed_color_lookup(colors, smoothIteration, maxIterations, totalColors, colorsCount, cycle);
    }
    
    int byteOffset = colorIndex * 4;
    if (byteOffset >= colorsCount - 3) {
        byteOffset = colorsCount - 4;
    }
    return half4(colors[byteOffset], colors[byteOffset+1], colors[byteOffset+2], 1.0);
}
