## 2.1.2

### 🐛 Bug Fixes

- **Improved background parallax zoom**: Background (starry sky) now zooms at a reduced rate (15% of globe zoom) for a more realistic depth perception. Distant stars appear to stay in place while the globe zooms, creating a natural parallax effect.

---

## 2.1.1

- Updated to `lints` package with `lints/core.yaml` for stricter analysis

---

## 2.1.0

### 🐛 Bug Fixes

- **Fixed texture change not updating**: Globe now properly updates when changing textures via `loadSurface()` without requiring manual interaction
- **Fixed chunky globe edges**: Added anti-aliasing to both GPU shader and CPU fallback rendering for smooth circular edges
- **Fixed deprecated API warnings**: Replaced deprecated `color.value` with `color.toARGB32()` and `color.opacity` with `color.a`
- **Fixed private type in public API**: Made `FlutterEarthGlobeState` public to comply with Dart best practices

### ✨ Improvements

- **Improved edge rendering**: Smooth sphere edges using smoothstep-based alpha blending
- **Better CPU fallback**: Enhanced CPU rendering path with proper anti-aliasing when GPU shaders are unavailable
- **Shader compatibility**: Removed unsupported `fwidth()` function for better platform compatibility
- **Cache invalidation**: Proper surface texture tracking in cache validation for both GPU and CPU rendering paths

---

## 2.0.0

### 🚀 Major Performance Improvements

- **GPU-accelerated rendering**: Sphere and background now use fragment shaders for significantly better performance
- **New shader-based sphere renderer**: Smooth texture mapping with hardware acceleration
- **New shader-based background renderer**: GPU-powered starry background with parallax effect
- **Optimized foreground rendering**: Separated repaint boundaries for hover/click events to prevent unnecessary repaints

### ✨ New Features

- **Satellites**: New satellite feature inspired by globe.gl
  - Add satellites with customizable styles (size, color, glow, shape)
  - Multiple satellite shapes: circle, square, triangle, star, satellite icon
  - Orbital animation support with customizable orbital parameters (inclination, period, eccentricity)
  - Orbit path visualization with optional dashed lines
  - Size attenuation based on depth
  - Glow effects with customizable intensity
- **Enhanced Points**: Points now support tilt effect based on surface angle (Globe.GL style)
- **Improved Connection Rendering**: Great circle arc rendering with proper 3D projection
- **Atmospheric Glow**: Enhanced atmospheric effects around the globe

### 🛠 Improvements

- Smooth zoom animations with easing curves (Globe.GL style)
- Improved deceleration for rotation with natural physics-based movement
- Better error handling and automatic fallback to CPU rendering when shaders fail
- Web platform stability improvements with shader recreation on WebGL context issues
- Replaced deprecated `withOpacity` calls with `withAlpha` for better performance

### 📦 Dependencies

- Added shader assets for GPU rendering

### ⚠️ Breaking Changes

- Removed legacy `foreground_painter.dart` in favor of new `gpu_foreground_painter.dart`
- Some internal APIs have changed for the new rendering pipeline

## 1.1.0

- Added Day/Night cycle feature with animated sun position
- Support for separate day and night surface textures
- Smooth blending between day and night based on sun position
- Real-time sun position calculation based on current time
- Configurable day/night transition blend factor
- Animation controls for day/night cycle (start, stop, resume)
- Manual sun position control via longitude and latitude

## 1.0.7

- Fixed issue with point connection. Thanks to @PabloAsensio .

## 1.0.6

- Fixed issue with overlays (points/connections) drifting on vertical drag (issue #20)
- Fixed deceleration animation direction for vertical rotation
- Improved texture rendering with bilinear interpolation for smoother visuals
- Improved deceleration animation smoothness with better easing curve
- Code refactoring and performance improvements

## 1.0.5

- Fixed issue of PointConnection not showing when `animateDraw = false`
- Fixed issue with FlutterEarthGlobeController not disposing correctly.

## 1.0.4

- Added ability to change the curve of a connection
- Fixed issue with zoom in smaller screen sizes
- Fixed known issues

## 1.0.3

- Added ability to enable/disable zoom
- Added ability to focus on specific coordinates
- Fixed issue with zoom not behaving correctly
- Fixed issue with alignment

## 1.0.2

- Added more listeners and callbacks
- Improved overall usage of controller
  
## 1.0.1

- Minor Readme fixes

## 1.0.0

- The first oficial release
