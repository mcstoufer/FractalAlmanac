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

inline df_float df_add(df_float a, df_float b) {
    float s = a.hi + b.hi;
    float v = s - a.hi;
    float e = (a.hi - (s - v)) + (b.hi - v) + a.lo + b.lo;
    
    // Quick two-sum normalization pass
    float s_norm = s + e;
    float e_norm = e - (s_norm - s);
    return df_float{s_norm, e_norm};
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

inline float2 quick_two_sum(float a, float b) {
    float s = a + b;
    float v = s - a;
    float e = b - v;
    return float2(s, e);
}

inline half4 color_lookup(device const float *colors, uint32_t i,
                          float maxIterations, int totalColors,
                          int colorsCount, bool cycle) {
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
