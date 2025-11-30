import 'package:flutter/foundation.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';

/// A state management class for globe coordinates that uses ValueNotifier
/// to efficiently update only the widgets that depend on coordinate changes.
class CoordinateState {
  CoordinateState._();

  static final CoordinateState _instance = CoordinateState._();

  /// Singleton instance
  static CoordinateState get instance => _instance;

  /// Notifier for hover coordinates - only widgets listening to this will rebuild
  final ValueNotifier<GlobeCoordinates?> hoverCoordinates =
      ValueNotifier<GlobeCoordinates?>(null);

  /// Notifier for click coordinates - only widgets listening to this will rebuild
  final ValueNotifier<GlobeCoordinates?> clickCoordinates =
      ValueNotifier<GlobeCoordinates?>(null);

  /// Update hover coordinates without triggering a full widget rebuild
  void updateHoverCoordinates(GlobeCoordinates? coordinates) {
    hoverCoordinates.value = coordinates;
  }

  /// Update click coordinates without triggering a full widget rebuild
  void updateClickCoordinates(GlobeCoordinates? coordinates) {
    clickCoordinates.value = coordinates;
  }

  /// Reset both coordinates
  void reset() {
    hoverCoordinates.value = null;
    clickCoordinates.value = null;
  }

  /// Dispose the notifiers (call when no longer needed)
  void dispose() {
    hoverCoordinates.dispose();
    clickCoordinates.dispose();
  }
}
