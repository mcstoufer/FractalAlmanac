//
//  MandelbrotPertubation.metal
//  FractalAlmanac
//
//  Created by Martin Stoufer on 8/11/26.
//

#include <metal_stdlib>
#include "Helpers/Float2ShaderUtilities.metal"
#include "Helpers/DualFloatShaderUtilities.metal"

using namespace metal;

kernel void mandelbrotComputePerturbation(
                                          texture2d<float, access::write> outputTexture [[texture(0)]],
                                          device const float4* refOrbit                 [[buffer(0)]], // xHi, xLo, yHi, yLo
                                          constant float2& uScale                       [[buffer(1)]],
                                          constant float& maxIterationsFloat            [[buffer(2)]],
                                          constant float& cyclePalette                  [[buffer(3)]],
                                          constant float2& centerX_Split                [[buffer(4)]],
                                          constant float2& centerY_Split                [[buffer(5)]],
                                          constant float2& referenceCenterX_Split       [[buffer(6)]],
                                          constant float2& referenceCenterY_Split       [[buffer(7)]],
                                          constant float *colors                        [[buffer(8)]],
                                          constant int& colorsCount                     [[buffer(9)]],
                                          uint2 gid                                     [[thread_position_in_grid]]
                                          ) {
    
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    
    uint32_t maxIterations = uint32_t(maxIterationsFloat);
    uint32_t iteration = 0;
    float4 finalColor = float4(0.0f, 0.0f, 0.0f, 1.0f); // Set background defaults to deep space black
    float2 screenSize = float2(outputTexture.get_width(), outputTexture.get_height());
    float2 centeredPosition = float2(gid) - (screenSize * 0.5f);

    // Brute-force section for low zoom level.
    if (uScale.x > 1e-7f) {
        
        df_float dx = df_mul(df_create(centeredPosition.x), df_create(uScale.x));
        df_float dy = df_mul(df_create(-centeredPosition.y), df_create(uScale.y));
        
        // Final coordinate vectors = screen offset + base viewport target coordinates
        df_float cx = df_add(dx, {centerX_Split.x, centerX_Split.y});
        df_float cy = df_add(dy, {centerY_Split.x, centerY_Split.y});
        
        df_float zx = df_float {0.0, 0.0};
        df_float zy = df_create(0.0f);
        
        df_float zx2 = df_create(0.0f);
        df_float zy2 = df_create(0.0f);
        
        while (iteration < maxIterations) {
            zx2 = df_mul(zx, zx);
            zy2 = df_mul(zy, zy);
            
            // Escape evaluation check: Zx^2 + Zy^2 > 4.0
            if ((zx2.hi + zy2.hi) > 4.0f) {
                break;
            }
            
            // Zy_next = 2 * Zx * Zy + Cy
            df_float two_zx = df_add(zx, zx);
            df_float next_zy = df_add(df_mul(two_zx, zy), cy);
            
            // Zx_next = Zx^2 - Zy^2 + Cx
            df_float next_zx = df_add(df_sub(zx2, zy2), cx);
            
            zx = next_zx;
            zy = next_zy;
            iteration++;
        }
        
        // 5. Color mapping based on iteration escape depth
        int totalColors = colorsCount / 4;
        float4 bruteColor = float4(
                    smoothable_color_lookup(
                        colors,
                        iteration,
                        zx, zy,
                        maxIterations,
                        totalColors,
                        colorsCount,
                        cyclePalette
                    )
                );
        outputTexture.write(bruteColor, gid);
        return;
    }
    
    // Pertubation theory zoom for deep-zoom resolution.
    // REVISED DIAGNOSTIC CHECK: Validate the array using index, since index [0] is always (0,0)
    if (maxIterations > 1) {
        float4 secondPoint = refOrbit[1];
        if (isnan(secondPoint.x) || isinf(secondPoint.x)) {
            outputTexture.write(float4(1.0f, 0.0f, 0.0f, 1.0f), gid); // Red Warning Screen
            return;
        }
    }
    
    df_float centerX = {centerX_Split.x, centerX_Split.y};
    df_float centerY = {centerY_Split.x, centerY_Split.y};
    df_float referenceCenterX = {referenceCenterX_Split.x, referenceCenterX_Split.y};
    df_float referenceCenterY = {referenceCenterY_Split.x, referenceCenterY_Split.y};
    df_float centerDeltaX = df_sub(centerX, referenceCenterX);
    df_float centerDeltaY = df_sub(centerY, referenceCenterY);
    
    // Delta c is the live viewport center relative to the fixed reference orbit plus this pixel's offset.
    df_float deltaCX = df_add(centerDeltaX, df_mul(df_create(centeredPosition.x), df_create(uScale.x)));
    df_float deltaCY = df_add(centerDeltaY, df_mul(df_create(-centeredPosition.y), df_create(uScale.y)));
    df_float deltaZX = df_create(0.0f);
    df_float deltaZY = df_create(0.0f);
    df_float escapedAbsoluteZX = df_create(0.0f);
    df_float escapedAbsoluteZY = df_create(0.0f);
    
    while (iteration + 1 < maxIterations) {
        // Fetch pre-computed reference orbit position X_n
        float4 refPoint = refOrbit[iteration];
        df_float X = {refPoint.x, refPoint.y};
        df_float Y = {refPoint.z, refPoint.w};

        // 2 * X * deltaZ
        df_float twoXDeltaZX = df_sub(df_mul(X, deltaZX), df_mul(Y, deltaZY));
        twoXDeltaZX = df_add(twoXDeltaZX, twoXDeltaZX);
        
        df_float twoXDeltaZY = df_add(df_mul(X, deltaZY), df_mul(Y, deltaZX));
        twoXDeltaZY = df_add(twoXDeltaZY, twoXDeltaZY);
        
        // deltaZ ^ 2
        df_float deltaZX2 = df_mul(deltaZX, deltaZX);
        df_float deltaZY2 = df_mul(deltaZY, deltaZY);
        df_float deltaZSquaredX = df_sub(deltaZX2, deltaZY2);
        df_float deltaZSquaredY = df_add(df_mul(deltaZX, deltaZY), df_mul(deltaZX, deltaZY));
        
        // Update displacement tracking state
        deltaZX = df_add(df_add(twoXDeltaZX, deltaZSquaredX), deltaCX);
        deltaZY = df_add(df_add(twoXDeltaZY, deltaZSquaredY), deltaCY);
        
        iteration++;
        
        // Escape evaluation: Absolute Z_(n+1) = X_(n+1) + deltaZ_(n+1)
        float4 nextRefPoint = refOrbit[iteration];
        df_float nextX = {nextRefPoint.x, nextRefPoint.y};
        df_float nextY = {nextRefPoint.z, nextRefPoint.w};
        df_float absoluteZX = df_add(nextX, deltaZX);
        df_float absoluteZY = df_add(nextY, deltaZY);
        df_float magnitudeSquared = df_add(df_mul(absoluteZX, absoluteZX), df_mul(absoluteZY, absoluteZY));
        if (magnitudeSquared.hi > 4.0f) {
            escapedAbsoluteZX = absoluteZX;
            escapedAbsoluteZY = absoluteZY;
            break;
        }
    }
    
    // Pertubation mapping color calculations
    int totalColors = colorsCount / 4;
    finalColor = float4(
        smoothable_color_lookup(
            colors,
            iteration,
            escapedAbsoluteZX,
            escapedAbsoluteZY,
            maxIterationsFloat,
            totalColors,
            colorsCount,
            cyclePalette
        )
    );
   
    outputTexture.write(finalColor, gid);
}
