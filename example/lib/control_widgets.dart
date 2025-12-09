import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/misc.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/sphere_style.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'globe_controls_state.dart';

/// Rotation control widget - only rebuilds when rotation state changes
class RotationControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const RotationControl({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobeControlsState.instance.isRotating,
      builder: (context, isRotating, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Rotate'),
                const SizedBox(width: 10),
                Switch(
                  value: isRotating,
                  onChanged: (value) {
                    if (value) {
                      controller.startRotation();
                    } else {
                      controller.stopRotation();
                    }
                    GlobeControlsState.instance.setRotating(value);
                  },
                ),
                IconButton(
                  onPressed: () {
                    controller.resetRotation();
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Rotation speed control widget
class RotationSpeedControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const RotationSpeedControl({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobeControlsState.instance.isRotating,
      builder: (context, isRotating, child) {
        return ValueListenableBuilder<double>(
          valueListenable: GlobeControlsState.instance.rotationSpeed,
          builder: (context, speed, child) {
            return Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Rotation speed'),
                        SizedBox(width: 10),
                      ],
                    ),
                    Slider(
                      value: speed,
                      min: 0.0,
                      max: 0.2,
                      onChanged: isRotating
                          ? (value) {
                              controller.rotationSpeed = value;
                              GlobeControlsState.instance
                                  .setRotationSpeed(value);
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Zoom control widget
class ZoomControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const ZoomControl({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: GlobeControlsState.instance.zoom,
      builder: (context, zoom, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Zoom'),
                    SizedBox(width: 10),
                  ],
                ),
                Slider(
                  min: controller.minZoom,
                  max: controller.maxZoom,
                  value: zoom.clamp(controller.minZoom, controller.maxZoom),
                  divisions: 8,
                  onChanged: (value) {
                    controller.setZoom(value);
                    GlobeControlsState.instance.setZoom(value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Day/Night cycle enable control
class DayNightEnableControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const DayNightEnableControl({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobeControlsState.instance.isDayNightCycleEnabled,
      builder: (context, isEnabled, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enable'),
                const SizedBox(width: 10),
                Switch(
                  value: isEnabled,
                  onChanged: (value) {
                    controller.setDayNightCycleEnabled(value);
                    GlobeControlsState.instance.setDayNightCycleEnabled(value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Day/Night mode control (texture swap vs simulated)
class DayNightModeControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const DayNightModeControl({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobeControlsState.instance.isDayNightCycleEnabled,
      builder: (context, isEnabled, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: GlobeControlsState.instance.isSimulatedNightMode,
          builder: (context, isSimulated, child) {
            return Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Night Mode'),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ChoiceChip(
                          label: const Text('Texture',
                              style: TextStyle(fontSize: 11)),
                          selected: !isSimulated,
                          onSelected: isEnabled
                              ? (value) {
                                  if (value) {
                                    controller.dayNightMode =
                                        DayNightMode.textureSwap;
                                    GlobeControlsState.instance
                                        .setSimulatedNightMode(false);
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(width: 4),
                        ChoiceChip(
                          label: const Text('Simulated',
                              style: TextStyle(fontSize: 11)),
                          selected: isSimulated,
                          onSelected: isEnabled
                              ? (value) {
                                  if (value) {
                                    controller.dayNightMode =
                                        DayNightMode.simulated;
                                    GlobeControlsState.instance
                                        .setSimulatedNightMode(true);
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Simulated night color control widget
class SimulatedNightColorControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const SimulatedNightColorControl({Key? key, required this.controller})
      : super(key: key);

  static const List<Color> _presetColors = [
    Color.fromARGB(255, 25, 38, 64), // Default dark blue
    Color.fromARGB(255, 10, 15, 30), // Very dark blue
    Color.fromARGB(255, 40, 20, 60), // Purple night
    Color.fromARGB(255, 60, 30, 20), // Mars-like red
    Color.fromARGB(255, 20, 40, 30), // Green tint
    Color.fromARGB(255, 50, 40, 30), // Warm sepia
    Color.fromARGB(255, 30, 30, 30), // Neutral gray
    Color.fromARGB(255, 0, 0, 0), // Pure black
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobeControlsState.instance.isDayNightCycleEnabled,
      builder: (context, isEnabled, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: GlobeControlsState.instance.isSimulatedNightMode,
          builder: (context, isSimulated, child) {
            return ValueListenableBuilder<Color>(
              valueListenable: GlobeControlsState.instance.simulatedNightColor,
              builder: (context, currentColor, child) {
                final isActive = isEnabled && isSimulated;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Night Tint Color',
                          style: TextStyle(
                            color: isActive ? null : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: _presetColors.map((color) {
                            final isSelected =
                                currentColor.value == color.value;
                            return GestureDetector(
                              onTap: isActive
                                  ? () {
                                      controller.simulatedNightColor = color;
                                      GlobeControlsState.instance
                                          .setSimulatedNightColor(color);
                                    }
                                  : null,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected ? Colors.white : Colors.grey,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Simulated night intensity control widget
class SimulatedNightIntensityControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const SimulatedNightIntensityControl({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobeControlsState.instance.isDayNightCycleEnabled,
      builder: (context, isEnabled, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: GlobeControlsState.instance.isSimulatedNightMode,
          builder: (context, isSimulated, child) {
            return ValueListenableBuilder<double>(
              valueListenable:
                  GlobeControlsState.instance.simulatedNightIntensity,
              builder: (context, intensity, child) {
                final isActive = isEnabled && isSimulated;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Night Brightness',
                              style: TextStyle(
                                color: isActive ? null : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(intensity * 100).round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isActive ? Colors.grey : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: intensity,
                          min: 0.0,
                          max: 0.5,
                          divisions: 10,
                          onChanged: isActive
                              ? (value) {
                                  controller.simulatedNightIntensity = value;
                                  GlobeControlsState.instance
                                      .setSimulatedNightIntensity(value);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Day/Night animation control
class DayNightAnimateControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const DayNightAnimateControl({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobeControlsState.instance.isDayNightCycleEnabled,
      builder: (context, isEnabled, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: GlobeControlsState.instance.isDayNightAnimating,
          builder: (context, isAnimating, child) {
            return Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Animate'),
                    const SizedBox(width: 10),
                    Switch(
                      value: isAnimating,
                      onChanged: isEnabled
                          ? (value) {
                              if (value) {
                                controller.startDayNightCycle(
                                    cycleDuration: const Duration(seconds: 30),
                                    direction:
                                        DayNightCycleDirection.rightToLeft);
                              } else {
                                controller.stopDayNightCycle();
                              }
                              GlobeControlsState.instance
                                  .setDayNightAnimating(value);
                            }
                          : null,
                    ),
                    IconButton(
                      onPressed: isEnabled
                          ? () {
                              controller.stopDayNightCycle();
                              controller.setSunPosition(
                                  longitude: 0, latitude: 0);
                              GlobeControlsState.instance.setSunLongitude(0);
                              GlobeControlsState.instance.setSunLatitude(0);
                              if (isAnimating) {
                                controller.startDayNightCycle(
                                    cycleDuration: const Duration(seconds: 30));
                              }
                            }
                          : null,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Sun position control
class SunPositionControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const SunPositionControl({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobeControlsState.instance.isDayNightCycleEnabled,
      builder: (context, isEnabled, child) {
        return ValueListenableBuilder<double>(
          valueListenable: GlobeControlsState.instance.sunLongitude,
          builder: (context, longitude, child) {
            return ValueListenableBuilder<double>(
              valueListenable: GlobeControlsState.instance.sunLatitude,
              builder: (context, latitude, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Sun Position'),
                            SizedBox(width: 10),
                          ],
                        ),
                        Text('Longitude: ${longitude.toStringAsFixed(1)}°'),
                        Slider(
                          min: -180,
                          max: 180,
                          value: longitude.clamp(-180.0, 180.0),
                          onChanged: isEnabled
                              ? (value) {
                                  controller.setSunPosition(longitude: value);
                                  GlobeControlsState.instance
                                      .setSunLongitude(value);
                                }
                              : null,
                        ),
                        Text('Latitude: ${latitude.toStringAsFixed(1)}°'),
                        Slider(
                          min: -23.5,
                          max: 23.5,
                          value: latitude.clamp(-23.5, 23.5),
                          onChanged: isEnabled
                              ? (value) {
                                  controller.setSunPosition(latitude: value);
                                  GlobeControlsState.instance
                                      .setSunLatitude(value);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Blend factor control
class BlendFactorControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const BlendFactorControl({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobeControlsState.instance.isDayNightCycleEnabled,
      builder: (context, isEnabled, child) {
        return ValueListenableBuilder<double>(
          valueListenable: GlobeControlsState.instance.dayNightBlendFactor,
          builder: (context, blendFactor, child) {
            return Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Blend Factor'),
                        SizedBox(width: 10),
                      ],
                    ),
                    Slider(
                      min: 0.05,
                      max: 0.5,
                      value: blendFactor.clamp(0.05, 0.5),
                      onChanged: isEnabled
                          ? (value) {
                              controller.setDayNightBlendFactor(value);
                              GlobeControlsState.instance
                                  .setDayNightBlendFactor(value);
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Real time sun position control
class RealTimeSunControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const RealTimeSunControl({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: GlobeControlsState.instance.isDayNightCycleEnabled,
      builder: (context, isEnabled, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: GlobeControlsState.instance.useRealTimeSunPosition,
          builder: (context, useRealTime, child) {
            return Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Real Time Sun'),
                    const SizedBox(width: 10),
                    Switch(
                      value: useRealTime,
                      onChanged: isEnabled
                          ? (value) {
                              controller.setUseRealTimeSunPosition(value);
                              GlobeControlsState.instance
                                  .setUseRealTimeSunPosition(value);
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Point control widget
class PointControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;
  final Point point;

  const PointControl({
    Key? key,
    required this.controller,
    required this.point,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: GlobeControlsState.instance.visiblePoints,
      builder: (context, visiblePoints, child) {
        final isVisible = visiblePoints.contains(point.id);
        return ValueListenableBuilder<Map<String, double>>(
          valueListenable: GlobeControlsState.instance.pointSizes,
          builder: (context, pointSizes, child) {
            final currentSize = pointSizes[point.id] ?? point.style.size;
            return Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(point.label ?? ''),
                        const SizedBox(width: 10),
                        Checkbox(
                          value: isVisible,
                          onChanged: (value) {
                            if (value == true) {
                              controller.addPoint(point);
                              GlobeControlsState.instance
                                  .addVisiblePoint(point.id);
                            } else {
                              controller.removePoint(point.id);
                              GlobeControlsState.instance
                                  .removeVisiblePoint(point.id);
                            }
                          },
                        ),
                        IconButton(
                          onPressed: () {
                            controller.focusOnCoordinates(point.coordinates,
                                animate: true);
                          },
                          icon: const Icon(Icons.location_on),
                        ),
                      ],
                    ),
                    if (isVisible)
                      Slider(
                        value: currentSize / 30,
                        onChanged: (value) {
                          final newSize = value * 30;
                          controller.updatePoint(point.id,
                              style: point.style.copyWith(size: newSize));
                          point.style = point.style.copyWith(size: newSize);
                          GlobeControlsState.instance
                              .setPointSize(point.id, newSize);
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Connection control widget
class ConnectionControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;
  final PointConnection connection;

  const ConnectionControl({
    Key? key,
    required this.controller,
    required this.connection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: GlobeControlsState.instance.visibleConnections,
      builder: (context, visibleConnections, child) {
        final isVisible = visibleConnections.contains(connection.id);
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(connection.label ?? ''),
                const SizedBox(width: 10),
                Checkbox(
                  value: isVisible,
                  onChanged: (value) {
                    if (value == true) {
                      controller.addPointConnection(connection,
                          animateDraw: true);
                      GlobeControlsState.instance
                          .addVisibleConnection(connection.id);
                    } else {
                      controller.removePointConnection(connection.id);
                      GlobeControlsState.instance
                          .removeVisibleConnection(connection.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Texture selection widget
class TextureSelector extends StatelessWidget {
  final FlutterEarthGlobeController controller;
  final List<String> textures;

  const TextureSelector({
    Key? key,
    required this.controller,
    required this.textures,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: GlobeControlsState.instance.selectedSurface,
      builder: (context, selectedSurface, child) {
        return ListView(
          shrinkWrap: true,
          children: textures
              .map((texture) => Card(
                    clipBehavior: Clip.hardEdge,
                    color: selectedSurface == texture
                        ? Colors.cyan.withAlpha(128)
                        : Colors.white.withAlpha(128),
                    child: InkWell(
                      onTap: () {
                        controller.loadSurface(Image.asset(texture).image);

                        if (texture.contains('sun') ||
                            texture.contains('venus') ||
                            texture.contains('mars')) {
                          controller.setSphereStyle(SphereStyle(
                              shadowColor: Colors.orange.withAlpha(204),
                              shadowBlurSigma: 20));
                        } else {
                          controller.setSphereStyle(const SphereStyle());
                        }
                        GlobeControlsState.instance.setSelectedSurface(texture);
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
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(texture
                              .replaceFirst('assets/', '')
                              .split('.')[0]
                              .replaceAll('_', ' ')
                              .split(' ')[1]
                              .toUpperCase()),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

/// Divider text widget
class DividerText extends StatelessWidget {
  final String text;

  const DividerText({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
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
  }
}

/// Satellite control widget for adding and managing satellites
class SatelliteControl extends StatefulWidget {
  final FlutterEarthGlobeController controller;

  const SatelliteControl({Key? key, required this.controller})
      : super(key: key);

  @override
  State<SatelliteControl> createState() => _SatelliteControlState();
}

class _SatelliteControlState extends State<SatelliteControl> {
  int _satelliteCounter = 100;
  final math.Random _random = math.Random();
  SatelliteShape? _selectedShape;
  Color _selectedColor = Colors.cyan;
  double _selectedSize = 3.0;

  static const List<Color> _colors = [
    Colors.white,
    Colors.cyan,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.pink,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  String _getColorName(Color color) {
    if (color == Colors.white) return 'White';
    if (color == Colors.cyan) return 'Cyan';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.green) return 'Green';
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.red) return 'Red';
    if (color == Colors.teal) return 'Teal';
    return 'Unknown';
  }

  String _getShapeName(SatelliteShape shape) {
    switch (shape) {
      case SatelliteShape.circle:
        return '● Circle';
      case SatelliteShape.square:
        return '■ Square';
      case SatelliteShape.triangle:
        return '▲ Triangle';
      case SatelliteShape.star:
        return '★ Star';
      case SatelliteShape.satelliteIcon:
        return '🛰 Satellite';
    }
  }

  void _addRandomSatellites(int count) {
    setState(() {
      const shapes = SatelliteShape.values;

      for (int i = 0; i < count; i++) {
        final inclination = _random.nextDouble() * 90;
        final raan = _random.nextDouble() * 360;
        final periodSeconds = 10 + _random.nextDouble() * 40;
        final altitude = 0.05 + _random.nextDouble() * 0.5;

        final orbit = SatelliteOrbit(
          inclination: inclination,
          raan: raan,
          period: Duration(seconds: periodSeconds.round()),
          initialPhase: _random.nextDouble() * 360,
          eccentricity: _random.nextDouble() * 0.1,
        );

        final shape = _selectedShape ?? shapes[_random.nextInt(shapes.length)];

        widget.controller.addSatellite(Satellite(
          id: 'random-sat-${_satelliteCounter++}',
          coordinates: const GlobeCoordinates(0, 0),
          orbit: orbit,
          altitude: altitude,
          style: SatelliteStyle(
            size: _selectedSize,
            color: _selectedColor,
            shape: shape,
            hasGlow: true,
            glowColor: _selectedColor,
            glowIntensity: 0.5,
          ),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Count: ${widget.controller.satellites.length}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Shape selector dropdown
            Row(
              children: [
                const Text('Shape: ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: DropdownButton<SatelliteShape?>(
                    value: _selectedShape,
                    isExpanded: true,
                    isDense: true,
                    hint: const Text('Random', style: TextStyle(fontSize: 12)),
                    items: [
                      const DropdownMenuItem<SatelliteShape?>(
                        value: null,
                        child: Text('Random', style: TextStyle(fontSize: 12)),
                      ),
                      ...SatelliteShape.values.map((shape) => DropdownMenuItem(
                            value: shape,
                            child: Text(
                              _getShapeName(shape),
                              style: const TextStyle(fontSize: 12),
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedShape = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Color selector dropdown
            Row(
              children: [
                const Text('Color: ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: DropdownButton<Color>(
                    value: _selectedColor,
                    isExpanded: true,
                    isDense: true,
                    items: _colors
                        .map((color) => DropdownMenuItem(
                              value: color,
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getColorName(color),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedColor = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Size selector
            Row(
              children: [
                const Text('Size: ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _selectedSize,
                    min: 1.0,
                    max: 8.0,
                    divisions: 14,
                    label: _selectedSize.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _selectedSize = value;
                      });
                    },
                  ),
                ),
                Text(
                  _selectedSize.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addRandomSatellites(1),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+1', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addRandomSatellites(10),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+10', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addRandomSatellites(50),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+50', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addRandomSatellites(100),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+100', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  widget.controller.clearSatellites();
                });
              },
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Clear All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Atmosphere color control widget
class AtmosphereColorControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const AtmosphereColorControl({Key? key, required this.controller})
      : super(key: key);

  static const List<Color> _presetColors = [
    Color.fromARGB(255, 57, 123, 185), // Default blue
    Colors.blue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.pink,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: GlobeControlsState.instance.atmosphereColor,
      builder: (context, currentColor, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Glow Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _presetColors.map((color) {
                    final isSelected = currentColor.value == color.value;
                    return GestureDetector(
                      onTap: () {
                        controller.atmosphereColor = color;
                        GlobeControlsState.instance.setAtmosphereColor(color);
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Atmosphere opacity/intensity control widget
class AtmosphereOpacityControl extends StatelessWidget {
  final FlutterEarthGlobeController controller;

  const AtmosphereOpacityControl({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: GlobeControlsState.instance.atmosphereOpacity,
      builder: (context, opacity, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Glow Intensity'),
                    const SizedBox(width: 8),
                    Text(
                      '${(opacity * 100).round()}%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Slider(
                  value: opacity,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  onChanged: (value) {
                    controller.atmosphereOpacity = value;
                    GlobeControlsState.instance.setAtmosphereOpacity(value);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
