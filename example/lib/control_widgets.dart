import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/sphere_style.dart';
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
                        ? Colors.cyan.withOpacity(0.5)
                        : Colors.white.withOpacity(0.5),
                    child: InkWell(
                      onTap: () {
                        controller.loadSurface(Image.asset(texture).image);

                        if (texture.contains('sun') ||
                            texture.contains('venus') ||
                            texture.contains('mars')) {
                          controller.setSphereStyle(SphereStyle(
                              shadowColor: Colors.orange.withOpacity(0.8),
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
