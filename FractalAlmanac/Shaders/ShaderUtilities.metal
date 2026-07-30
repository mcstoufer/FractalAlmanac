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

inline float2 quickTwoSum(float a, float b) {
    float s = a + b;
    float e = b - (s - a);
    return float2(s, e);
}

inline df_float df_add(df_float a, df_float b) {
    float s = a.hi + b.hi;
    float v = s - a.hi;
    float e = (a.hi - (s - v)) + (b.hi - v) + a.lo + b.lo;
    
    // Quick two-sum normalization pass
    float s_norm = s + e;
    float e_norm = e - (s_norm - s);
    return df_float{s_norm, e_norm};
}

inline float2 f2_add(float2 a, float2 b) {
    float s = a.x + b.x;
    float v = s - a.x;
    float e = (a.x - (s - v)) + (b.x - v) + a.y + b.y;
    return quickTwoSum(s, e);
}

inline df_float df_sub(df_float a, df_float b) {
    // 1. Compute the structural difference of the high parts
    float s_hi = a.hi - b.hi;
    
    // 2. Compute the exact floating-point error of that high subtraction
    float v = s_hi - a.hi;
    float err_hi = (a.hi - (s_hi - v)) - (b.hi + v);
    
    // 3. Accumulate the low parts and the high part error
    float s_lo = (a.lo - b.lo) + err_hi;
    
    // 4. Renormalize the result into a clean high/low split
    float th = s_hi + s_lo;
    float tl = s_lo - (th - s_hi);
    
    return { th, tl };
}

inline float2 f2_sub(float2 a, float2 b) {
    float s = a.x - b.x;
    float v = s - a.x;
    float e = (a.x - (s - v)) - (b.x + v) + a.y - b.y;
    return quickTwoSum(s, e);
}

inline float2 df_split(float a) {
    // 131073.0f represents 2^17 + 1, perfect for splitting 24-bit mantissas
    float c = a * 131073.0f;
    float ab_hi = c - (c - a);
    float ab_lo = a - ab_hi;
    return float2(ab_hi, ab_lo);
}

inline df_float df_mul(df_float a, df_float b) {
    float p = a.hi * b.hi;
    
    // Split inputs safely to find exact lower remnants
    float2 a_split = df_split(a.hi);
    float2 b_split = df_split(b.hi);
    
    float e = ((((a_split.x * b_split.x - p) + a_split.x * b_split.y) + a_split.y * b_split.x) + a_split.y * b_split.y)
    + a.hi * b.lo + a.lo * b.hi;
    
    // Quick two-sum normalization pass
    float s_norm = p + e;
    float e_norm = e - (s_norm - p);
    return df_float{s_norm, e_norm};
}

// Helper function for split-precision multiplication
inline float2 f2_mul(float2 a, float2 b) {
    float c = a.x * b.x;
    float c_exp = fma(a.x, b.x, -c);
    c_exp += a.x * b.y + a.y * b.x;
    return quickTwoSum(c, c_exp);
}

inline float2 quick_two_sum(float a, float b) {
    float s = a + b;
    float v = s - a;
    float e = b - v;
    return float2(s, e);
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

inline half4 color_lookup(device const float *colors,
                          float i,
                          float maxIterations, int totalColors,
                          int colorsCount, bool cycle) {
    if (i == maxIterations) return half4(0.0,0.0,0.0,1.0); // black
    
    // 1. Calculate a continuous floating-point index mapped to the total color scale
    float continuousIndex = 0.0;
    if (cycle) {
        continuousIndex = fmod(i, (float)totalColors);
    } else {
        continuousIndex = (i * (float)totalColors) / maxIterations;
    }
    
    // 2. Identify the two adjacent color indices to interpolate between
    int index1 = (int)floor(continuousIndex);
    int index2 = (index1 + 1);
    
    // Handle wrapping for cycling palettes, or clamp to the last index
    if (cycle) {
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
    
//    int colorIndex = 0;
//    if (cycle == 1) {
//        colorIndex = i % totalColors;
//    } else {
//        colorIndex = (i * totalColors / maxIterations);
//    }
//    
//    int byteOffset = colorIndex * 4;
//    if (byteOffset >= colorsCount - 3) {
//        byteOffset = colorsCount - 4;
//    }
//    
//    return half4(colors[byteOffset], colors[byteOffset+1], colors[byteOffset+2], 1.0);
}
