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
