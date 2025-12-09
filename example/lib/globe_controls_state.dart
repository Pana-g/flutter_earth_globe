import 'package:flutter/foundation.dart';
import 'dart:ui' show Color;

/// A state management class for globe controls that uses ValueNotifier
/// to efficiently update only the widgets that depend on specific control changes.
/// This prevents the entire globe from rebuilding when control values change.
class GlobeControlsState {
  GlobeControlsState._();

  static final GlobeControlsState _instance = GlobeControlsState._();

  /// Singleton instance
  static GlobeControlsState get instance => _instance;

  // Rotation controls
  final ValueNotifier<bool> isRotating = ValueNotifier<bool>(false);
  final ValueNotifier<double> rotationSpeed = ValueNotifier<double>(0.05);

  // Zoom control
  final ValueNotifier<double> zoom = ValueNotifier<double>(0.5);

  // Day/Night cycle controls
  final ValueNotifier<bool> isDayNightCycleEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isDayNightAnimating = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isSimulatedNightMode =
      ValueNotifier<bool>(false); // false = textureSwap, true = simulated
  final ValueNotifier<double> sunLongitude = ValueNotifier<double>(0.0);
  final ValueNotifier<double> sunLatitude = ValueNotifier<double>(0.0);
  final ValueNotifier<double> dayNightBlendFactor = ValueNotifier<double>(0.15);
  final ValueNotifier<bool> useRealTimeSunPosition = ValueNotifier<bool>(false);

  // Simulated night mode controls
  final ValueNotifier<Color> simulatedNightColor =
      ValueNotifier<Color>(const Color.fromARGB(255, 25, 38, 64));
  final ValueNotifier<double> simulatedNightIntensity =
      ValueNotifier<double>(0.15);

  // Atmosphere controls
  final ValueNotifier<Color> atmosphereColor =
      ValueNotifier<Color>(const Color.fromARGB(255, 57, 123, 185));
  final ValueNotifier<double> atmosphereOpacity = ValueNotifier<double>(0.8);

  // Surface selection
  final ValueNotifier<String?> selectedSurface = ValueNotifier<String?>(null);

  // Points visibility (map of point id to visibility)
  final ValueNotifier<Set<String>> visiblePoints =
      ValueNotifier<Set<String>>({});

  // Connections visibility (map of connection id to visibility)
  final ValueNotifier<Set<String>> visibleConnections =
      ValueNotifier<Set<String>>({});

  // Point sizes (map of point id to size)
  final ValueNotifier<Map<String, double>> pointSizes =
      ValueNotifier<Map<String, double>>({});

  /// Update rotation state
  void setRotating(bool value) {
    isRotating.value = value;
  }

  /// Update rotation speed
  void setRotationSpeed(double value) {
    rotationSpeed.value = value;
  }

  /// Update zoom level
  void setZoom(double value) {
    zoom.value = value;
  }

  /// Update day/night cycle enabled state
  void setDayNightCycleEnabled(bool value) {
    isDayNightCycleEnabled.value = value;
  }

  /// Update day/night animation state
  void setDayNightAnimating(bool value) {
    isDayNightAnimating.value = value;
  }

  /// Update simulated night mode setting
  void setSimulatedNightMode(bool value) {
    isSimulatedNightMode.value = value;
  }

  /// Update sun longitude
  void setSunLongitude(double value) {
    sunLongitude.value = value;
  }

  /// Update sun latitude
  void setSunLatitude(double value) {
    sunLatitude.value = value;
  }

  /// Update day/night blend factor
  void setDayNightBlendFactor(double value) {
    dayNightBlendFactor.value = value;
  }

  /// Update real time sun position setting
  void setUseRealTimeSunPosition(bool value) {
    useRealTimeSunPosition.value = value;
  }

  /// Update simulated night color
  void setSimulatedNightColor(Color value) {
    simulatedNightColor.value = value;
  }

  /// Update simulated night intensity
  void setSimulatedNightIntensity(double value) {
    simulatedNightIntensity.value = value;
  }

  /// Update atmosphere color
  void setAtmosphereColor(Color value) {
    atmosphereColor.value = value;
  }

  /// Update atmosphere opacity
  void setAtmosphereOpacity(double value) {
    atmosphereOpacity.value = value;
  }

  /// Update selected surface
  void setSelectedSurface(String? value) {
    selectedSurface.value = value;
  }

  /// Add a visible point
  void addVisiblePoint(String id) {
    final newSet = Set<String>.from(visiblePoints.value);
    newSet.add(id);
    visiblePoints.value = newSet;
  }

  /// Remove a visible point
  void removeVisiblePoint(String id) {
    final newSet = Set<String>.from(visiblePoints.value);
    newSet.remove(id);
    visiblePoints.value = newSet;
  }

  /// Check if a point is visible
  bool isPointVisible(String id) {
    return visiblePoints.value.contains(id);
  }

  /// Add a visible connection
  void addVisibleConnection(String id) {
    final newSet = Set<String>.from(visibleConnections.value);
    newSet.add(id);
    visibleConnections.value = newSet;
  }

  /// Remove a visible connection
  void removeVisibleConnection(String id) {
    final newSet = Set<String>.from(visibleConnections.value);
    newSet.remove(id);
    visibleConnections.value = newSet;
  }

  /// Check if a connection is visible
  bool isConnectionVisible(String id) {
    return visibleConnections.value.contains(id);
  }

  /// Update point size
  void setPointSize(String id, double size) {
    final newMap = Map<String, double>.from(pointSizes.value);
    newMap[id] = size;
    pointSizes.value = newMap;
  }

  /// Get point size
  double getPointSize(String id, double defaultSize) {
    return pointSizes.value[id] ?? defaultSize;
  }

  /// Initialize with default points
  void initializePoints(List<String> pointIds) {
    visiblePoints.value = pointIds.toSet();
  }

  /// Reset all state
  void reset() {
    isRotating.value = false;
    rotationSpeed.value = 0.05;
    zoom.value = 0.5;
    isDayNightCycleEnabled.value = false;
    isDayNightAnimating.value = false;
    isSimulatedNightMode.value = false;
    sunLongitude.value = 0.0;
    sunLatitude.value = 0.0;
    dayNightBlendFactor.value = 0.15;
    useRealTimeSunPosition.value = false;
    simulatedNightColor.value = const Color.fromARGB(255, 25, 38, 64);
    simulatedNightIntensity.value = 0.15;
    atmosphereColor.value = const Color.fromARGB(255, 57, 123, 185);
    atmosphereOpacity.value = 0.2;
    selectedSurface.value = null;
    visiblePoints.value = {};
    visibleConnections.value = {};
    pointSizes.value = {};
  }

  /// Dispose all notifiers (call when no longer needed)
  void dispose() {
    isRotating.dispose();
    rotationSpeed.dispose();
    zoom.dispose();
    isDayNightCycleEnabled.dispose();
    isDayNightAnimating.dispose();
    isSimulatedNightMode.dispose();
    sunLongitude.dispose();
    sunLatitude.dispose();
    dayNightBlendFactor.dispose();
    useRealTimeSunPosition.dispose();
    simulatedNightColor.dispose();
    simulatedNightIntensity.dispose();
    atmosphereColor.dispose();
    atmosphereOpacity.dispose();
    selectedSurface.dispose();
    visiblePoints.dispose();
    visibleConnections.dispose();
    pointSizes.dispose();
  }
}
