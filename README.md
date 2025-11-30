
# Flutter Earth Globe

## Overview

Flutter Earth Globe is an interactive 3D sphere widget for Flutter applications. This widget is designed to be easy to use and highly customizable, making it ideal for any application that requires a visually appealing representation of a planet. This package was inspired by [Globe.GL](https://globe.gl/) and [Sphere](https://pub.dev/packages/sphere).

# [Live Demo](https://pana-g.github.io/flutter_earth_globe/)

<img alt="image" src="https://raw.githubusercontent.com/Pana-g/flutter_earth_globe/master/screenshots/screenshotEarthDay.png" width="350">

<img alt="image" src="https://raw.githubusercontent.com/Pana-g/flutter_earth_globe/master/screenshots/screenshotEarthNight.png" width="350">

<img alt="Day/Night Cycle" src="https://raw.githubusercontent.com/Pana-g/flutter_earth_globe/master/screenshots/screenshotEarthDayNight.png" width="350">

<img alt="Day/Night Cycle Animation" src="https://raw.githubusercontent.com/Pana-g/flutter_earth_globe/master/screenshots/earthDayNightCycle.gif" width="350">

<img alt="Satellites" src="https://raw.githubusercontent.com/Pana-g/flutter_earth_globe/master/screenshots/earthDaySatelites.gif" width="350">

<img alt="Satellites with Day/Night Cycle" src="https://raw.githubusercontent.com/Pana-g/flutter_earth_globe/master/screenshots/earthDayNightCycleSatelites.gif" width="350">

<img alt="image" src="https://raw.githubusercontent.com/Pana-g/flutter_earth_globe/master/screenshots/screenshotMoon.png" width="350">

<img alt="image" src="https://raw.githubusercontent.com/Pana-g/flutter_earth_globe/master/screenshots/screenshotMars.png" width="350">

## Features

- **3D Interactive Globe**: A realistic and interactive 3D model of the Earth.
- **Customizable Appearance**: Options to customize the appearance of the globe including colors, textures, and more.
- **Zoom and Rotation**: Users can interact with the globe through zoom and rotation gestures.
- **Point Support**: Ability to place customizable points on the globe.
- **Connections Support**: Ability to create connections between different coordinates.
- **Custom Labels Support**: Ability to create custom widget labels for a **point** or **connection**.
- **Day/Night Cycle**: Realistic day/night cycle with smooth transitions between day and night textures based on sun position.
- **Responsive Design**: Ensures compatibility with a wide range of devices and screen sizes.

## Installation

To install Flutter Earth Globe, follow these steps:

1. Add the package to your Flutter project's `pubspec.yaml` file:

   ```yaml
   dependencies:
     flutter_earth_globe: ^[latest_version]
   ```

   or just run

   ```shell
    flutter pub add flutter_earth_globe
   ```

2. Import the package in your Dart code:

   ```dart
   import 'package:flutter_earth_globe/flutter_earth_globe.dart';
   ```

## Usage

Here is a basic example of how to integrate the Flutter Earth Globe into your Flutter app:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  late FlutterEarthGlobeController _controller;

   @override
  initState() {
    _controller = FlutterEarthGlobeController(
        rotationSpeed: 0.05,
        isBackgroundFollowingSphereRotation: true,
        background: Image.asset('assets/2k_stars.jpg').image,
        surface: Image.asset('assets/2k_earth-day.jpg').image);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Earth Globe Example'),
        ),
        body: SafeArea(
        child: FlutterEarthGlobe(
              controller: _controller,
              radius: 120,
            )
        ),
      ),
    );
  }
}
```

## Customization

#### Create a list of Points and add them to the globe

```dart
final FlutterEarthGlobeController _controller = FlutterEarthGlobeController();
List<Point> points = [
      Point(
          id: '1',
          coordinates: const GlobeCoordinates(51.5072, 0.1276),
          label: 'London',
          isLabelVisible: true,
          style: const PointStyle(color: Colors.red, size: 6)),
      Point(
          id: '2',
          isLabelVisible: true,
          coordinates: const GlobeCoordinates(40.7128, -74.0060),
          style: const PointStyle(color: Colors.green),
          onHover: () {},
          label: 'New York'),
      Point(
          id: '3',
          isLabelVisible: true,
          coordinates: const GlobeCoordinates(35.6895, 139.6917),
          style: const PointStyle(color: Colors.blue),
          onHover: () {
            print('Tokyo');
          },
          label: 'Tokyo'),
      Point(
          id: '4',
          isLabelVisible: true,
          onTap: () {
            Future.delayed(Duration.zero, () {
              showDialog(
                  context: context,
                  builder: (context) => const AlertDialog(
                        title: Text('Center'),
                        content: Text('This is the center of the globe'),
                      ));
            });
          },
          coordinates: const GlobeCoordinates(0, 0),
          style: const PointStyle(color: Colors.yellow),
          label: 'Center'),
    ];

    for (var point in points) {
      _controller.addPoint(point);
    }
```

#### Create connections between points

```dart
final FlutterEarthGlobeController _controller = FlutterEarthGlobeController();

// Add a simple solid connection
_controller.addPointConnection(PointConnection(
  id: 'connection-1',
  start: const GlobeCoordinates(51.5072, 0.1276),    // London
  end: const GlobeCoordinates(40.7128, -74.0060),    // New York
  label: 'London - New York',
  isLabelVisible: true,
  style: PointConnectionStyle(
    type: PointConnectionType.solid,
    color: Colors.cyan,
    lineWidth: 2,
  ),
));

// Add an animated dashed connection
_controller.addPointConnection(PointConnection(
  id: 'connection-2',
  start: const GlobeCoordinates(40.7128, -74.0060),  // New York
  end: const GlobeCoordinates(35.6895, 139.6917),    // Tokyo
  label: 'New York - Tokyo',
  isLabelVisible: true,
  style: PointConnectionStyle(
    type: PointConnectionType.dashed,
    color: Colors.orange,
    dashSize: 4,
    spacing: 6,
    dashAnimateTime: 2000,  // Dashes move along the arc over 2 seconds
    animateOnAdd: true,     // Arc grows when first appearing
    growthAnimationDuration: 1500,
  ),
));

// Add a dotted connection
_controller.addPointConnection(PointConnection(
  id: 'connection-3',
  start: const GlobeCoordinates(35.6895, 139.6917), // Tokyo
  end: const GlobeCoordinates(51.5072, 0.1276),     // London
  style: PointConnectionStyle(
    type: PointConnectionType.dotted,
    color: Colors.green,
    dotSize: 2,
    spacing: 4,
  ),
  curveScale: 2.0,  // Higher arc curve
  onTap: () {
    print('Connection tapped!');
  },
));
```

##### PointConnectionStyle Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `type` | `PointConnectionType` | solid | Line type: solid, dashed, or dotted |
| `color` | `Color` | white | Color of the connection line |
| `lineWidth` | `double` | 1.0 | Width of solid lines |
| `dashSize` | `double` | 4.0 | Length of dashes |
| `dotSize` | `double` | 1.0 | Size of dots |
| `spacing` | `double` | 8.0 | Space between dashes/dots |
| `dashAnimateTime` | `int` | 0 | Time (ms) for dash to travel the arc (0 = disabled) |
| `transitionDuration` | `int` | 500 | Fade in/out duration (ms) |
| `animateOnAdd` | `bool` | true | Animate arc growth when added |
| `growthAnimationDuration` | `int` | 1000 | Arc growth animation duration (ms) |

#### Load a background image that follows the rotation of the sphere and a sphere surface texture image

```dart
final FlutterEarthGlobeController _controller = FlutterEarthGlobeController();
@override
initState(){
    _controller.onLoaded = () {
        _controller.loadBackground(Image.asset('assets/2k_stars.jpg').image,
            followsRotation: true);
        _controller.loadSurface(Image.asset('assets/2k_earth-day.jpg',).image,
        );
    };

    super.initState();
}
```

#### Enable Day/Night Cycle

Create a realistic day/night effect by providing both day and night textures:

```dart
final FlutterEarthGlobeController _controller = FlutterEarthGlobeController(
    surface: Image.asset('assets/2k_earth-day.jpg').image,
    nightSurface: Image.asset('assets/2k_earth-night.jpg').image,
    isDayNightCycleEnabled: true,
    dayNightBlendFactor: 0.15, // Controls the sharpness of the day/night transition
);

// Start animated day/night cycle
_controller.startDayNightCycle(cycleDuration: Duration(seconds: 30));

// Stop the animation
_controller.stopDayNightCycle();

// Manually set sun position
_controller.setSunPosition(longitude: 45.0, latitude: 10.0);

// Use real-time sun position based on current time
_controller.setUseRealTimeSunPosition(true);
```

#### Change the style of the sphere

```dart
final FlutterEarthGlobeController _controller = FlutterEarthGlobeController();
_controller.changeSphereStyle(SphereStyle(
      shadowColor: Colors.orange.withAlpha(204),
      shadowBlurSigma: 20));
controller
```

#### Add Satellites

Add satellites to the globe with customizable styles and optional orbital animations. Inspired by [Globe.GL](https://globe.gl/).

```dart
final FlutterEarthGlobeController _controller = FlutterEarthGlobeController();

// Add a stationary (geostationary) satellite
_controller.addSatellite(Satellite(
  id: 'geo-sat-1',
  coordinates: GlobeCoordinates(0, -75.2),
  altitude: 0.35, // Height above the globe surface
  label: 'GOES-16',
  isLabelVisible: true,
  style: SatelliteStyle(
    size: 6,
    color: Colors.yellow,
    shape: SatelliteShape.circle,
    hasGlow: true,
    glowColor: Colors.yellow,
    glowIntensity: 0.5,
  ),
));

// Add an orbiting satellite (ISS-like)
_controller.addSatellite(Satellite(
  id: 'iss',
  coordinates: GlobeCoordinates(0, 0), // Starting position (used if no orbit)
  altitude: 0.06,
  label: 'ISS',
  isLabelVisible: true,
  orbit: SatelliteOrbit(
    inclination: 51.6,        // Orbital inclination in degrees
    period: Duration(seconds: 30), // Orbital period (faster for demo)
    raan: 0.0,                // Right ascension of ascending node
    initialPhase: 0.0,        // Starting phase in degrees
  ),
  style: SatelliteStyle(
    size: 8,
    color: Colors.white,
    shape: SatelliteShape.satelliteIcon,
    showOrbitPath: true,      // Show the orbital path
    orbitPathColor: Colors.white.withAlpha(77),
    orbitPathWidth: 1.0,
  ),
));
```

##### Managing Satellites

```dart
// Update an existing satellite
_controller.updateSatellite('iss',
  label: 'International Space Station',
  style: SatelliteStyle(size: 10, color: Colors.blue),
);

// Remove a satellite
_controller.removeSatellite('geo-sat-1');

// Clear all satellites
_controller.clearSatellites();
```

## Contributors

We would like to thank all the contributors who have helped make this project a success. Your contributions, big or small, make a significant impact on the development and improvement of this project.

If you would like to contribute, please feel free to fork the repository, make your changes, and submit a pull request.

### How to Contribute

1. **Fork the Repository**: Click the 'Fork' button at the top right corner of this repository.
2. **Clone Your Fork**: Clone your fork to your local machine.
3. **Create a Branch**: Create a new branch for your modifications (`git checkout -b feature/YourFeature`).
4. **Make Your Changes**: Make the necessary changes to the project.
5. **Commit Your Changes**: Commit your changes (`git commit -am 'Add some feature'`).
6. **Push to the Branch**: Push your changes to your branch (`git push origin feature/YourFeature`).
7. **Open a Pull Request**: Go to the repository on GitHub and open a pull request.

We are excited to see your contributions and are looking forward to growing this project with the community!

## Support the Library

You can also support the library by liking it on pub, staring in on Github and reporting any bugs you encounter.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
