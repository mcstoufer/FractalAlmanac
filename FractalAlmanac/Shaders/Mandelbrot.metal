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

df_float df_add(df_float a, df_float b) {
    df_float z;
    float t1 = a.hi + b.hi;
    float e = t1 - a.hi;
    float t2 = ((b.hi - e) + (a.hi - (t1 - e))) + a.lo + b.lo;
    z.hi = t1 + t2;
    z.lo = t2 - (z.hi - t1);
    return z;
}

df_float df_mul(df_float a, df_float b) {
    df_float z;
    float t1 = a.hi * b.hi;
    float t2 = fma(a.hi, b.hi, -t1);
    t2 += a.hi * b.lo + a.lo * b.hi;
    z.hi = t1 + t2;
    z.lo = t2 - (z.hi - t1);
    return z;
}

[[ stitchable ]] half4 mandelbrot(float2 position,
                                  float4 realBounds,   // minReal.hi, minReal.lo, maxReal.hi, maxReal.lo
                                  float4 imagBounds,   // minImag.hi, minImag.lo, maxImag.hi, maxImag.lo
                                  float2 scale,
                                  float2 c,
                                  device const float *colors,
                                  int colorsCount) {
    int totalColors = colorsCount / 4;
    uint32_t maxIterations = 250;
    // Scale the coordinates to the complex domain.
    df_float cx = { position.x, 0.0f };
    df_float cy = { position.y, 0.0f };
    
    df_float zx = { 0.0f, 0.0f };
    df_float zy = { 0.0f, 0.0f };
    uint32_t i = 0;

    for (; i < maxIterations; i++) {
        df_float zx2 = df_mul(zx, zx);
        df_float zy2 = df_mul(zy, zy);
        
        if ((zx2.hi + zy2.hi) >= 4.0f) break;
        
        // zy = 2 * zx * zy + cy
        df_float two_zx = df_add(zx, zx);
        zy = df_add(df_mul(two_zx, zy), cy);
        
        // zx = zx2 - zy2 + cx
        df_float neg_zy2 = { -zy2.hi, -zy2.lo };
        zx = df_add(df_add(zx2, neg_zy2), cx);
    }
    if (i == maxIterations) return half4(0.0,0.0,0.0,1.0); // black
    int colorIndex = i % totalColors;
    int byteOffset = colorIndex * 4;
    
    if (byteOffset >= colorsCount - 3) {
        byteOffset = colorsCount - 4;
    }
    
    return half4(colors[byteOffset], colors[byteOffset+1], colors[byteOffset+2], 1.0);
}
