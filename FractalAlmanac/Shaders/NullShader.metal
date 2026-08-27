//
//  NullShader.metal
//  FractalAlmanac
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>

using namespace metal;

// This no-op Shader is provided for Fractal sets who have been migrated to their own pipeline that define
// its own custom buffer components instead of a standard Shader argument list.
[[ stitchable ]] half4 nullShader(float2 position, SwiftUI::Layer layer) {
    return layer.sample(position);
}
