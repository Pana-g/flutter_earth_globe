import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/gpu_foreground_painter.dart';

void main() {
  group('FlutterEarthGlobeController - Region Operations', () {
    late FlutterEarthGlobeController controller;

    setUp(() {
      controller = FlutterEarthGlobeController();
    });

    test('initial state has empty regions and zero revision', () {
      expect(controller.regions, isEmpty);
      expect(controller.selectedRegionIds, isEmpty);
      expect(controller.regionRevision, 0);
    });

    test('loadRegionDataset parses Polygon geometries correctly', () {
      final sampleGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'id': 'TEST_COUNTRY', 'name': 'Test Country'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [0.0, 0.0],
                  [10.0, 0.0],
                  [10.0, 10.0],
                  [0.0, 10.0],
                  [0.0, 0.0],
                ]
              ]
            }
          }
        ]
      };

      controller.loadRegionDataset(
        sampleGeoJson,
        defaultBorderColor: Colors.blue,
        defaultBorderWidth: 2.0,
        defaultFillColor: Colors.green,
      );

      expect(controller.regions.length, 1);
      final region = controller.regions.first;
      expect(region.id, 'TEST_COUNTRY');
      expect(region.name, 'Test Country');
      expect(region.borderColor, Colors.blue);
      expect(region.borderWidth, 2.0);
      expect(region.fillColor, Colors.green);
      expect(region.isVisible, isTrue);
      expect(region.polygons.length, 1);
      expect(region.polygons.first.length, 1); // 1 ring (exterior boundary)
      expect(region.polygons.first.first.length, 5); // 5 points
      expect(controller.regionRevision, greaterThan(0));
    });

    test('loadRegionDataset parses MultiPolygon geometries correctly', () {
      final sampleGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'id': 'ISLAND_NATION', 'name': 'Island Nation'},
            'geometry': {
              'type': 'MultiPolygon',
              'coordinates': [
                [
                  [
                    [0.0, 0.0],
                    [1.0, 0.0],
                    [1.0, 1.0],
                    [0.0, 0.0]
                  ]
                ],
                [
                  [
                    [10.0, 10.0],
                    [11.0, 10.0],
                    [11.0, 11.0],
                    [10.0, 10.0]
                  ]
                ]
              ]
            }
          }
        ]
      };

      controller.loadRegionDataset(sampleGeoJson);

      expect(controller.regions.length, 1);
      final region = controller.regions.first;
      expect(region.id, 'ISLAND_NATION');
      expect(region.polygons.length, 2);
    });

    test('loadRegionDataset resolves alternative ID and Name keys', () {
      final sampleGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {
              'iso_3166_2': 'US-CA',
              'name_en': 'California',
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [0.0, 0.0],
                  [1.0, 0.0],
                  [1.0, 1.0],
                  [0.0, 0.0]
                ]
              ]
            }
          },
          {
            'type': 'Feature',
            'properties': {
              'code_hasc': 'IN.DL',
              'title': 'Delhi',
            },
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [0.0, 0.0],
                  [1.0, 0.0],
                  [1.0, 1.0],
                  [0.0, 0.0]
                ]
              ]
            }
          }
        ]
      };

      controller.loadRegionDataset(sampleGeoJson);

      expect(controller.regions.length, 2);
      expect(controller.regions[0].id, 'US-CA');
      expect(controller.regions[0].name, 'California');
      expect(controller.regions[1].id, 'IN-DL');
      expect(controller.regions[1].name, 'Delhi');
    });

    test('loadRegionDataset respects clipAgainstBuilder', () {
      final sampleGeoJson = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'id': 'PAK', 'name': 'Pakistan'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                [
                  [0.0, 0.0],
                  [1.0, 0.0],
                  [1.0, 1.0],
                  [0.0, 0.0]
                ]
              ]
            }
          }
        ]
      };

      controller.loadRegionDataset(
        sampleGeoJson,
        clipAgainstBuilder: (id) => id == 'PAK' ? ['IND'] : [],
      );

      expect(controller.regions.first.clipAgainst, ['IND']);
    });

    test('showRegions and hideRegions toggle visibility and bump revision', () {
      controller.addRegion(const GlobeRegion(
        id: 'FRA',
        name: 'France',
        polygons: [],
        isVisible: true,
      ));
      controller.addRegion(const GlobeRegion(
        id: 'DEU',
        name: 'Germany',
        polygons: [],
        isVisible: true,
      ));

      final initialRevision = controller.regionRevision;

      controller.hideRegions(['FRA']);
      expect(controller.regions.firstWhere((r) => r.id == 'FRA').isVisible, isFalse);
      expect(controller.regions.firstWhere((r) => r.id == 'DEU').isVisible, isTrue);
      expect(controller.regionRevision, greaterThan(initialRevision));

      controller.showRegions(['FRA']);
      expect(controller.regions.firstWhere((r) => r.id == 'FRA').isVisible, isTrue);

      controller.hideAllRegions();
      expect(controller.regions.every((r) => !r.isVisible), isTrue);

      controller.showAllRegions();
      expect(controller.regions.every((r) => r.isVisible), isTrue);
    });

    test('updateRegionStyle modifies styles dynamically and bumps revision', () {
      controller.addRegion(const GlobeRegion(
        id: 'IND',
        name: 'India',
        polygons: [],
        borderColor: Colors.white,
        borderWidth: 1.0,
      ));

      final revBefore = controller.regionRevision;
      controller.updateRegionStyle(
        'IND',
        borderColor: Colors.orange,
        borderWidth: 2.5,
        fillColor: Colors.amber,
      );

      final updated = controller.regions.first;
      expect(updated.borderColor, Colors.orange);
      expect(updated.borderWidth, 2.5);
      expect(updated.fillColor, Colors.amber);
      expect(controller.regionRevision, greaterThan(revBefore));
    });

    test('selectRegions sets selection and bumps revision', () {
      final revBefore = controller.regionRevision;
      controller.selectRegions(['IND', 'USA']);
      expect(controller.selectedRegionIds, {'IND', 'USA'});
      expect(controller.regionRevision, greaterThan(revBefore));
    });

    test('removeRegion and clearRegions remove items and bump revision', () {
      controller.addRegion(const GlobeRegion(id: 'A', name: 'A', polygons: []));
      controller.addRegion(const GlobeRegion(id: 'B', name: 'B', polygons: []));
      expect(controller.regions.length, 2);

      final rev1 = controller.regionRevision;
      controller.removeRegion('A');
      expect(controller.regions.length, 1);
      expect(controller.regions.first.id, 'B');
      expect(controller.regionRevision, greaterThan(rev1));

      final rev2 = controller.regionRevision;
      controller.clearRegions();
      expect(controller.regions, isEmpty);
      expect(controller.regionRevision, greaterThan(rev2));
    });

    testWidgets('GpuForegroundPainter hit-testing triggers onRegionTap on click inside polygon', (tester) async {
      GlobeRegion? tappedRegion;

      const testRegion = GlobeRegion(
        id: 'TEST_ID',
        name: 'Test Region',
        polygons: [],
      );

      final polygonPath = Path()
        ..moveTo(75, 75)
        ..lineTo(125, 75)
        ..lineTo(125, 125)
        ..lineTo(75, 125)
        ..close();

      final regionData = RegionRenderData(
        id: 'TEST_ID_0',
        baseId: 'TEST_ID',
        region: testRegion,
        visiblePaths: [polygonPath],
        polygonPath: polygonPath,
        borderColor: Colors.white,
        borderWidth: 1.0,
        fillColor: Colors.blue,
        highlightColor: null,
        isSelected: false,
        isVisible: true,
        clipAgainst: const [],
      );

      await tester.pumpWidget(
        CustomPaint(
          size: const Size(200, 200),
          painter: GpuForegroundPainter(
            points: const [],
            arcs: const [],
            satellites: const [],
            regions: [regionData],
            radius: 100,
            center: const Offset(100, 100),
            clickPoint: const Offset(100, 100),
            onRegionTap: (region) {
              tappedRegion = region;
            },
          ),
        ),
      );

      await tester.pump();
      expect(tappedRegion, isNotNull);
      expect(tappedRegion!.id, 'TEST_ID');
    });

    testWidgets('GpuForegroundPainter hit-testing triggers onRegionHover when hovering over polygon', (tester) async {
      GlobeRegion? hoveredRegion;

      const testRegion = GlobeRegion(
        id: 'TEST_ID',
        name: 'Test Region',
        polygons: [],
      );

      final polygonPath = Path()
        ..moveTo(75, 75)
        ..lineTo(125, 75)
        ..lineTo(125, 125)
        ..lineTo(75, 125)
        ..close();

      final regionData = RegionRenderData(
        id: 'TEST_ID_0',
        baseId: 'TEST_ID',
        region: testRegion,
        visiblePaths: [polygonPath],
        polygonPath: polygonPath,
        borderColor: Colors.white,
        borderWidth: 1.0,
        fillColor: Colors.blue,
        highlightColor: null,
        isSelected: false,
        isVisible: true,
        clipAgainst: const [],
      );

      // Hover inside
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(200, 200),
          painter: GpuForegroundPainter(
            points: const [],
            arcs: const [],
            satellites: const [],
            regions: [regionData],
            radius: 100,
            center: const Offset(100, 100),
            hoverPoint: const Offset(100, 100),
            previousHoveredRegionId: null,
            onRegionHover: (region) {
              hoveredRegion = region;
            },
          ),
        ),
      );

      await tester.pump();
      expect(hoveredRegion, isNotNull);
      expect(hoveredRegion!.id, 'TEST_ID');

      // Hover moves outside
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(200, 200),
          painter: GpuForegroundPainter(
            points: const [],
            arcs: const [],
            satellites: const [],
            regions: [regionData],
            radius: 100,
            center: const Offset(100, 100),
            hoverPoint: const Offset(10, 10),
            previousHoveredRegionId: 'TEST_ID',
            onRegionHover: (region) {
              hoveredRegion = region;
            },
          ),
        ),
      );

      await tester.pump();
      expect(hoveredRegion, isNull);
    });

    testWidgets('GpuForegroundPainter hit-testing respects clipAgainst masks', (tester) async {
      GlobeRegion? tappedRegion;

      const baseRegion = GlobeRegion(
        id: 'IND',
        name: 'India',
        polygons: [],
      );

      const clippedRegion = GlobeRegion(
        id: 'PAK',
        name: 'Pakistan',
        polygons: [],
        clipAgainst: ['IND'],
      );

      final indPath = Path()
        ..moveTo(50, 50)
        ..lineTo(150, 50)
        ..lineTo(150, 150)
        ..lineTo(50, 150)
        ..close();

      final pakPath = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0)
        ..lineTo(100, 100)
        ..lineTo(0, 100)
        ..close();

      final indData = RegionRenderData(
        id: 'IND_0',
        baseId: 'IND',
        region: baseRegion,
        visiblePaths: [indPath],
        polygonPath: indPath,
        borderColor: Colors.green,
        borderWidth: 1.0,
        fillColor: Colors.green,
        highlightColor: null,
        isSelected: false,
        isVisible: true,
        clipAgainst: const [],
      );

      final pakData = RegionRenderData(
        id: 'PAK_0',
        baseId: 'PAK',
        region: clippedRegion,
        visiblePaths: [pakPath],
        polygonPath: pakPath,
        borderColor: Colors.orange,
        borderWidth: 1.0,
        fillColor: Colors.orange,
        highlightColor: null,
        isSelected: false,
        isVisible: true,
        clipAgainst: const ['IND'],
      );

      await tester.pumpWidget(
        CustomPaint(
          size: const Size(200, 200),
          painter: GpuForegroundPainter(
            points: const [],
            arcs: const [],
            satellites: const [],
            regions: [indData, pakData],
            radius: 100,
            center: const Offset(100, 100),
            clickPoint: const Offset(75, 75),
            onRegionTap: (region) {
              tappedRegion = region;
            },
          ),
        ),
      );

      await tester.pump();
      expect(tappedRegion, isNotNull);
      expect(tappedRegion!.id, 'IND');
    });

    testWidgets('GeoJSON inner rings (holes) are preserved in one polygon and taps inside hole are ignored', (tester) async {
      GlobeRegion? tappedRegion;

      final sampleGeoJsonWithHole = {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'id': 'DONUT_COUNTRY', 'name': 'Donut Country'},
            'geometry': {
              'type': 'Polygon',
              'coordinates': [
                // Exterior ring: square around (0,0)
                [
                  [-20.0, -20.0],
                  [20.0, -20.0],
                  [20.0, 20.0],
                  [-20.0, 20.0],
                  [-20.0, -20.0],
                ],
                // Interior ring (hole): smaller square centered at (0,0)
                [
                  [-5.0, -5.0],
                  [5.0, -5.0],
                  [5.0, 5.0],
                  [-5.0, 5.0],
                  [-5.0, -5.0],
                ],
              ]
            }
          }
        ]
      };

      controller.loadRegionDataset(
        sampleGeoJsonWithHole,
        defaultFillColor: Colors.purple,
      );

      expect(controller.regions.length, 1);
      final region = controller.regions.first;
      // Must be 1 polygon containing 2 rings (exterior + hole)
      expect(region.polygons.length, 1);
      expect(region.polygons.first.length, 2);

      final renderer = GlobeForegroundRenderer();
      final renderData = renderer.calculateRegionPositions(
        regions: controller.regions,
        radius: 100,
        rotationY: 0,
        rotationZ: 0,
        canvasSize: const Size(200, 200),
      );

      // Must produce exactly 1 RegionRenderData for this polygon (not 2 separate ones)
      expect(renderData.length, 1);
      final data = renderData.first;
      expect(data.polygonPath?.fillType, PathFillType.evenOdd);

      // Center (100, 100) corresponds to (lat: 0, lon: 0) which is inside the hole
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(200, 200),
          painter: GpuForegroundPainter(
            points: const [],
            arcs: const [],
            satellites: const [],
            regions: renderData,
            radius: 100,
            center: const Offset(100, 100),
            clickPoint: const Offset(100, 100), // inside hole
            onRegionTap: (r) => tappedRegion = r,
          ),
        ),
      );
      await tester.pump();
      expect(tappedRegion, isNull, reason: 'Click inside hole must NOT trigger onRegionTap');

      // Click in filled area outside hole (e.g. at Offset(115, 115))
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(200, 200),
          painter: GpuForegroundPainter(
            points: const [],
            arcs: const [],
            satellites: const [],
            regions: renderData,
            radius: 100,
            center: const Offset(100, 100),
            clickPoint: const Offset(115, 115), // in filled region outside hole
            onRegionTap: (r) => tappedRegion = r,
          ),
        ),
      );
      await tester.pump();
      expect(tappedRegion, isNotNull);
      expect(tappedRegion!.id, 'DONUT_COUNTRY');
    });

    testWidgets('reloading region under the same ID with modified geometry invalidates cache', (tester) async {
      GlobeRegion? tappedRegion;
      final renderer = GlobeForegroundRenderer();

      // First version: centered at (0, 0)
      final initialRegion = GlobeRegion(
        id: 'SHAPE_A',
        name: 'Shape A',
        fillColor: Colors.blue,
        polygons: const [
          [
            [
              [-5.0, -5.0],
              [5.0, -5.0],
              [5.0, 5.0],
              [-5.0, 5.0],
              [-5.0, -5.0],
            ]
          ]
        ],
      );

      controller.addRegion(initialRegion);

      var renderData = renderer.calculateRegionPositions(
        regions: controller.regions,
        radius: 100,
        rotationY: 0,
        rotationZ: 0,
        canvasSize: const Size(200, 200),
        regionRevision: controller.regionRevision,
      );

      // Verify click at (100, 100) hits initialRegion
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(200, 200),
          painter: GpuForegroundPainter(
            points: const [],
            arcs: const [],
            satellites: const [],
            regions: renderData,
            radius: 100,
            center: const Offset(100, 100),
            clickPoint: const Offset(100, 100),
            onRegionTap: (r) => tappedRegion = r,
          ),
        ),
      );
      await tester.pump();
      expect(tappedRegion?.id, 'SHAPE_A');

      // Now reload region under same ID 'SHAPE_A' but moved to [30..40, 30..40]
      final updatedRegion = GlobeRegion(
        id: 'SHAPE_A',
        name: 'Shape A (Moved)',
        fillColor: Colors.blue,
        polygons: const [
          [
            [
              [30.0, 30.0],
              [40.0, 30.0],
              [40.0, 40.0],
              [30.0, 40.0],
              [30.0, 30.0],
            ]
          ]
        ],
      );

      controller.removeRegion('SHAPE_A');
      controller.addRegion(updatedRegion);

      renderData = renderer.calculateRegionPositions(
        regions: controller.regions,
        radius: 100,
        rotationY: 0,
        rotationZ: 0,
        canvasSize: const Size(200, 200),
        regionRevision: controller.regionRevision,
      );

      // Hit at old location (100, 100) must now be FALSE because shape moved and cache refreshed
      tappedRegion = null;
      await tester.pumpWidget(
        CustomPaint(
          size: const Size(200, 200),
          painter: GpuForegroundPainter(
            points: const [],
            arcs: const [],
            satellites: const [],
            regions: renderData,
            radius: 100,
            center: const Offset(100, 100),
            clickPoint: const Offset(100, 100),
            onRegionTap: (r) => tappedRegion = r,
          ),
        ),
      );
      await tester.pump();
      expect(tappedRegion, isNull, reason: 'Old vertices must not persist after reloading geometry under same ID');
    });

    test('GlobeRegion.normalizePolygons correctly handles 3-level and 4-level lists', () {
      final threeLevel = [
        [
          [0.0, 0.0],
          [1.0, 1.0],
          [0.0, 0.0],
        ]
      ];
      final normalizedFrom3 = GlobeRegion.normalizePolygons(threeLevel);
      expect(normalizedFrom3.length, 1);
      expect(normalizedFrom3.first.length, 1);
      expect(normalizedFrom3.first.first.length, 3);

      final fourLevel = [
        [
          [
            [0.0, 0.0],
            [10.0, 10.0],
            [0.0, 0.0],
          ],
          [
            [2.0, 2.0],
            [3.0, 3.0],
            [2.0, 2.0],
          ]
        ]
      ];
      final normalizedFrom4 = GlobeRegion.normalizePolygons(fourLevel);
      expect(normalizedFrom4.length, 1);
      expect(normalizedFrom4.first.length, 2);
    });

    test('selectRegions works case-insensitively when calculating render data', () {
      final renderer = GlobeForegroundRenderer();
      final region = GlobeRegion(
        id: 'TEST_ID',
        name: 'Test',
        fillColor: Colors.blue,
        highlightColor: Colors.amber,
        polygons: const [
          [
            [
              [0.0, 0.0],
              [10.0, 0.0],
              [10.0, 10.0],
              [0.0, 10.0],
              [0.0, 0.0],
            ]
          ]
        ],
      );

      final renderData = renderer.calculateRegionPositions(
        regions: [region],
        radius: 100,
        rotationY: 0,
        rotationZ: 0,
        canvasSize: const Size(200, 200),
        selectedRegionIds: {'test_id'}, // lowercase selection
      );

      expect(renderData.first.isSelected, isTrue);
      expect(renderData.first.highlightColor, Colors.amber);
    });

    test('clipping safeguard prevents region from clipping against itself if self ID is in clipAgainst', () {
      final renderer = GlobeForegroundRenderer();
      final region = GlobeRegion(
        id: 'SELF',
        name: 'Self Region',
        clipAgainst: const ['SELF'], // accidentally contains self
        polygons: const [
          [
            [
              [0.0, 0.0],
              [10.0, 0.0],
              [10.0, 10.0],
              [0.0, 10.0],
              [0.0, 0.0],
            ]
          ]
        ],
      );

      final renderData = renderer.calculateRegionPositions(
        regions: [region],
        radius: 100,
        rotationY: 0,
        rotationZ: 0,
        canvasSize: const Size(200, 200),
      );

      expect(renderData.first.visiblePaths, isNotEmpty);
    });
  });
}
