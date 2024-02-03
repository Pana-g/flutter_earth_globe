import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import 'package:flutter_earth_globe/rotating_globe_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/sphere_style.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _key = GlobalKey(); // Create a key
  String? _selectedSurface;
  RotatingGlobeController controller = RotatingGlobeController();
  List<String> textures = [
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
      child: Text(
        point.label ?? '',
        style: Theme.of(context).textTheme.titleMedium,
      ),
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
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  @override
  initState() {
    points = [
      Point(
          id: '1',
          coordinates: const GlobeCoordinates(51.5072, 0.1276),
          label: 'London',
          labelBuilder: pointLabelBuilder,
          style: const PointStyle(color: Colors.red, size: 6)),
      Point(
          id: '2',
          // showTitleOnHover: true,
          labelBuilder: pointLabelBuilder,
          coordinates: const GlobeCoordinates(40.7128, -74.0060),
          style: const PointStyle(color: Colors.green),
          onHover: () {},
          label: 'New York'),
      Point(
          id: '3',
          labelBuilder: pointLabelBuilder,
          coordinates: const GlobeCoordinates(35.6895, 139.6917),
          style: const PointStyle(color: Colors.blue),
          onHover: () {
            // print('EEEEEEEEE tokyo');
          },
          label: 'Tokyo'),
      Point(
          id: '4',
          isLabelVisible: true,
          labelBuilder: pointLabelBuilder,
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
          id: '3')
    ];
    controller.onLoaded = () {
      controller.loadBackground(Image.asset('assets/2k_stars.jpg').image,
          followsRotation: true);
      controller.loadSurface(
        Image.asset(
          textures[0],
          // filterQuality: FilterQuality.medium,
        ).image,
      );
      setState(() {
        _selectedSurface = textures[0];
      });
    };

    for (var point in points) {
      controller.addPoint(point);
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
        children: textures
            .map((texture) => Card(
                  clipBehavior: Clip.hardEdge,
                  color: _selectedSurface == texture
                      ? Colors.cyan.withOpacity(0.5)
                      : Colors.white.withOpacity(0.5),
                  child: InkWell(
                    onTap: () {
                      controller.loadSurface(Image.asset(
                        texture,
                      ).image);

                      if (texture.contains('sun') ||
                          texture.contains('venus') ||
                          texture.contains('mars')) {
                        controller.changeSphereStyle(SphereStyle(
                            shadowColor: Colors.orange.withOpacity(0.8),
                            shadowBlurSigma: 20));
                      } else {
                        controller.changeSphereStyle(SphereStyle());
                      }
                      setState(() {
                        _selectedSurface = texture;
                      });
                      // controller.changeSurface(textures[i]);
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
                      value: controller.isRotating,
                      onChanged: (value) {
                        if (value) {
                          controller.startRotation();
                        } else {
                          controller.stopRotation();
                        }
                        setState(() {});
                      }),
                  IconButton(
                      onPressed: () {
                        controller.resetRotation();
                      },
                      icon: const Icon(Icons.refresh)),
                ],
              )),
          getDividerText('Points'),
          ...points
              .map((e) => getListAction(
                  e.label ?? '',
                  Checkbox(
                    value: controller.points
                        .where((element) => element.id == e.id)
                        .isNotEmpty,
                    onChanged: (value) {
                      if (value == true) {
                        controller.addPoint(e);
                      } else {
                        controller.removePoint(e.id);
                      }
                      setState(() {});
                    },
                  ),
                  secondary: controller.points
                          .where((element) => element.id == e.id)
                          .isNotEmpty
                      ? Row(
                          children: [
                            Slider(
                                value: e.style.size / 30,
                                onChanged: (value) {
                                  value = value * 30;
                                  controller.updatePoint(e.id,
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
                    value: controller.connections
                        .where((element) => element.id == e.id)
                        .isNotEmpty,
                    onChanged: (value) {
                      if (value == true) {
                        controller.addPointConnection(e, animateDraw: true);
                      } else {
                        controller.removePointConnection(e.id);
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
          children: [
            FlutterEarthGlobe(
              controller: controller,
              radius: 120,
            ),
            Positioned(top: 10, left: 10, child: getLeftSide()),
            Positioned(top: 10, right: 10, child: getRightSide()),
          ],
        ),
      ),
    );
  }
}
