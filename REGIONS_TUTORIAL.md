# Tutorial: Region Outlines & Highlights in Flutter Earth Globe

This tutorial guides you through the process of drawing, styling, and interacting with country or state boundaries on the `FlutterEarthGlobe`.

---

## 1. Installation

Add the package to your Flutter project's `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter_earth_globe: ^2.2.0  # Or link directly to the Git repository
```

Run `flutter pub get` in your terminal to fetch the package.

---

## 2. Configure GeoJSON Boundaries

To draw region outlines, you must provide a standard geographic GeoJSON dataset (containing `Polygon` or `MultiPolygon` geometries).

> **Where to get GeoJSON boundaries?**
> You can download free country outlines and state/province subdivisions at various resolutions (110m, 50m, 10m) from [Natural Earth](https://www.naturalearthdata.com/downloads/). For most mobile globes, 110m (~700 KB) or 50m (~2.5 MB) provides an ideal balance of visual detail and fast asset loading.

1. Place your `.geojson` file inside your project's assets folder (e.g., `assets/geo/countries.geojson`).
2. Declare the asset in your `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/geo/countries.geojson
   ```

---

## 3. Implementation Step-by-Step

### Step A: Initialize the Controller
In your stateful widget, initialize the `FlutterEarthGlobeController` with your desired textures:

```dart
late FlutterEarthGlobeController _controller;

@override
void initState() {
  super.initState();
  _controller = FlutterEarthGlobeController(
    rotationSpeed: 0.05,
    isRotating: true,
    zoom: 0.6,
    surface: const AssetImage('assets/textures/2k_earth-day.jpg'),
  );

  _loadRegionOutlines();
}
```

### Step B: Load the Boundaries
Load the GeoJSON string from your assets, decode it, and pass it to the controller. You can specify default styles and hide boundaries initially:

```dart
Future<void> _loadRegionOutlines() async {
  try {
    // 1. Read and decode the GeoJSON asset
    final jsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/geo/countries.geojson');
    final Map<String, dynamic> geojson = jsonDecode(jsonString);

    // 2. Load into the controller
    _controller.loadRegionDataset(
      geojson,
      defaultBorderColor: Colors.white70,
      defaultBorderWidth: 0.5,
      defaultFillColor: Colors.transparent,
      defaultIsVisible: false, // Start hidden to load in the background
      clipAgainstBuilder: (id) {
        // Optional: Clip specific overlapping borders (e.g., Pakistan/China against India)
        if (id.startsWith('PAK') || id.startsWith('CHN')) {
          return ['IND'];
        }
        return [];
      },
    );

    // 3. Make specific countries/states visible and styled
    _controller.showRegions(['IND', 'USA', 'BRA']);

    _controller.updateRegionStyle(
      'IND',
      borderColor: Colors.orangeAccent,
      borderWidth: 1.2,
      fillColor: Colors.deepOrange.withOpacity(0.4),
    );

  } catch (e) {
    print('Failed to load boundaries: $e');
  }
}
```

### Step C: Build the Widget
Embed the `FlutterEarthGlobe` in your widget tree:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: FlutterEarthGlobe(
        controller: _controller,
        radius: 150,
      ),
    ),
  );
}
```

---

## 4. API Reference: Region Methods

All region-related operations are controlled using the `FlutterEarthGlobeController`:

| Method Name | Return Type | Arguments | Description |
|:---|:---|:---|:---|
| **`loadRegionDataset`** | `void` | `Map<String, dynamic> geojson`<br>• `defaultBorderColor`<br>• `defaultBorderWidth`<br>• `defaultFillColor`<br>• `defaultHighlightColor`<br>• `defaultIsVisible`<br>• `clipAgainstBuilder` | Parses, caches, and optionally displays a GeoJSON boundaries dataset. Supports standard properties for IDs (like `iso_3166_2`, `code_hasc`, `code`, or `id`). |
| **`showRegions`** | `void` | `List<String> ids` | Makes the specified region IDs visible on the globe. |
| **`hideRegions`** | `void` | `List<String> ids` | Hides the specified region IDs from rendering. |
| **`showAllRegions`** | `void` | None | Shows all loaded region boundaries. |
| **`hideAllRegions`** | `void` | None | Hides all loaded region boundaries. |
| **`updateRegionStyle`** | `void` | `String id`<br>• `borderColor`<br>• `borderWidth`<br>• `fillColor`<br>• `highlightColor`<br>• `isVisible`<br>• `clipAgainst` | Dynamically updates colors, border width, visibility, or clipping targets for a specific region. |
| **`selectRegions`** | `void` | `List<String> ids` | Highlights a set of regions programmatically (applies `highlightColor`). |
| **`clearRegions`** | `void` | None | Clears all loaded regions and boundaries from memory. |

---

## 5. Interactions & Gesture Listeners

You can capture clicks or hover events on specific boundaries. Set these listeners on the controller:

### Taps / Click Gestures
```dart
_controller.onRegionTap = (GlobeRegion region) {
  print('Tapped: ${region.name} (${region.id})');
  
  // Highlight the tapped region
  _controller.selectRegions([region.id]);
};
```

### Hover / Mouse Movement Gestures
```dart
_controller.onRegionHover = (GlobeRegion region) {
  print('Hovering over: ${region.name}');
};
```
