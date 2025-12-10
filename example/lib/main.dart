import 'package:flutter_earth_globe/flutter_earth_globe.dart';
import 'package:flutter_earth_globe/flutter_earth_globe_controller.dart';
import 'package:flutter_earth_globe/globe_coordinates.dart';
import 'package:flutter_earth_globe/point.dart';
import 'package:flutter_earth_globe/point_connection.dart';
import 'package:flutter_earth_globe/point_connection_style.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'coordinate_state.dart';
import 'coordinates_display.dart';
import 'globe_controls_state.dart';
import 'control_widgets.dart';

void main() {
  runApp(MaterialApp(
    title: 'Flutter Earth Globe',
    theme: AppTheme.darkTheme,
    debugShowCheckedModeBanner: false,
    home: const Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  late FlutterEarthGlobeController _controller;

  // Panel visibility
  bool _leftPanelVisible = true;
  bool _rightPanelVisible = true;

  // Section expansion states
  bool _rotationExpanded = true;
  bool _dayNightExpanded = false;
  bool _pointsExpanded = false;
  bool _connectionsExpanded = false;
  bool _atmosphereExpanded = false;

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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHovering
              ? [AppTheme.accentCyan, AppTheme.accentPurple]
              : [
                  AppTheme.accentCyan.withAlpha(180),
                  AppTheme.accentPurple.withAlpha(180)
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha(isHovering ? 180 : 80),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentCyan.withAlpha(isHovering ? 150 : 80),
            blurRadius: isHovering ? 20 : 12,
            spreadRadius: isHovering ? 2 : 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withAlpha(150),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            point.label ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget connectionLabelBuilder(BuildContext context,
      PointConnection connection, bool isHovering, bool visible) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHovering
              ? [AppTheme.accentPurple, AppTheme.accentPink]
              : [
                  AppTheme.accentPurple.withAlpha(180),
                  AppTheme.accentPink.withAlpha(180)
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(isHovering ? 180 : 80),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentPurple.withAlpha(isHovering ? 150 : 80),
            blurRadius: isHovering ? 16 : 10,
            spreadRadius: isHovering ? 1 : 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flight_takeoff_rounded,
            color: Colors.white.withAlpha(220),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            connection.label ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _controller = FlutterEarthGlobeController(
      rotationSpeed: 0.05,
      minZoom: -1.5,
      maxZoom: 5,
      zoom: 0.5,
      isRotating: false,
      atmosphereOpacity: 0.8,
      zoomToMousePosition: false,
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
        labelBuilder: pointLabelBuilder,
        isLabelVisible: true,
        style: const PointStyle(
          color: Colors.cyan,
          size: 6,
          altitude: 0.1,
          transitionDuration: 500,
        ),
      ),
      Point(
        id: '2',
        coordinates: const GlobeCoordinates(40.7128, -74.0060),
        style: const PointStyle(
          color: Colors.green,
          altitude: 0.05,
          transitionDuration: 600,
        ),
        labelBuilder: pointLabelBuilder,
        isLabelVisible: true,
        label: 'New York',
      ),
      Point(
        id: '3',
        coordinates: const GlobeCoordinates(35.6895, 139.6917),
        style: const PointStyle(
          color: Colors.purple,
          altitude: 0.15,
          transitionDuration: 700,
        ),
        labelBuilder: pointLabelBuilder,
        isLabelVisible: true,
        label: 'Tokyo',
      ),
      Point(
        id: '4',
        isLabelVisible: false,
        onTap: () {
          Future.delayed(Duration.zero, () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.primaryMedium,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Center Point',
                    style: TextStyle(color: Colors.white)),
                content: const Text(
                  'This is the center of the globe at coordinates (0, 0)',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          });
        },
        coordinates: const GlobeCoordinates(0, 0),
        style: const PointStyle(
          color: Colors.amber,
          altitude: 0.0,
          transitionDuration: 400,
        ),
        label: 'Center',
      ),
    ];

    connections = [
      PointConnection(
        id: '1',
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.primaryMedium,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Flight Route',
                  style: TextStyle(color: Colors.white)),
              content: const Text(
                'London → New York\nDistance: ~5,570 km',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        start: points[0].coordinates,
        end: points[1].coordinates,
        isMoving: true,
        labelBuilder: connectionLabelBuilder,
        isLabelVisible: true,
        curveScale: 1.2,
        style: const PointConnectionStyle(
          type: PointConnectionType.dotted,
          lineWidth: 2,
          dashSize: 6,
          spacing: 10,
          dashAnimateTime: 1000,
          transitionDuration: 500,
          animateOnAdd: true,
          growthAnimationDuration: 1000,
        ),
        label: 'LDN → NYC',
      ),
      PointConnection(
        start: points[1].coordinates,
        end: points[3].coordinates,
        isMoving: true,
        labelBuilder: connectionLabelBuilder,
        isLabelVisible: true,
        id: '2',
        style: const PointConnectionStyle(
          type: PointConnectionType.dashed,
          dashAnimateTime: 1000,
          transitionDuration: 500,
          animateOnAdd: true,
          growthAnimationDuration: 800,
        ),
        label: 'NYC → CTR',
      ),
      PointConnection(
        label: 'TYO → CTR',
        labelBuilder: connectionLabelBuilder,
        isLabelVisible: true,
        start: points[2].coordinates,
        end: points[3].coordinates,
        curveScale: 0.5,
        id: '3',
        style: const PointConnectionStyle(
          transitionDuration: 500,
          animateOnAdd: true,
          growthAnimationDuration: 1200,
        ),
      ),
    ];

    _controller.onLoaded = () {
      GlobeControlsState.instance.setSelectedSurface(_textures[0]);
    };

    for (var point in points) {
      _controller.addPoint(point);
      GlobeControlsState.instance.addVisiblePoint(point.id);
    }

    GlobeControlsState.instance.setZoom(_controller.zoom);
    GlobeControlsState.instance.setRotationSpeed(_controller.rotationSpeed);
    GlobeControlsState.instance
        .setDayNightBlendFactor(_controller.dayNightBlendFactor);
  }

  Widget _buildCollapsibleSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          icon: icon,
          isExpanded: isExpanded,
          onTap: onToggle,
        ),
        AnimatedCrossFade(
          firstChild: Column(children: children),
          secondChild: const SizedBox.shrink(),
          crossFadeState:
              isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return GlassPanel(
      width: 260,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Controls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _leftPanelVisible = false),
                color: AppTheme.accentBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Rotation Section
          _buildCollapsibleSection(
            title: 'Rotation & Zoom',
            icon: Icons.rotate_right,
            isExpanded: _rotationExpanded,
            onToggle: () =>
                setState(() => _rotationExpanded = !_rotationExpanded),
            children: [
              RotationControl(controller: _controller),
              const SizedBox(height: 8),
              RotationSpeedControl(controller: _controller),
              const SizedBox(height: 8),
              ZoomControl(controller: _controller),
            ],
          ),

          // Day/Night Section
          _buildCollapsibleSection(
            title: 'Day/Night Cycle',
            icon: Icons.brightness_4,
            isExpanded: _dayNightExpanded,
            onToggle: () =>
                setState(() => _dayNightExpanded = !_dayNightExpanded),
            children: [
              DayNightEnableControl(controller: _controller),
              DayNightModeControl(controller: _controller),
              SimulatedNightColorControl(controller: _controller),
              SimulatedNightIntensityControl(controller: _controller),
              DayNightAnimateControl(controller: _controller),
              SunPositionControl(controller: _controller),
              BlendFactorControl(controller: _controller),
              RealTimeSunControl(controller: _controller),
            ],
          ),

          // Points Section
          _buildCollapsibleSection(
            title: 'Points',
            icon: Icons.place,
            isExpanded: _pointsExpanded,
            onToggle: () => setState(() => _pointsExpanded = !_pointsExpanded),
            children: points
                .map((point) =>
                    PointControl(controller: _controller, point: point))
                .toList(),
          ),

          // Connections Section
          _buildCollapsibleSection(
            title: 'Connections',
            icon: Icons.timeline,
            isExpanded: _connectionsExpanded,
            onToggle: () =>
                setState(() => _connectionsExpanded = !_connectionsExpanded),
            children: [
              ...connections.map((connection) => ConnectionControl(
                  controller: _controller, connection: connection)),
              const SizedBox(height: 8),
              SatelliteControl(controller: _controller),
            ],
          ),

          // Atmosphere Section
          _buildCollapsibleSection(
            title: 'Atmosphere & Lighting',
            icon: Icons.blur_on,
            isExpanded: _atmosphereExpanded,
            onToggle: () =>
                setState(() => _atmosphereExpanded = !_atmosphereExpanded),
            children: [
              AtmosphereColorControl(controller: _controller),
              AtmosphereOpacityControl(controller: _controller),
              SurfaceLightingControl(controller: _controller),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return GlassPanel(
      width: 250,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppTheme.headerGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.public, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Textures',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => setState(() => _rightPanelVisible = false),
                color: AppTheme.accentBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          TextureSelector(
            controller: _controller,
            textures: _textures,
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withAlpha(100),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.public, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Text(
            'Flutter Earth Globe',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelToggle({
    required IconData icon,
    required bool isVisible,
    required VoidCallback onTap,
    required Alignment alignment,
  }) {
    return AnimatedOpacity(
      opacity: isVisible ? 0 : 1,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: isVisible,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.panelGradient,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentBlue.withAlpha(50)),
            ),
            child: Icon(icon, color: AppTheme.accentCyan, size: 24),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;

    double radius = screenWidth < 500 ? ((screenWidth / 3.5) - 20) : 140;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.primaryDark,
      drawer: isSmallScreen
          ? Drawer(
              backgroundColor: Colors.transparent,
              child: _buildLeftPanel(),
            )
          : null,
      endDrawer: isSmallScreen
          ? Drawer(
              backgroundColor: Colors.transparent,
              child: _buildRightPanel(),
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            // Globe - full screen background
            Positioned.fill(
              child: FlutterEarthGlobe(
                onZoomChanged: (zoom) {
                  GlobeControlsState.instance.setZoom(zoom);
                },
                onTap: (coordinates) {
                  CoordinateState.instance.updateClickCoordinates(coordinates);
                },
                onHover: (coordinates) {
                  CoordinateState.instance.updateHoverCoordinates(coordinates);
                },
                controller: _controller,
                radius: radius,
              ),
            ),

            // Title at top
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(child: _buildTitle()),
            ),

            // Left panel or toggle
            if (!isSmallScreen)
              Positioned(
                top: 16,
                left: 16,
                bottom: 16,
                child: AnimatedSlide(
                  offset:
                      _leftPanelVisible ? Offset.zero : const Offset(-1.1, 0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: _buildLeftPanel(),
                ),
              ),

            // Left toggle button
            if (!isSmallScreen)
              Positioned(
                top: 80,
                left: 16,
                child: _buildPanelToggle(
                  icon: Icons.chevron_right,
                  isVisible: _leftPanelVisible,
                  onTap: () => setState(() => _leftPanelVisible = true),
                  alignment: Alignment.centerLeft,
                ),
              ),

            // Right panel or toggle
            if (!isSmallScreen)
              Positioned(
                top: 16,
                right: 16,
                bottom: 16,
                child: AnimatedSlide(
                  offset:
                      _rightPanelVisible ? Offset.zero : const Offset(1.1, 0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: _buildRightPanel(),
                ),
              ),

            // Right toggle button
            if (!isSmallScreen)
              Positioned(
                top: 16,
                right: 16,
                child: _buildPanelToggle(
                  icon: Icons.chevron_left,
                  isVisible: _rightPanelVisible,
                  onTap: () => setState(() => _rightPanelVisible = true),
                  alignment: Alignment.centerRight,
                ),
              ),

            // Mobile menu buttons
            if (isSmallScreen) ...[
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.panelGradient,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.accentBlue.withAlpha(50)),
                    ),
                    child: const Icon(Icons.menu, color: AppTheme.accentCyan),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.panelGradient,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.accentBlue.withAlpha(50)),
                    ),
                    child: const Icon(Icons.public, color: AppTheme.accentCyan),
                  ),
                ),
              ),
            ],

            // Coordinates display at bottom
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CoordinatesDisplay(),
            ),
          ],
        ),
      ),
    );
  }
}
