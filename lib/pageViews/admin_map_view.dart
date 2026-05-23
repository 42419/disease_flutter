import 'dart:async';
import 'dart:convert';

import 'package:farm_flutter/utils/api_config.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:farm_flutter/models/map_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AdminMapView extends StatefulWidget {
  const AdminMapView({super.key});

  @override
  State<AdminMapView> createState() => AdminMapViewState();
}

class AdminMapViewState extends State<AdminMapView> {
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
  List<GeoRegion> _cityRegions = const [];
  List<GeoRegion> _districtRegions = const [];
  LatLngBounds? _bounds;
  String? _selectedRegionId;
  double _currentZoom = _initialZoom;
  bool _showDistrictLayer = false;
  bool _lastGestureActive = false;
  bool _isBouncingCamera = false;
  Timer? _cameraBounceTimer;
  final Set<String> _dataAdcodes = {};
  final Set<String> _cityCodesWithDistrictData = {};
  final Map<String, Map<String, int>> _diseaseStatsByCode = {};
  final List<Map<String, dynamic>> _diseaseRawData = [];

  List<GeoRegion> get _activeRegions =>
      _showDistrictLayer ? _districtRegions : _cityRegions;

  GeoRegion? get _selectedRegion {
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
    _fetchDiseaseData();
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
        _selectedRegionId = null;
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

  Future<void> _fetchDiseaseData() async {
    try {
      HttpUtil.init(baseUrl: ApiConfig.baseUrl);
      final resp = await HttpUtil.get(
        '/get_all_dg',
        headers: {'X-API-Token': ApiConfig.apiToken},
      );
      if (resp is Map && resp['data'] is List) {
        final dataList = resp['data'] as List;
        _dataAdcodes.clear();
        _diseaseRawData.clear();
        final tempStats = <String, Map<String, int>>{};
        for (final item in dataList) {
          if (item is Map) {
            final loc = item['location']?.toString().trim();
            final name = item['bhname']?.toString().trim();
            if (loc == null || loc.isEmpty || loc == 'null') continue;
            if (name == null || name.isEmpty) continue;
            _dataAdcodes.add(loc);
            _diseaseRawData.add(item as Map<String, dynamic>);
            tempStats.putIfAbsent(loc, () => {});
            tempStats[loc]!.update(name, (c) => c + 1, ifAbsent: () => 1);
          }
        }
        _diseaseStatsByCode.clear();
        _diseaseStatsByCode.addAll(tempStats);
      }
      _cityCodesWithDistrictData.clear();
      for (final adcode in _dataAdcodes) {
        if (adcode.length == 6 && !adcode.endsWith('00')) {
          _cityCodesWithDistrictData.add('${adcode.substring(0, 4)}00');
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('fetch disease data failed: $e');
    }
  }

  bool _regionHasData(GeoRegion region) {
    if (_dataAdcodes.contains(region.id)) return true;
    if (_showDistrictLayer && region.parentAdcode != null) {
      if (_cityCodesWithDistrictData.contains(region.parentAdcode)) {
        return false;
      }
      if (_dataAdcodes.contains(region.parentAdcode)) {
        return true;
      }
    }
    return false;
  }

  int _regionTotalCount(GeoRegion region) {
    final isCityLevel = !_showDistrictLayer;
    final prefix = isCityLevel ? region.id.substring(0, 4) : region.id;
    int total = 0;
    for (final entry in _diseaseStatsByCode.entries) {
      if (entry.key.startsWith(prefix)) {
        total += entry.value.values.fold(0, (s, c) => s + c);
      }
    }
    return total;
  }

  List<MapEntry<String, int>> _getDiseaseSummary(String regionId) {
    final merged = <String, int>{};
    final isCityLevel = !_showDistrictLayer;
    final prefix = isCityLevel ? regionId.substring(0, 4) : regionId;

    for (final entry in _diseaseStatsByCode.entries) {
      if (entry.key.startsWith(prefix)) {
        entry.value.forEach((name, count) {
          merged.update(name, (c) => c + count, ifAbsent: () => count);
        });
      }
    }
    final sorted = merged.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }

  Future<GeoDataBundle> _loadRegionsFromAsset(String assetPath) async {
    final rawJson = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final features = decoded['features'];
    if (features is! List) {
      throw FormatException('$assetPath 的 GeoJSON features 格式无效');
    }

    final regions = <GeoRegion>[];
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
        GeoRegion(
          id: adcode ?? name,
          name: name,
          level: properties['level']?.toString() ?? '',
          parentAdcode: parentAdcode,
          center: centroid,
          polygons: parsedPolygons,
        ),
      );
    }

    return GeoDataBundle(
      regions: regions,
      bounds: allPoints.isEmpty ? null : LatLngBounds.fromPoints(allPoints),
    );
  }

  List<GeoPolygonData> _parseGeometry(Map<String, dynamic> geometry) {
    final type = geometry['type']?.toString();
    final coordinates = geometry['coordinates'];
    if (type == null || coordinates is! List) return const [];

    final polygons = <GeoPolygonData>[];

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

  GeoPolygonData? _parseSinglePolygon(List<dynamic> coordinates) {
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

    return GeoPolygonData(
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
    final hasGeoData = _dataAdcodes.isNotEmpty;
    int maxCount = 1;
    if (hasGeoData) {
      for (final r in _activeRegions) {
        final c = _regionTotalCount(r);
        if (c > maxCount) maxCount = c;
      }
    }

    for (final region in _activeRegions) {
      final isSelected = region.id == _selectedRegionId;
      final hasData = _regionHasData(region);
      final count = hasData ? _regionTotalCount(region) : 0;
      final ratio = maxCount > 1 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;

      for (final shape in region.polygons) {
        Color fillColor;
        Color borderColor;

        if (hasGeoData && hasData) {
          final opacity = 0.10 + ratio * 0.38;
          fillColor = isSelected
              ? AppColors.warning.withValues(alpha: opacity + 0.10)
              : AppColors.warning.withValues(alpha: opacity);
          borderColor = isSelected
              ? AppColors.danger
              : AppColors.warning.withValues(alpha: 0.55 + ratio * 0.30);
        } else if (hasGeoData) {
          fillColor = isSelected
              ? AppColors.primary.withValues(alpha: 0.10)
              : AppColors.primary.withValues(alpha: 0.04);
          borderColor = isSelected
              ? AppColors.danger
              : AppColors.divider.withValues(alpha: 0.50);
        } else {
          fillColor = isSelected
              ? AppColors.primary.withValues(alpha: 0.34)
              : AppColors.primary.withValues(alpha: 0.14);
          borderColor = isSelected
              ? AppColors.danger
              : AppColors.primary.withValues(alpha: 0.70);
        }

        polygons.add(
          Polygon<String>(
            points: shape.outer,
            holePointsList: shape.holes.isEmpty ? null : shape.holes,
            color: fillColor,
            borderColor: borderColor,
            borderStrokeWidth: isSelected
                ? (showStrongDetail ? 3.2 : 2.8)
                : (hasGeoData && hasData
                    ? (showStrongDetail ? 2.2 : 1.6)
                    : (showStrongDetail ? 1.8 : 1.1)),
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
      final hasData = _regionHasData(region);
      final hasGeoData = _dataAdcodes.isNotEmpty;
      final dim = hasGeoData && !hasData;
      return Marker(
        point: region.center,
        width: isSelected ? (isDistrict ? 92 : 100) : (isDistrict ? 84 : 96),
        height: isSelected ? 28 : 24,
        child: IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(
                  alpha: dim ? 0.28 : (isSelected ? 0.92 : 0.82),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                region.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.danger
                      : dim
                          ? AppColors.mutedSoft
                          : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Marker> _buildDiseaseInfoMarkers() {
    final region = _selectedRegion;
    if (region == null || !_regionHasData(region)) return [];
    final summary = _getDiseaseSummary(region.id);
    if (summary.isEmpty) return [];

    final maxCount = summary.first.value;
    final barCount = summary.length;
    const barMaxHeight = 56.0;
    const innerGap = 8.0;
    final barWidth = _barWidthForNames(summary.map((e) => e.key).toList());
    final cardWidth = barCount * (barWidth + innerGap) - innerGap + 28;
    final markerHeight = barMaxHeight + 84;

    return [
      Marker(
        point: _smartOffset(region.center, 0.12, 0),
        width: cardWidth + 20,
        height: markerHeight,
        child: IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(240),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withAlpha(110)),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: summary.map((entry) {
                      final barHeight =
                          (entry.value / maxCount) * barMaxHeight;
                      return Padding(
                        padding: EdgeInsets.only(
                          left: entry == summary.first ? 0 : innerGap,
                        ),
                        child: SizedBox(
                          width: barWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: barWidth,
                                height: barHeight.clamp(14, barMaxHeight),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withAlpha(180),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: summary.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: entry == summary.first ? 0 : innerGap,
                        ),
                        child: SizedBox(
                          width: barWidth,
                          child: Text(
                            entry.key,
                            maxLines: 3,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  double _barWidthForNames(List<String> names) {
    double maxLen = 0;
    for (final n in names) {
      double w = 0;
      for (final rune in n.runes) {
        w += rune > 127 ? 9 : 6;
      }
      if (w > maxLen) maxLen = w;
    }
    return maxLen.clamp(36.0, 72.0);
  }

  LatLng _smartOffset(LatLng regionCenter, double latOff, double lngOff) {
    final camera = _mapController.camera;
    final vc = camera.center;
    final z = camera.zoom;
    final halfLat = 360 / z.clamp(5, 18);
    final halfLng = halfLat * 1.6;
    final latRatio = (regionCenter.latitude - vc.latitude) / halfLat;
    final lngRatio = (regionCenter.longitude - vc.longitude) / halfLng;
    return LatLng(
      regionCenter.latitude + (latOff * (latRatio > 0.1 ? -1 : 1)),
      regionCenter.longitude + (lngOff * (lngRatio > 0.3 ? -1 : 1)),
    );
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
    if (hitId == null) return;

    if (hitId == _selectedRegionId) {
      setState(() => _selectedRegionId = null);
      return;
    }

    final tappedRegion = _activeRegions.cast<GeoRegion?>().firstWhere(
      (r) => r?.id == hitId,
      orElse: () => null,
    );

    setState(() {
      if (tappedRegion != null && _regionHasData(tappedRegion)) {
        _selectedRegionId = hitId;
      } else {
        _selectedRegionId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowDistrictLayer = _currentZoom >= _districtLabelZoom;
    if (shouldShowDistrictLayer != _showDistrictLayer) {
      _showDistrictLayer = shouldShowDistrictLayer;
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
                style: TextStyle(
                  fontFamily: "serif",
                  color: AppColors.ink,
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
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          '管理员首页',
          style: TextStyle(
            fontFamily: "serif",
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 1.5,
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
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedRegion?.name ??
                        (_showDistrictLayer ? '河南省县区' : '河南省地市'),
                    style: TextStyle(
                      fontFamily: "serif",
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (selectedRegion != null &&
                      _regionHasData(selectedRegion))
                    ...[
                      const SizedBox(height: 4),
                      Text(
                        '当前选中${_showDistrictLayer ? '区县' : '地市'}',
                        style: TextStyle(
                          fontFamily: "serif",
                          fontSize: 12,
                          color: AppColors.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  if (selectedRegion == null ||
                      !_regionHasData(selectedRegion))
                    ...[
                      const SizedBox(height: 4),
                      Text(
                        selectedRegion == null
                            ? detailLevelText
                            : '当前选中${_showDistrictLayer ? '区县' : '地市'} — 暂无病害数据',
                        style: TextStyle(
                          fontFamily: "serif",
                          fontSize: 12,
                          color: AppColors.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: AppColors.hairline),
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
                                  MarkerLayer(
                                    markers: [
                                      ..._buildLabelMarkers(),
                                      ..._buildDiseaseInfoMarkers(),
                                    ],
                                  ),
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
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: Text(
                          '默认显示市级，放大后切换到县区级',
                          style: TextStyle(
                            fontFamily: "serif",
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
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
