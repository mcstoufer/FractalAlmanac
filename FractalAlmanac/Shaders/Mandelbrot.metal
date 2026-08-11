//
//  MandelbrotPertub.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 8/10/26.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
#include "Float2ShaderUtilities.metal"
#include "ShaderUtilities.metal"
using namespace metal;

// Emulated Double addition: Quick-Two-Sum algorithm
inline float2 ds_add(float2 a, float2 b, thread float2& lo_out) {
    float2 s = a + b;
    float2 v = s - a;
    lo_out = (a - (s - v)) + (b - v);
    return s;
}

[[stitchable]] half4 mandelbrot(float2 position,           // Current pixel position (automatically passed by SwiftUI)
                                SwiftUI::Layer layer,      // FIX: Changed from half4 to SwiftUI::Layer
                                float2 xCenter,            // FIX: .x = High, .y = Low
                                float2 yCenter,            // FIX: .x = High, .y = Low
                                float2 uScale,             // FIX: .x = High, .y = Low (Uniform Scale)
                                float2 screenSize,         // FIX: Pass screen size to offset to viewport center
                                float iterationCount,     // Iteration depth limit
                                float cyclePalette,
                                constant const float *colors,
                                int colorsCount
                                ) {
    int maxIterations = int(iterationCount);
    float2 centeredPosition = position - (screenSize * 0.5f);
    
    float2 cx = ds_add(xCenter, ds_mul(uScale, float2(centeredPosition.x, 0.0f)));
    float2 cy = ds_add(yCenter, ds_mul(uScale, float2(-centeredPosition.y, 0.0f))); // Invert Y layout
    
    float2 zx = float2(0.0f, 0.0f);
    float2 zy = float2(0.0f, 0.0f);
    
    int iteration = 0;
    
    // 4. Standard Mandelbrot escape-time loop
    while (iteration < maxIterations) {
        // Zx^2 calculation
        // Calculate: Zx^2 and Zy^2
        float2 zx2 = ds_mul(zx, zx);
        float2 zy2 = ds_mul(zy, zy);
        
        // Escape check: Zx^2 + Zy^2 > 4.0
        if ((zx2.x + zy2.x) > 4.0f) break;
        
        // Calculate: New Zy = 2.0 * Zx * Zy + Cy
        float2 two_zx = ds_add(zx, zx);
        float2 next_zy = ds_add(ds_mul(two_zx, zy), cy);
        
        // Calculate: New Zx = Zx^2 - Zy^2 + Cx
        float2 zx2_minus_zy2 = ds_add(zx2, float2(-zy2.x, -zy2.y));
        float2 next_zx = ds_add(zx2_minus_zy2, cx);
        
        // Assign new state positions smoothly
        zx = next_zx;
        zy = next_zy;
        
        iteration++;
    }
    
    // 5. Color mapping based on iteration escape depth
    if (iteration == maxIterations) {
        return half4(0.0, 0.0, 0.0, 1.0); // Inside the set (Black)
    }
    
    int totalColors = colorsCount / 4;
    return color_lookup(colors, iteration, iterationCount, totalColors, colorsCount, cyclePalette);

}
