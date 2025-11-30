import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import 'package:flutter/material.dart';
import 'coordinate_state.dart';
import 'coordinates_display.dart';
import 'globe_controls_state.dart';
import 'control_widgets.dart';

void main() {
  runApp(MaterialApp(
    title: 'Flutter Earth Globe',
    theme: ThemeData(primarySwatch: Colors.blue),
    debugShowCheckedModeBanner: false,
    home: const Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  late FlutterEarthGlobeController _controller;
  final List<String> _textures = [
    'assets/2k_earth-day.jpg',
    'assets/2k_earth-night.jpg',
    'assets/2k_jupiter.jpg',
    'assets/2k_mars.jpg',
    'assets/2k_mercury.jpg',
    'assets/2k_moon.jpg',
    'assets/2k_neptune.jpg',
    'assets/2k_saturn.jpg',
    'assets/2k_stars.jpg',
    'assets/2k_sun.jpg',
    'assets/2k_uranus.jpg',
    'assets/2k_venus_surface.jpg'
  ];

  late List<Point> points;
  List<PointConnection> connections = [];

  Widget pointLabelBuilder(
      BuildContext context, Point point, bool isHovering, bool visible) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: isHovering
              ? Colors.blueAccent.withAlpha(204)
              : Colors.blueAccent.withAlpha(128),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 10,
                spreadRadius: 2)
          ]),
      child: Text(point.label ?? '',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              )),
    );
  }

  Widget connectionLabelBuilder(BuildContext context,
      PointConnection connection, bool isHovering, bool visible) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: isHovering
              ? Colors.blueAccent.withAlpha(204)
              : Colors.blueAccent.withAlpha(128),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 10,
                spreadRadius: 2)
          ]),
      child: Text(
        connection.label ?? '',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
      ),
    );
  }

  @override
  initState() {
    super.initState();

    _controller = FlutterEarthGlobeController(
      rotationSpeed: 0.05,
      minZoom: -1.5, // Allow zooming out to see the whole globe small
      maxZoom: 5,
      zoom: 0.5,
      isRotating: false,
      isBackgroundFollowingSphereRotation: true,
      background: Image.asset('assets/2k_stars.jpg').image,
      surface: Image.asset('assets/2k_earth-day.jpg').image,
      nightSurface: Image.asset('assets/2k_earth-night.jpg').image,
      isDayNightCycleEnabled: false,
      dayNightBlendFactor: 0.15,
    );

    points = [
      Point(
          id: '1',
          coordinates: const GlobeCoordinates(51.5072, 0.1276),
          label: 'London',
          style: const PointStyle(
              color: Colors.red,
              size: 6,
              altitude: 0.1,
              transitionDuration: 500)),
      Point(
          id: '2',
          coordinates: const GlobeCoordinates(40.7128, -74.0060),
          style: const PointStyle(
              color: Colors.green, altitude: 0.05, transitionDuration: 600),
          onHover: () {},
          label: 'New York'),
      Point(
          id: '3',
          coordinates: const GlobeCoordinates(35.6895, 139.6917),
          style: const PointStyle(
              color: Colors.blue, altitude: 0.15, transitionDuration: 700),
          onHover: () {},
          label: 'Tokyo'),
      Point(
          id: '4',
          isLabelVisible: false,
          onTap: () {
            Future.delayed(Duration.zero, () {
              showDialog(
                  // ignore: use_build_context_synchronously
                  context: context,
                  builder: (context) => const AlertDialog(
                        title: Text('Center'),
                        content: Text('This is the center of the globe'),
                      ));
            });
          },
          coordinates: const GlobeCoordinates(0, 0),
          style: const PointStyle(
              color: Colors.yellow, altitude: 0.0, transitionDuration: 400),
          label: 'Center'),
    ];

    connections = [
      PointConnection(
          id: '1',
          onTap: () {
            showDialog(
                context: context,
                builder: (context) => const AlertDialog(
                      title: Text('London to New York'),
                      content: Text(
                          'This is a connection between London and New York'),
                    ));
          },
          start: points[0].coordinates,
          end: points[1].coordinates,
          isMoving: true,
          labelBuilder: connectionLabelBuilder,
          isLabelVisible: false,
          curveScale: 1.2,
          style: const PointConnectionStyle(
              type: PointConnectionType.dotted,
              color: Colors.red,
              lineWidth: 2,
              dashSize: 6,
              spacing: 10,
              dashAnimateTime: 2000,
              transitionDuration: 500,
              animateOnAdd: true,
              growthAnimationDuration: 1000),
          label: 'London to New York'),
      PointConnection(
          start: points[1].coordinates,
          end: points[3].coordinates,
          isMoving: true,
          labelBuilder: connectionLabelBuilder,
          id: '2',
          style: const PointConnectionStyle(
              type: PointConnectionType.dashed,
              dashAnimateTime: 3000,
              transitionDuration: 500,
              animateOnAdd: true,
              growthAnimationDuration: 800),
          label: 'New York to Center'),
      PointConnection(
          label: 'Tokyo to Center',
          labelBuilder: connectionLabelBuilder,
          start: points[2].coordinates,
          end: points[3].coordinates,
          curveScale: 0.5,
          id: '3',
          style: const PointConnectionStyle(
              transitionDuration: 500,
              animateOnAdd: true,
              growthAnimationDuration: 1200))
    ];

    _controller.onLoaded = () {
      GlobeControlsState.instance.setSelectedSurface(_textures[0]);
    };

    // Initialize state with all points visible
    for (var point in points) {
      _controller.addPoint(point);
      GlobeControlsState.instance.addVisiblePoint(point.id);
    }

    // Initialize control states
    GlobeControlsState.instance.setZoom(_controller.zoom);
    GlobeControlsState.instance.setRotationSpeed(_controller.rotationSpeed);
    GlobeControlsState.instance
        .setDayNightBlendFactor(_controller.dayNightBlendFactor);
  }

  Widget leftSideContent() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: 220,
      child: ListView(
        shrinkWrap: true,
        children: [
          RotationControl(controller: _controller),
          RotationSpeedControl(controller: _controller),
          ZoomControl(controller: _controller),
          const DividerText(text: 'Day/Night Cycle'),
          DayNightEnableControl(controller: _controller),
          DayNightAnimateControl(controller: _controller),
          SunPositionControl(controller: _controller),
          BlendFactorControl(controller: _controller),
          RealTimeSunControl(controller: _controller),
          const DividerText(text: 'Points'),
          ...points.map((point) => PointControl(
                controller: _controller,
                point: point,
              )),
          const DividerText(text: 'Connections'),
          ...connections.map((connection) => ConnectionControl(
                controller: _controller,
                connection: connection,
              )),
          const DividerText(text: 'Satellites'),
          SatelliteControl(controller: _controller),
        ],
      ),
    );
  }

  Widget getLeftSide() {
    if (MediaQuery.of(context).size.width < 800) {
      return IconButton.filled(
          onPressed: () {
            _key.currentState?.openDrawer();
          },
          icon: const Icon(Icons.menu));
    } else {
      return leftSideContent();
    }
  }

  Widget rightSideContent() {
    return SizedBox(
      width: 220,
      height: MediaQuery.of(context).size.height - 10,
      child: TextureSelector(
        controller: _controller,
        textures: _textures,
      ),
    );
  }

  Widget getRightSide() {
    if (MediaQuery.of(context).size.width < 800) {
      return IconButton.filled(
          onPressed: () {
            _key.currentState?.openEndDrawer();
          },
          icon: const Icon(Icons.menu));
    } else {
      return rightSideContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    double radius = MediaQuery.of(context).size.width < 500
        ? ((MediaQuery.of(context).size.width / 3.8) - 20)
        : 120;
    return Scaffold(
      key: _key,
      drawerEnableOpenDragGesture: true,
      endDrawerEnableOpenDragGesture: true,
      drawer: MediaQuery.of(context).size.width < 800
          ? Container(
              color: Colors.white38,
              child: leftSideContent(),
            )
          : null,
      endDrawer: MediaQuery.of(context).size.width < 800
          ? Container(
              color: Colors.white38,
              child: rightSideContent(),
            )
          : null,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            FlutterEarthGlobe(
              onZoomChanged: (zoom) {
                // Update zoom state without setState - only control widgets rebuild
                GlobeControlsState.instance.setZoom(zoom);
              },
              onTap: (coordinates) {
                // Use CoordinateState instead of setState for better performance
                CoordinateState.instance.updateClickCoordinates(coordinates);
              },
              onHover: (coordinates) {
                // Use CoordinateState instead of setState for better performance
                CoordinateState.instance.updateHoverCoordinates(coordinates);
              },
              controller: _controller,
              radius: radius,
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue.withAlpha(128)),
              child: Text(
                'Flutter Earth Globe',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
            Positioned(top: 10, left: 10, child: getLeftSide()),
            Positioned(top: 10, right: 10, child: getRightSide()),
            const Positioned(
                bottom: 0, left: 0, right: 0, child: CoordinatesDisplay())
          ],
        ),
      ),
    );
  }
}
