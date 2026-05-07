import 'dart:async';
import 'dart:convert';

import 'package:farm_flutter/pageViews/mine_view.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _currentIndex = 0;
  PageController? _pageController;

  PageController get _controller {
    return _pageController ??= PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _controller,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: const [_AdminHomeMapView(), MineView()],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: AppColors.white,
            elevation: 8,
            indicatorColor: AppColors.primaryLightest,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                );
              }
              return const TextStyle(
                color: AppColors.bottomNavUnselected,
                fontSize: 12,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: AppColors.primary, size: 24);
              }
              return const IconThemeData(
                color: AppColors.bottomNavUnselected,
                size: 24,
              );
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            _controller.jumpToPage(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '首页',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHomeMapView extends StatefulWidget {
  const _AdminHomeMapView();

  @override
  State<_AdminHomeMapView> createState() => _AdminHomeMapViewState();
}

class _AdminHomeMapViewState extends State<_AdminHomeMapView> {
  static const String _cityGeoJsonAssetPath = 'assets/geojson/河南省_市.geojson';
  static const String _districtGeoJsonAssetPath =
      'assets/geojson/河南省_县区.geojson';
  static const double _initialZoom = 6.8;
  static const double _districtLabelZoom = 8.1;
  static const double _districtDetailZoom = 9.6;
  static const double _minZoom = 5.0;
  static const double _maxZoom = 10.2;

  final MapController _mapController = MapController();
  final LayerHitNotifier<String> _hitNotifier = ValueNotifier(null);

  bool _isLoading = true;
  String? _errorMessage;
  List<_GeoRegion> _cityRegions = const [];
  List<_GeoRegion> _districtRegions = const [];
  LatLngBounds? _bounds;
  String? _selectedRegionId;
  double _currentZoom = _initialZoom;
  bool _showDistrictLayer = false;
  bool _lastGestureActive = false;
  bool _isBouncingCamera = false;
  Timer? _cameraBounceTimer;

  List<_GeoRegion> get _activeRegions =>
      _showDistrictLayer ? _districtRegions : _cityRegions;

  _GeoRegion? get _selectedRegion {
    if (_selectedRegionId == null) return null;
    for (final region in _activeRegions) {
      if (region.id == _selectedRegionId) return region;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  @override
  void dispose() {
    _cameraBounceTimer?.cancel();
    _hitNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadGeoJson() async {
    try {
      final cityData = await _loadRegionsFromAsset(_cityGeoJsonAssetPath);
      final districtData = await _loadRegionsFromAsset(
        _districtGeoJsonAssetPath,
      );

      if (!mounted) return;

      setState(() {
        _cityRegions = cityData.regions;
        _districtRegions = districtData.regions;
        _bounds = cityData.bounds ?? districtData.bounds;
        _selectedRegionId = cityData.regions.isNotEmpty
            ? cityData.regions.first.id
            : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '加载 GeoJSON 失败：$e';
      });
    }
  }

  Future<_GeoDataBundle> _loadRegionsFromAsset(String assetPath) async {
    final rawJson = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final features = decoded['features'];
    if (features is! List) {
      throw FormatException('$assetPath 的 GeoJSON features 格式无效');
    }

    final regions = <_GeoRegion>[];
    final allPoints = <LatLng>[];

    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;

      final properties = feature['properties'] as Map<String, dynamic>? ?? {};
      final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
      final parsedPolygons = _parseGeometry(geometry);
      if (parsedPolygons.isEmpty) continue;

      for (final polygon in parsedPolygons) {
        allPoints.addAll(polygon.outer);
      }

      final adcode = properties['adcode']?.toString();
      final name = properties['name']?.toString() ?? '未命名区域';
      final parent = properties['parent'] as Map<String, dynamic>?;
      final parentAdcode = parent?['adcode']?.toString();
      final centroid =
          _readPoint(properties['centroid']) ??
          _readPoint(properties['center']) ??
          _calculateCentroid(parsedPolygons.first.outer);

      regions.add(
        _GeoRegion(
          id: adcode ?? name,
          name: name,
          level: properties['level']?.toString() ?? '',
          parentAdcode: parentAdcode,
          center: centroid,
          polygons: parsedPolygons,
        ),
      );
    }

    return _GeoDataBundle(
      regions: regions,
      bounds: allPoints.isEmpty ? null : LatLngBounds.fromPoints(allPoints),
    );
  }

  List<_GeoPolygonData> _parseGeometry(Map<String, dynamic> geometry) {
    final type = geometry['type']?.toString();
    final coordinates = geometry['coordinates'];
    if (type == null || coordinates is! List) return const [];

    final polygons = <_GeoPolygonData>[];

    if (type == 'Polygon') {
      final polygon = _parseSinglePolygon(coordinates);
      if (polygon != null) polygons.add(polygon);
    } else if (type == 'MultiPolygon') {
      for (final polygonCoordinates in coordinates) {
        if (polygonCoordinates is! List) continue;
        final polygon = _parseSinglePolygon(polygonCoordinates);
        if (polygon != null) polygons.add(polygon);
      }
    }

    return polygons;
  }

  _GeoPolygonData? _parseSinglePolygon(List<dynamic> coordinates) {
    if (coordinates.isEmpty) return null;

    final rings = <List<LatLng>>[];
    for (final ringCoordinates in coordinates) {
      if (ringCoordinates is! List) continue;
      final ring = <LatLng>[];
      for (final point in ringCoordinates) {
        if (point is! List || point.length < 2) continue;
        final lng = (point[0] as num?)?.toDouble();
        final lat = (point[1] as num?)?.toDouble();
        if (lng == null || lat == null) continue;
        ring.add(LatLng(lat, lng));
      }
      if (ring.length >= 3) {
        rings.add(ring);
      }
    }

    if (rings.isEmpty) return null;

    return _GeoPolygonData(
      outer: rings.first,
      holes: rings.length > 1 ? rings.sublist(1) : const [],
    );
  }

  LatLng? _readPoint(dynamic rawPoint) {
    if (rawPoint is! List || rawPoint.length < 2) return null;
    final lng = (rawPoint[0] as num?)?.toDouble();
    final lat = (rawPoint[1] as num?)?.toDouble();
    if (lng == null || lat == null) return null;
    return LatLng(lat, lng);
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    var latSum = 0.0;
    var lngSum = 0.0;
    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  List<Polygon<String>> _buildMapPolygons() {
    final polygons = <Polygon<String>>[];
    final showStrongDetail = _currentZoom >= _districtDetailZoom;

    for (final region in _activeRegions) {
      final isSelected = region.id == _selectedRegionId;
      for (final shape in region.polygons) {
        polygons.add(
          Polygon<String>(
            points: shape.outer,
            holePointsList: shape.holes.isEmpty ? null : shape.holes,
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.34)
                : AppColors.primary.withValues(alpha: 0.14),
            borderColor: isSelected
                ? AppColors.danger
                : AppColors.primary.withValues(alpha: 0.70),
            borderStrokeWidth: isSelected
                ? (showStrongDetail ? 3.2 : 2.8)
                : (showStrongDetail ? 1.8 : 1.1),
            hitValue: region.id,
            label: null,
          ),
        );
      }
    }

    return polygons;
  }

  List<Marker> _buildLabelMarkers() {
    return _activeRegions.map((region) {
      final isSelected = region.id == _selectedRegionId;
      final isDistrict = _showDistrictLayer;
      return Marker(
        point: region.center,
        width: isSelected ? (isDistrict ? 92 : 100) : (isDistrict ? 84 : 96),
        height: isSelected ? 28 : 24,
        child: IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isSelected ? 0.92 : 0.82),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                region.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.danger : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  LatLngBounds? _bounceTargetBounds() {
    final bounds = _bounds;
    if (bounds == null) return null;
    return LatLngBounds(
      LatLng(bounds.south - 0.28, bounds.west - 0.35),
      LatLng(bounds.north + 0.28, bounds.east + 0.35),
    );
  }

  LatLngBounds? _dragLimitBounds() {
    final bounds = _bounds;
    if (bounds == null) return null;
    return LatLngBounds(
      LatLng(bounds.south - 3.5, bounds.west - 4.5),
      LatLng(bounds.north + 3.5, bounds.east + 4.5),
    );
  }

  double _clampZoom(double zoom) {
    if (zoom < _minZoom) return _minZoom;
    if (zoom > _maxZoom) return _maxZoom;
    return zoom;
  }

  LatLng _clampCenter(LatLng center, LatLngBounds? bounds) {
    if (bounds == null) return center;
    final lat = center.latitude.clamp(bounds.south, bounds.north);
    final lng = center.longitude.clamp(bounds.west, bounds.east);
    return LatLng(lat.toDouble(), lng.toDouble());
  }

  void _bounceCameraBack(MapCamera camera) {
    final targetBounds = _bounceTargetBounds();
    final targetZoom = _clampZoom(camera.zoom);
    final targetCenter = _clampCenter(camera.center, targetBounds);
    final needsBounce =
        (targetZoom - camera.zoom).abs() > 0.001 ||
        (targetCenter.latitude - camera.center.latitude).abs() > 0.0001 ||
        (targetCenter.longitude - camera.center.longitude).abs() > 0.0001;

    if (!needsBounce) return;

    _cameraBounceTimer?.cancel();
    _isBouncingCamera = true;

    const totalSteps = 12;
    var step = 0;
    final startCenter = camera.center;
    final startZoom = camera.zoom;

    _cameraBounceTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      step++;
      final t = step / totalSteps;
      final eased = 1 - (1 - t) * (1 - t);
      final nextCenter = LatLng(
        startCenter.latitude +
            (targetCenter.latitude - startCenter.latitude) * eased,
        startCenter.longitude +
            (targetCenter.longitude - startCenter.longitude) * eased,
      );
      final nextZoom = startZoom + (targetZoom - startZoom) * eased;

      _mapController.move(nextCenter, nextZoom);

      if (step >= totalSteps) {
        timer.cancel();
        _isBouncingCamera = false;
      }
    });
  }

  void _scheduleBounceBack() {
    _cameraBounceTimer?.cancel();
    _cameraBounceTimer = Timer(const Duration(milliseconds: 36), () {
      if (!mounted || _isBouncingCamera) return;
      _bounceCameraBack(_mapController.camera);
    });
  }

  void _handlePolygonTap() {
    final hit = _hitNotifier.value;
    final hitId = hit?.hitValues.isNotEmpty == true
        ? hit!.hitValues.first
        : null;
    if (hitId == null || hitId == _selectedRegionId) return;

    setState(() {
      _selectedRegionId = hitId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowDistrictLayer = _currentZoom >= _districtLabelZoom;
    if (shouldShowDistrictLayer != _showDistrictLayer) {
      _showDistrictLayer = shouldShowDistrictLayer;
      if (_selectedRegionId != null &&
          !_activeRegions.any((region) => region.id == _selectedRegionId)) {
        _selectedRegionId = _activeRegions.isNotEmpty
            ? _activeRegions.first.id
            : null;
      }
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final selectedRegion = _selectedRegion;
    final bounds = _bounds;
    final detailLevelText = _currentZoom >= _districtDetailZoom
        ? '当前精度：区县边界详情'
        : (_showDistrictLayer ? '当前精度：区县级' : '当前精度：地市级');

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          '管理员首页',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedRegion?.name ??
                        (_showDistrictLayer ? '河南省县区' : '河南省地市'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedRegion == null
                        ? detailLevelText
                        : '当前选中${_showDistrictLayer ? '区县' : '地市'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Listener(
                        onPointerUp: (_) => _scheduleBounceBack(),
                        onPointerCancel: (_) => _scheduleBounceBack(),
                        onPointerDown: (_) {
                          _cameraBounceTimer?.cancel();
                          _isBouncingCamera = false;
                        },
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCameraFit: bounds == null
                                ? null
                                : CameraFit.bounds(
                                    bounds: bounds,
                                    padding: const EdgeInsets.all(24),
                                  ),
                            initialCenter:
                                selectedRegion?.center ??
                                const LatLng(34.0, 113.0),
                            initialZoom: _initialZoom,
                            minZoom: _minZoom - 2.5,
                            maxZoom: _maxZoom + 3.0,
                            keepAlive: true,
                            cameraConstraint: _dragLimitBounds() == null
                                ? const CameraConstraint.unconstrained()
                                : CameraConstraint.contain(
                                    bounds: _dragLimitBounds()!,
                                  ),
                            interactionOptions: const InteractionOptions(
                              flags:
                                  InteractiveFlag.drag |
                                  InteractiveFlag.pinchZoom |
                                  InteractiveFlag.doubleTapZoom,
                            ),
                            onPositionChanged: (camera, hasGesture) {
                              final zoom = camera.zoom;
                              if (mounted &&
                                  (zoom - _currentZoom).abs() >= 0.05) {
                                setState(() {
                                  _currentZoom = zoom;
                                });
                              }

                              if (!hasGesture &&
                                  _lastGestureActive &&
                                  !_isBouncingCamera) {
                                _scheduleBounceBack();
                              }
                              _lastGestureActive = hasGesture;
                            },
                            onTap: (tapPosition, point) {
                              if (_selectedRegionId == null) return;
                              setState(() {
                                _selectedRegionId = null;
                              });
                            },
                          ),
                          children: [
                            Container(color: AppColors.backgroundLight),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: Stack(
                                key: ValueKey(_showDistrictLayer),
                                children: [
                                  GestureDetector(
                                    onTap: _handlePolygonTap,
                                    child: PolygonLayer<String>(
                                      polygons: _buildMapPolygons(),
                                      hitNotifier: _hitNotifier,
                                      drawInSingleWorld: true,
                                    ),
                                  ),
                                  MarkerLayer(markers: _buildLabelMarkers()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.96),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: const Text(
                          '默认显示市级，放大后切换到县区级',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeoRegion {
  final String id;
  final String name;
  final String level;
  final String? parentAdcode;
  final LatLng center;
  final List<_GeoPolygonData> polygons;

  const _GeoRegion({
    required this.id,
    required this.name,
    required this.level,
    required this.parentAdcode,
    required this.center,
    required this.polygons,
  });
}

class _GeoPolygonData {
  final List<LatLng> outer;
  final List<List<LatLng>> holes;

  const _GeoPolygonData({required this.outer, required this.holes});
}

class _GeoDataBundle {
  final List<_GeoRegion> regions;
  final LatLngBounds? bounds;

  const _GeoDataBundle({required this.regions, required this.bounds});
}
