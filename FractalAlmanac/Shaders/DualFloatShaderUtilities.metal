//
//  DualFloatShaderUtilities.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 8/4/26.
//

#include <metal_stdlib>
#include "ShaderUtilities.metal"

using namespace metal;

inline df_float df_create(float v) {
    return {v, 0.0f};
}
inline df_float three_sum(float a, float b, float c) {
    // Pass 1: Compute high sum approximation
    float th = a + b;
    float err_a = th - a;
    float tl = (a - (th - err_a)) + (b - err_a);
    
    // Pass 2: Merge the third component into the tracking stream
    float total_hi = th + c;
    float err_th = total_hi - th;
    float total_lo = tl + ((th - (total_hi - err_th)) + (c - err_th));
    
    return { total_hi, total_lo };
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

inline df_float df_sub(df_float a, df_float b) {
    float s_hi = a.hi - b.hi;
    
    // Hardware-accelerated error extraction via FMA: error = (a.hi - s_hi) - b.hi
    // Evaluated with infinite intermediate precision
    float err_hi = fma(1.0f, a.hi - s_hi, -b.hi);
    
    // Accumulate low parts
    float s_lo = a.lo - b.lo;
    
    return three_sum(s_hi, s_lo, err_hi);
}

inline df_float df_mul(df_float a, df_float b) {
    // 1. Compute the high-precision approximation of the product
    float p = a.hi * b.hi;
    
    // 2. Hardware-isolated high error extraction via FMA
    float err_hi = fma(a.hi, b.hi, -p);
    
    // 3. Accumulate cross-terms of low-precision components safely
    float cross_term_1 = a.hi * b.lo;
    float cross_term_2 = fma(a.lo, b.hi, err_hi);
    
    // 4. Combine the tracking variables through the Three-Sum pipeline
    return three_sum(p, cross_term_1, cross_term_2);
}

inline df_float df_mul2(df_float a, df_float b) {
    float p = a.hi * b.hi;
    float e = fma(a.hi, b.hi, -p) + a.hi * b.lo + a.lo * b.hi;
    return {p + e, e - ((p + e) - p)};
}

inline df_float df_add2(df_float a, df_float b) {
    float s = a.hi + b.hi;
    float v = s - a.hi;
    float e = (a.hi - (s - v)) + (b.hi - v) + a.lo + b.lo;
    return {s + e, e - ((s + e) - s)};
}

inline df_float df_sub2(df_float a, df_float b) {
    float s = a.hi - b.hi;
    float v = s - a.hi;
    float e = (a.hi - (s - v)) - (b.hi + v) + a.lo - b.lo;
    return {s + e, e - ((s + e) - s)};
}
