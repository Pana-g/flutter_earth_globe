#version 460 core

#include <flutter/runtime_effect.glsl>

// Output color
out vec4 fragColor;

// Uniforms - sphere parameters (float uniforms must come before samplers)
uniform float uResolutionX;    // Canvas width
uniform float uResolutionY;    // Canvas height
uniform float uCenterX;        // Sphere center X on screen
uniform float uCenterY;        // Sphere center Y on screen
uniform float uRadius;         // Sphere radius in pixels
uniform float uRotationX;      // X rotation in radians
uniform float uRotationZ;      // Z rotation in radians

// Uniforms - day/night cycle
uniform float uSunLongitude;   // Sun longitude in radians
uniform float uSunLatitude;    // Sun latitude in radians
uniform float uBlendFactor;    // Day/night transition sharpness
uniform float uDayNightEnabled; // 1.0 if day/night cycle enabled, 0.0 otherwise

// Samplers for textures (must come after float uniforms)
uniform sampler2D uDaySurface;
uniform sampler2D uNightSurface;

// Constants
const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;
const float HALF_PI = 1.57079632679;

// Rotation matrix around X axis
mat3 rotationMatrixX(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        1.0, 0.0, 0.0,
        0.0, c, -s,
        0.0, s, c
    );
}

// Rotation matrix around Z axis
mat3 rotationMatrixZ(float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        c, -s, 0.0,
        s, c, 0.0,
        0.0, 0.0, 1.0
    );
}

// Calculate day/night blend factor
float calculateDayNightFactor(float lat, float lon) {
    // Calculate the angle between the point and the sun
    float cosAngle = sin(lat) * sin(uSunLatitude) + 
                     cos(lat) * cos(uSunLatitude) * cos(lon - uSunLongitude);
    
    // Map to 0-1 with smooth transition based on blend factor
    return clamp(cosAngle / uBlendFactor + 0.5, 0.0, 1.0);
}

void main() {
    // Get fragment position relative to center
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 center = vec2(uCenterX, uCenterY);
    vec2 pos = fragCoord - center;
    
    // Calculate distance from center
    float dist = length(pos);
    float radiusSquared = uRadius * uRadius;
    
    // Anti-aliasing with fixed edge width for smooth edges
    // Use 1.5 pixels of smoothing at the edge
    float edgeWidth = 1.5;
    
    // Smooth transition at the edge
    float edgeAlpha = 1.0 - smoothstep(uRadius - edgeWidth, uRadius + edgeWidth * 0.5, dist);
    
    // If completely outside the AA band, output transparent
    if (edgeAlpha <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }
    
    // For pixels at the edge, we need to calculate z carefully
    // Clamp distance to just inside the sphere for stable z calculation
    float effectiveDist = min(dist, uRadius - 0.5);
    float distSquared = effectiveDist * effectiveDist;
    
    // Calculate z coordinate on sphere surface
    float z = sqrt(radiusSquared - distSquared);
    
    // For edge pixels, scale pos to stay on sphere surface
    // This ensures proper texture sampling at the edge
    vec2 effectivePos = pos;
    if (dist > effectiveDist) {
        effectivePos = pos * (effectiveDist / dist);
    }
    
    // Create 3D point on sphere
    vec3 spherePoint = vec3(effectivePos.x, effectivePos.y, z);
    
    // Apply combined rotation (Z then X, matching the Dart code)
    mat3 rotX = rotationMatrixX(HALF_PI - uRotationX);
    mat3 rotZ = rotationMatrixZ(uRotationZ + HALF_PI);
    mat3 combinedRot = rotZ * rotX;
    
    vec3 rotatedPoint = combinedRot * spherePoint;
    
    // Convert to spherical coordinates (lat/lon)
    float invRadius = 1.0 / uRadius;
    float lat = asin(rotatedPoint.z * invRadius);
    float lon = atan(rotatedPoint.y, rotatedPoint.x);
    
    // Convert to UV coordinates for texture sampling
    // lon is in [-PI, PI], map to [0, 1]
    // lat is in [-PI/2, PI/2], map to [0, 1]
    vec2 uv;
    uv.x = (lon + PI) / TWO_PI;
    uv.y = (HALF_PI - lat) / PI;
    
    // Sample day texture
    vec4 dayColor = texture(uDaySurface, uv);
    
    // Apply day/night cycle if enabled
    if (uDayNightEnabled > 0.5) {
        vec4 nightColor = texture(uNightSurface, uv);
        float dayFactor = calculateDayNightFactor(lat, lon);
        
        // Blend between day and night
        fragColor = mix(nightColor, dayColor, dayFactor);
    } else {
        fragColor = dayColor;
    }
    
    // Apply anti-aliasing edge smoothing with premultiplied alpha
    // This ensures proper blending with the background
    fragColor.rgb *= edgeAlpha;
    fragColor.a *= edgeAlpha;
}
