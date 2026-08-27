//
//  Float2ShaderUtilities.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 8/4/26.
//

#include <metal_stdlib>
using namespace metal;


inline float2 quickTwoSum(float a, float b) {
    float s = a + b;
    float e = b - (s - a);
    return float2(s, e);
}

inline float2 f2_add(float2 a, float2 b) {
    float s = a.x + b.x;
    float v = s - a.x;
    float e = (a.x - (s - v)) + (b.x - v) + a.y + b.y;
    return quickTwoSum(s, e);
}

inline float2 f2_sub(float2 a, float2 b) {
    float s = a.x - b.x;
    float v = s - a.x;
    float e = (a.x - (s - v)) - (b.x + v) + a.y - b.y;
    return quickTwoSum(s, e);
}


// Helper function for split-precision multiplication
inline float2 f2_mul(float2 a, float2 b) {
    float c = a.x * b.x;
    float c_exp = fma(a.x, b.x, -c);
    c_exp += a.x * b.y + a.y * b.x;
    return quickTwoSum(c, c_exp);
}

inline float2 ds_mul(float2 a, float2 b) {
    // Split constant factor: 2^12 + 1 = 4097.0f
    float c_split = 4097.0f;
    
    // Split 'a' into independent upper and lower halves
    float p_a = a.x * c_split;
    float a_hi = p_a - (p_a - a.x);
    float a_lo = a.x - a_hi;
    
    // Split 'b' into independent upper and lower halves
    float p_b = b.x * c_split;
    float b_hi = p_b - (p_b - b.x);
    float b_lo = b.x - b_hi;
    
    // Direct computation of the floating-point product and exact remainder
    float hi = a.x * b.x;
    float lo = (((a_hi * b_hi - hi) + a_hi * b_lo) + a_lo * b_hi) + a_lo * b_lo;
    
    // Incorporate the lower tracking properties
    lo += a.x * b.y + a.y * b.x;
    
    // Renormalize into a valid [Hi, Lo] vector output
    float h = hi + lo;
    return float2(h, lo + (hi - h));
}

inline float2 ds_add(float2 a, float2 b) {
    float s = a.x + b.x;
    float v = s - a.x;
    float t = (a.x - (s - v)) + (b.x - v);
    float lo = t + (a.y + b.y);
    
    // Renormalize the result so .x always holds the dominant magnitude
    float h = s + lo;
    return float2(h, lo + (s - h));
}
