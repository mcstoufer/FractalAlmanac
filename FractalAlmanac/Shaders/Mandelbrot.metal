//
//  Mandelbrot.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 7/20/26.
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

//df_float df_mix(df_float a, df_float b, float t) {
//    df_float neg_a = { -a.hi, -a.lo };
//    df_float diff = df_add(b, neg_a); // (b - a)
//    df_float t_df = { t, 0.0f };       // Convert interpolation factor to df_float
//    df_float scaled_diff = df_mul(diff, t_df); // t * (b - a)
//    return df_add(a, scaled_diff);    // a + t * (b - a)
//}

[[ stitchable ]] half4 mandelbrot(float2 position,
                                  half4 currentColor,
                                  float4 centerRealSplit,   // centerReal.hi, centerReal.lo
                                  float4 centerImagSplit,   // centerImag.hi, centerImag.lo
                                  float4 scaleSplit,        // dx.hi, dx.lo, dy.hi, dy.lo (Precalculated pixel step size)
                                  float2 size,
                                  float2 tuningData,
                                  float cycle,
                                  device const float *colors,
                                  int colorsCount) {
    int totalColors = colorsCount / 4;
    uint32_t maxIterations = static_cast<uint32_t>(tuningData.x);

    float offsetX = position.x - (size.x * 0.5f);
    float offsetY = position.y - (size.y * 0.5f);
    
    df_float c_real_center = { centerRealSplit.x, centerRealSplit.y };
    df_float c_imag_center = { centerImagSplit.x, centerImagSplit.y };
    
    df_float dx = { scaleSplit.x, scaleSplit.y };
    df_float dy = { scaleSplit.z, scaleSplit.w };
    
    df_float offset_x_df = { offsetX, 0.0f };
    df_float offset_y_df = { offsetY, 0.0f };
    
    df_float cx = df_add(c_real_center, df_mul(offset_x_df, dx));
    df_float cy = df_add(c_imag_center, df_mul(offset_y_df, dy));
    
    df_float zx = { 0.0f, 0.0f };
    df_float zy = { 0.0f, 0.0f };
    uint32_t i = 0;

    for (; i < maxIterations; i++) {
        df_float zx2 = df_mul(zx, zx);
        df_float zy2 = df_mul(zy, zy);
        
        if ((zx2.hi + zy2.hi) >= 4.0f) {
            break;
        }
        
        df_float two_zx = df_add(zx, zx);
        zy = df_add(df_mul(two_zx, zy), cy);
        
        df_float neg_zy2 = { -zy2.hi, -zy2.lo };
        zx = df_add(df_add(zx2, neg_zy2), cx);
    }
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
