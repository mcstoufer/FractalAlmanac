//
//  QuadFloatShaderUtilities.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 8/4/26.
//

#include <metal_stdlib>
using namespace metal;

struct qf_float {
    float4 components; // x: hi, y: mid1, z: mid2, w: lo
};

// Exact hardware two-sum error tracking
inline float2 hardware_two_sum(float a, float b) {
    float s = a + b;
    float err = fma(1.0f, a - (s - b), b - (s - a));
    return float2(s, err);
}

inline qf_float df_to_qf(float2 df) {
    // Extract the rounding error of the high part to fill the mid lane
    float hi = df.x;
    float mid1 = fma(1.0f, df.x - hi, df.y); // Capture the remainder
    float2 r = hardware_two_sum(hi, mid1);
    
    // Distribute into a clean 4-lane float4
    return qf_float{ float4(r.x, r.y, 0.0f, 0.0f) };
}

inline qf_float float_to_qf(float f) {
    return qf_float{ float4(f, 0.0f, 0.0f, 0.0f) };
}

inline qf_float qf_add(qf_float a, qf_float b) {
    float4 s, e;
    
    // Pairwise component addition with error isolation
    float2 r = hardware_two_sum(a.components.x, b.components.x);
    s.x = r.x; e.x = r.y;
    
    r = hardware_two_sum(a.components.y, b.components.y);
    s.y = r.x; e.y = r.y;
    
    r = hardware_two_sum(a.components.z, b.components.z);
    s.z = r.x; e.z = r.y;
    
    r = hardware_two_sum(a.components.w, b.components.w);
    s.w = r.x; e.w = r.y;
    
    // Cascade tracking errors downward
    r = hardware_two_sum(s.y, e.x); s.y = r.x; e.x = r.y;
    r = hardware_two_sum(s.z, e.y); s.z = r.x; e.y = r.y;
    r = hardware_two_sum(s.w, e.z); s.w = r.x; e.z = r.y;
    
    float final_w = s.w + e.w + e.x + e.y + e.z;
    
    // Fast structural renormalization pass
    r = hardware_two_sum(s.x, s.y); float th = r.x; float tm1 = r.y;
    r = hardware_two_sum(tm1, s.z); tm1 = r.x; float tm2 = r.y;
    r = hardware_two_sum(tm2, final_w); tm2 = r.x; float tl = r.y;
    
    return qf_float{ float4(th, tm1, tm2, tl) };
}

inline qf_float qf_sub(qf_float a, qf_float b) {
    // 1. Negate all vector lanes of the right-hand operand
    qf_float neg_b = qf_float{ float4(-b.components.x, -b.components.y, -b.components.z, -b.components.w) };
    
    // 2. Route straight into the optimized hardware quad-addition pipeline
    return qf_add(a, neg_b);
}

inline qf_float qf_mul(qf_float a, qf_float b) {
    float p0 = a.components.x * b.components.x;
    float e0 = fma(a.components.x, b.components.x, -p0);
    
    float p1 = a.components.x * b.components.y;
    float e1 = fma(a.components.x, b.components.y, -p1);
    
    float p2 = a.components.y * b.components.x;
    float e2 = fma(a.components.y, b.components.x, -p2);
    
    float p3 = a.components.x * b.components.z;
    float p4 = a.components.y * b.components.y;
    float p5 = a.components.z * b.components.x;
    
    // Accumulate the primary error pipelines
    float2 r = hardware_two_sum(e0, p1);  float s1 = r.x; float e1_acc = r.y;
    r = hardware_two_sum(s1, p2);          float s2 = r.x; float e2_acc = r.y;
    
    float carry = e1_acc + e2_acc + e1 + e2 + p3 + p4 + p5 +
    (a.components.x * b.components.w) +
    (a.components.y * b.components.z) +
    (a.components.z * b.components.y) +
    (a.components.w * b.components.x);
    
    // Chained renormalization back into a clean float4 split
    r = hardware_two_sum(p0, s2);    float th = r.x;  float tm1 = r.y;
    r = hardware_two_sum(tm1, carry); tm1 = r.x; float tm2 = r.y;
    
    return qf_float{ float4(th, tm1, tm2, tm2) };
}

inline half4 color_lookup(constant float *colors, uint32_t i,
                          qf_float zx, qf_float zy,
                          float maxIterations, int totalColors,
                          int colorsCount, float cycle) {
    if (i == maxIterations) return half4(0.0,0.0,0.0,1.0); // black
    
    int colorIndex = 0;
    if (cycle == 0) {
        colorIndex = (i * totalColors / maxIterations);
    } else if (cycle == 1) {
        colorIndex = i % totalColors;
    }
//    else {
//        float smoothIteration = smoother(i, maxIterations, zx, zy);
//        return smoothed_color_lookup(colors, smoothIteration, maxIterations, totalColors, colorsCount, cycle);
//    }
    
    int byteOffset = colorIndex * 4;
    if (byteOffset >= colorsCount - 3) {
        byteOffset = colorsCount - 4;
    }
    return half4(colors[byteOffset], colors[byteOffset+1], colors[byteOffset+2], 1.0);
}
