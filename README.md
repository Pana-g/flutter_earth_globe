
# Flutter Earth Globe

## Overview

Flutter Earth Globe is an interactive 3D sphere widget for Flutter applications. This widget is designed to be easy to use and highly customizable, making it ideal for any application that requires a visually appealing representation of a planet. This package was inspired by [Globe.GL](https://globe.gl/) and [Sphere](https://pub.dev/packages/sphere).

# [Live Demo](https://pana-g.github.io/flutter_earth_globe/)

<img alt="image" src="https://raw.githubusercontent.com/Pana-g/flutter_earth_globe/master/screenshots/Screenshot%20at%202024-02-04%2001-23-25.png" width="350">

<img alt="image" src="https://raw.githubusercontent.com/Pana-g/flutter_earth_globe/master/screenshots/Screenshot%20at%202024-02-04%2001-24-03.png" width="350">

<img alt="image" src="https://raw.githubusercontent.com/Pana-g/flutter_earth_globe/master/screenshots/Screenshot%20at%202024-02-04%2001-24-21.png" width="350">

<img alt="image" src="https://raw.githubusercontent.com/Pana-g/flutter_earth_globe/master/screenshots/Screenshot%20at%202024-02-04%2001-24-34.png" width="350">

## Features

- **3D Interactive Globe**: A realistic and interactive 3D model of the Earth.
- **Customizable Appearance**: Options to customize the appearance of the globe including colors, textures, and more.
- **Zoom and Rotation**: Users can interact with the globe through zoom and rotation gestures.
- **Point Support**: Ability to place customizable points on the globe.
- **Connections Support**: Ability to create connections between different coordinates.
- **Custom Labels Support**: Ability to create custom widget labels for a **point** or **connection**.
  
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

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Earth Globe Example'),
        ),
        body: SafeArea(
        child: FlutterEarthGlobe(
              controller: controller,
              radius: (MediaQuery.of(context).size.width >
                          MediaQuery.of(context).size.height
                      ? MediaQuery.of(context).size.height / 3.8
                      : MediaQuery.of(context).size.width / 3.8) -
                  40,
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
            print('EEEEEEEEE Tokyo');
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
      controller.addPoint(point);
    }
```
#### Load a background image that follows the rotation of the sphere and a sphere surface texture image
```dart
@override
initState(){
    controller.onLoaded = () {
        controller.loadBackground(Image.asset('assets/2k_stars.jpg').image,
            followsRotation: true);
        controller.loadSurface(Image.asset('assets/2k_earth-day.jpg',).image,
        );
    };

    super.initState();
}
```

#### Change the 

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
