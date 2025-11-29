#version 460 core

#include <flutter/runtime_effect.glsl>

// Output color
out vec4 fragColor;

// Uniforms - background parameters
uniform float uResolutionX;    // Canvas width
uniform float uResolutionY;    // Canvas height
uniform float uOffsetX;        // X offset for rotation
uniform float uOffsetY;        // Y offset for rotation
uniform float uTexWidth;       // Texture width
uniform float uTexHeight;      // Texture height

// Sampler for star texture
uniform sampler2D uStarTexture;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 texSize = vec2(uTexWidth, uTexHeight);
    
    // Calculate tiled UV coordinates with offset
    vec2 tiledPos = fragCoord + vec2(uOffsetX, uOffsetY);
    
    // Wrap coordinates to create seamless tiling
    vec2 uv = mod(tiledPos, texSize) / texSize;
    
    // Sample the texture
    fragColor = texture(uStarTexture, uv);
}
