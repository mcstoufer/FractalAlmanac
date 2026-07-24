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
