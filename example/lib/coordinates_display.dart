import 'package:flutter/material.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'coordinate_state.dart';

/// A widget that displays hover coordinates and only rebuilds when hover coordinates change.
class HoverCoordinatesCard extends StatelessWidget {
  const HoverCoordinatesCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ValueListenableBuilder<GlobeCoordinates?>(
            valueListenable: CoordinateState.instance.hoverCoordinates,
            builder: (context, coordinates, child) {
              return Column(
                children: [
                  Text(
                    'Hover coordinates',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                      'Latitude: ${coordinates?.latitude.toStringAsFixed(4) ?? 0}'),
                  Text(
                      'Longitude: ${coordinates?.longitude.toStringAsFixed(4) ?? 0}'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A widget that displays click coordinates and only rebuilds when click coordinates change.
class ClickCoordinatesCard extends StatelessWidget {
  const ClickCoordinatesCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ValueListenableBuilder<GlobeCoordinates?>(
            valueListenable: CoordinateState.instance.clickCoordinates,
            builder: (context, coordinates, child) {
              return Column(
                children: [
                  Text(
                    'Click coordinates',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                      'Latitude: ${coordinates?.latitude.toStringAsFixed(4) ?? 0}'),
                  Text(
                      'Longitude: ${coordinates?.longitude.toStringAsFixed(4) ?? 0}'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A combined widget that shows both hover and click coordinates.
class CoordinatesDisplay extends StatelessWidget {
  const CoordinatesDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      children: [
        HoverCoordinatesCard(),
        ClickCoordinatesCard(),
      ],
    );
  }
}
