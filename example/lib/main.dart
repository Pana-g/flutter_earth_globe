import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/sphere_style.dart';

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
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  String? _selectedSurface;
  GlobeCoordinates? _hoverCoordinates;
  GlobeCoordinates? _clickCoordinates;
  late FlutterEarthGlobeController _controller;
  bool _isDayNightAnimating = false;
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
              ? Colors.blueAccent.withOpacity(0.8)
              : Colors.blueAccent.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
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
              ? Colors.blueAccent.withOpacity(0.8)
              : Colors.blueAccent.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
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
    _controller = FlutterEarthGlobeController(
      rotationSpeed: 0.05,
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
          // labelBuilder: pointLabelBuilder,
          style: const PointStyle(color: Colors.red, size: 6)),
      Point(
          id: '2',
          // showTitleOnHover: true,
          // labelBuilder: pointLabelBuilder,
          coordinates: const GlobeCoordinates(40.7128, -74.0060),
          style: const PointStyle(color: Colors.green),
          onHover: () {},
          label: 'New York'),
      Point(
          id: '3',
          // labelBuilder: pointLabelBuilder,
          coordinates: const GlobeCoordinates(35.6895, 139.6917),
          style: const PointStyle(color: Colors.blue),
          onHover: () {},
          label: 'Tokyo'),
      Point(
          id: '4',
          isLabelVisible: false,
          // labelBuilder: pointLabelBuilder,
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
              spacing: 10),
          label: 'London to New York'),
      PointConnection(
          start: points[1].coordinates,
          end: points[3].coordinates,
          isMoving: true,
          labelBuilder: connectionLabelBuilder,
          id: '2',
          style: const PointConnectionStyle(type: PointConnectionType.dashed),
          label: 'New York to Center'),
      PointConnection(
          label: 'Tokyo to Center',
          labelBuilder: connectionLabelBuilder,
          start: points[2].coordinates,
          end: points[3].coordinates,
          curveScale: 1.6,
          id: '3')
    ];
    _controller.onLoaded = () {
      setState(() {
        _selectedSurface = _textures[0];
      });
    };

    for (var point in points) {
      _controller.addPoint(point);
    }

    super.initState();
  }

  Widget getDividerText(String text) => Card(
        child: SizedBox(
          width: 250,
          child: Row(
            children: [
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.black38,
                  height: 2,
                ),
              ),
              Text(
                text,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: Colors.black38,
                  height: 2,
                ),
              ),
            ],
          ),
        ),
      );

  getTextures() {
    return ListView(
        shrinkWrap: true,
        children: _textures
            .map((texture) => Card(
                  clipBehavior: Clip.hardEdge,
                  color: _selectedSurface == texture
                      ? Colors.cyan.withOpacity(0.5)
                      : Colors.white.withOpacity(0.5),
                  child: InkWell(
                    onTap: () {
                      _controller.loadSurface(Image.asset(
                        texture,
                      ).image);

                      if (texture.contains('sun') ||
                          texture.contains('venus') ||
                          texture.contains('mars')) {
                        _controller.setSphereStyle(SphereStyle(
                            shadowColor: Colors.orange.withOpacity(0.8),
                            shadowBlurSigma: 20));
                      } else {
                        _controller.setSphereStyle(const SphereStyle());
                      }
                      setState(() {
                        _selectedSurface = texture;
                      });
                      // _controller.changeSurface(textures[i]);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                texture,
                                width: 100,
                              ),
                            )),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(texture
                            .replaceFirst('assets/', '')
                            .split('.')[0]
                            .replaceAll('_', ' ')
                            .split(' ')[1]
                            .toUpperCase())
                      ],
                    ),
                  ),
                ))
            .toList());
  }

  Widget getListAction(String label, Widget child, {Widget? secondary}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                const SizedBox(
                  width: 10,
                ),
                child
              ],
            ),
            secondary ?? const SizedBox(),
          ],
        ),
      ),
    );
  }

  Widget leftSideContent() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: 220,
      child: ListView(
        shrinkWrap: true,
        children: [
          getListAction(
            'Rotate',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                    value: _controller.isRotating,
                    onChanged: (value) {
                      if (value) {
                        _controller.startRotation();
                      } else {
                        _controller.stopRotation();
                      }
                      setState(() {});
                    }),
                IconButton(
                    onPressed: () {
                      _controller.resetRotation();
                    },
                    icon: const Icon(Icons.refresh)),
              ],
            ),
          ),
          getListAction('Rotation speed', Container(),
              secondary: Slider(
                  value: _controller.rotationSpeed,
                  onChanged: _controller.isRotating
                      ? (value) {
                          _controller.rotationSpeed = value;
                          setState(() {});
                        }
                      : null)),
          getListAction('Zoom', Container(),
              secondary: Slider(
                  min: _controller.minZoom,
                  max: _controller.maxZoom,
                  value: _controller.zoom,
                  divisions: 8,
                  onChanged: (value) {
                    _controller.setZoom(value);
                    setState(() {});
                  })),
          getDividerText('Day/Night Cycle'),
          getListAction(
            'Enable',
            Switch(
                value: _controller.isDayNightCycleEnabled,
                onChanged: (value) {
                  _controller.setDayNightCycleEnabled(value);
                  setState(() {});
                }),
          ),
          getListAction(
            'Animate',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                    value: _isDayNightAnimating,
                    onChanged: _controller.isDayNightCycleEnabled
                        ? (value) {
                            if (value) {
                              _controller.startDayNightCycle(
                                  cycleDuration: const Duration(seconds: 30));
                              _isDayNightAnimating = true;
                            } else {
                              _controller.stopDayNightCycle();
                              _isDayNightAnimating = false;
                            }
                            setState(() {});
                          }
                        : null),
                IconButton(
                    onPressed: _controller.isDayNightCycleEnabled
                        ? () {
                            _controller.stopDayNightCycle();
                            _controller.setSunPosition(
                                longitude: 0, latitude: 0);
                            if (_isDayNightAnimating) {
                              _controller.startDayNightCycle(
                                  cycleDuration: const Duration(seconds: 30));
                            }
                            setState(() {});
                          }
                        : null,
                    icon: const Icon(Icons.refresh)),
              ],
            ),
          ),
          getListAction('Sun Position', Container(),
              secondary: Column(
                children: [
                  Text(
                      'Longitude: ${_controller.sunLongitude.toStringAsFixed(1)}°'),
                  Slider(
                      min: -180,
                      max: 180,
                      value: _controller.sunLongitude,
                      onChanged: _controller.isDayNightCycleEnabled
                          ? (value) {
                              _controller.setSunPosition(longitude: value);
                              setState(() {});
                            }
                          : null),
                  Text(
                      'Latitude: ${_controller.sunLatitude.toStringAsFixed(1)}°'),
                  Slider(
                      min: -23.5,
                      max: 23.5,
                      value: _controller.sunLatitude.clamp(-23.5, 23.5),
                      onChanged: _controller.isDayNightCycleEnabled
                          ? (value) {
                              _controller.setSunPosition(latitude: value);
                              setState(() {});
                            }
                          : null),
                ],
              )),
          getListAction('Blend Factor', Container(),
              secondary: Slider(
                  min: 0.05,
                  max: 0.5,
                  value: _controller.dayNightBlendFactor,
                  onChanged: _controller.isDayNightCycleEnabled
                      ? (value) {
                          _controller.setDayNightBlendFactor(value);
                          setState(() {});
                        }
                      : null)),
          getListAction(
            'Real Time Sun',
            Switch(
                value: _controller.useRealTimeSunPosition,
                onChanged: _controller.isDayNightCycleEnabled
                    ? (value) {
                        _controller.setUseRealTimeSunPosition(value);
                        setState(() {});
                      }
                    : null),
          ),
          getDividerText('Points'),
          ...points
              .map((e) => getListAction(
                  e.label ?? '',
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Checkbox(
                        value: _controller.points
                            .where((element) => element.id == e.id)
                            .isNotEmpty,
                        onChanged: (value) {
                          if (value == true) {
                            _controller.addPoint(e);
                          } else {
                            _controller.removePoint(e.id);
                          }
                          setState(() {});
                        },
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      IconButton(
                          onPressed: () {
                            _controller.focusOnCoordinates(e.coordinates,
                                animate: true);
                          },
                          icon: const Icon(Icons.location_on))
                    ],
                  ),
                  secondary: _controller.points
                          .where((element) => element.id == e.id)
                          .isNotEmpty
                      ? Row(
                          children: [
                            Slider(
                                value: e.style.size / 30,
                                onChanged: (value) {
                                  value = value * 30;
                                  _controller.updatePoint(e.id,
                                      style: e.style.copyWith(size: value));
                                  e.style = e.style.copyWith(size: value);
                                  setState(() {});
                                }),
                          ],
                        )
                      : null))
              .toList(),
          getDividerText('Connections'),
          ...connections
              .map((e) => getListAction(
                  e.label ?? '',
                  Checkbox(
                    value: _controller.connections
                        .where((element) => element.id == e.id)
                        .isNotEmpty,
                    onChanged: (value) {
                      if (value == true) {
                        _controller.addPointConnection(e, animateDraw: true);
                      } else {
                        _controller.removePointConnection(e.id);
                      }
                      setState(() {});
                    },
                  )))
              .toList(),
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
      child: getTextures(),
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
                setState(() {});
              },
              onTap: (coordinates) {
                setState(() {
                  _clickCoordinates = coordinates;
                });
              },
              onHover: (coordinates) {
                if (coordinates == null) return;

                setState(() {
                  _hoverCoordinates = coordinates;
                });
              },
              controller: _controller,
              radius: radius,
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.blue.withOpacity(0.5)),
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
            Positioned(
                bottom: 0,
                width: MediaQuery.of(context).size.width,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  children: [
                    SizedBox(
                      width: 250,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                'Hover coordinates',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                  'Latitude: ${_hoverCoordinates?.latitude ?? 0}'),
                              Text(
                                  'Longitude: ${_hoverCoordinates?.longitude ?? 0}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                'Click coordinates',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                  'Latitude: ${_clickCoordinates?.latitude ?? 0}'),
                              Text(
                                  'Longitude: ${_clickCoordinates?.longitude ?? 0}'),
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ))
          ],
        ),
      ),
    );
  }
}
