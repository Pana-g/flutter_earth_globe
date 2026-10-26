## 2.2.2

### ⚠️ Requirements

- The minimum supported versions are now **Dart 3.6** and **Flutter 3.27**. The package already used APIs from these versions (`Color.withValues`, `Color.r/g/b`), so older SDKs could resolve it but not compile it.
- Removed the unused `http` dependency.

### ✨ Features

- Added region rendering support with customizable border styles, fill colours, highlights, and tap/hover hit-testing (#40).
- Support for GeoJSON polygon and multipolygon parsing with inner ring holes and clipping mask boundaries (#40).

### 🐛 Bug Fixes

- `updatePoint()` and `updatePointConnection()` now actually apply the update. Previously they created the updated copy and discarded it.
- `loadBackground(isBackgroundFollowingSphereRotation: ...)` now stores the flag instead of ignoring it.
- Setting `controller.isRotating` now starts or stops the rotation. Previously the setter did nothing.
- `setZoom()` clamps values outside `minZoom`..`maxZoom` instead of asserting in debug and ignoring them in release.
- Calling `startRotation()`, `stopRotation()`, `toggleRotation()` or `resetRotation()` before the globe is mounted or after it unmounts no longer throws (#27). The rotation state is kept and applied when a globe mounts.
- A controller can be reused by a new globe, or swapped on an existing `FlutterEarthGlobe`, without errors.
- `FlutterEarthGlobeController.dispose()` no longer throws when the globe has already been removed, or was never built (#15, #43).
- Connections added with `animateDraw: true` no longer leak an `AnimationController`, and removing the globe mid-animation no longer throws.
- Image loads no longer race: a slower, older `loadSurface`/`loadNightSurface`/`loadBackground` cannot overwrite a newer one, `removeBackground()` wins over a pending load, loads finishing after `dispose()` are ignored, and load errors are reported through `FlutterError` instead of being thrown unhandled.
- `setUseRealTimeSunPosition(true)` now starts tracking the sun even when called after the globe is built.
- Grabbing the globe mid-fling no longer snaps it back for a frame (#41, part of #33).
- Point labels are placed for the current frame's rotation instead of trailing one frame behind (#42).
- A globe without a background now receives gestures under loose constraints (#44).

### ⚡ Performance

- The animation ticker for moving connections and orbiting satellites stops when nothing is animating, so an idle globe no longer renders every frame.
- Real-time sun tracking updates once a minute instead of on every frame.
- Satellite transition and orbit-path caches are cleaned up when satellites are removed.

### 📚 Docs

- Fixed README atmosphere example (`atmosphereColor`/`atmosphereOpacity` are properties, not `set...()` methods) and added `dispose()` to the Quick Start.
- Added a test suite and a CI workflow (analyze, format, test).

## 2.2.1

- Added `curve` parameter to `focusOnCoordinates` for more controlled and smooth animations.
- Fixed coordinate mapping issue where points on the globe were incorrectly placed or disappeared at certain rotations.

## 2.2.0

### ✨ New Features

- **Day/Night Mode Selection**: Choose between two day/night rendering modes:
  - `textureSwap`: Uses separate day/night textures for maximum visual quality
  - `simulated`: Applies a customizable color overlay, perfect for planets without dedicated night textures
- **Simulated Night Customization**: Configure the simulated night overlay with `simulatedNightColor` and `simulatedNightIntensity`
- **Atmosphere Color & Intensity**: Full control over atmosphere appearance with the `atmosphereColor` and `atmosphereOpacity` properties for planet-appropriate glows


### 🐛 Bug Fixes

- **Improved background parallax zoom**: Background (starry sky) now zooms at a reduced rate (15% of globe zoom) for a more realistic depth perception. Distant stars appear to stay in place while the globe zooms, creating a natural parallax effect.
- **Fixed hover detection**: Hover callbacks now work correctly when the globe is stationary
- **Optimized satellite rendering**: Added orbit path caching to prevent unnecessary recalculations, reducing potential flickering with many satellites
- **Improved label rendering**: Labels are now wrapped in RepaintBoundary for smoother UI performance

---

## 2.1.2

- Minor maintenance release

---

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
