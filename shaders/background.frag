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
uniform float uZoom;           // Zoom level (1.0 = normal, >1 = zoomed in)

// Sampler for star texture
uniform sampler2D uStarTexture;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 resolution = vec2(uResolutionX, uResolutionY);
    vec2 texSize = vec2(uTexWidth, uTexHeight);
    
    // Apply zoom by scaling from center of screen
    vec2 center = resolution * 0.5;
    vec2 fromCenter = fragCoord - center;
    vec2 zoomedPos = center + fromCenter / uZoom;
    
    // Calculate tiled UV coordinates with offset
    vec2 tiledPos = zoomedPos + vec2(uOffsetX, uOffsetY);
    
    // Wrap coordinates to create seamless tiling
    vec2 uv = mod(tiledPos, texSize) / texSize;
    
    // Sample the texture
    fragColor = texture(uStarTexture, uv);
}
