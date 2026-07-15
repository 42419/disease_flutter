import 'dart:async';
import 'dart:convert';

import 'package:farm_flutter/config/config.dart';
import 'package:farm_flutter/config/province_config.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:fl_chart/fl_chart.dart';
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
  static String get _cityGeoJsonAssetPath => currentProvince.cityGeoJsonPath;

  static String get _districtGeoJsonAssetPath =>
      currentProvince.districtGeoJsonPath;

  static double get _initialZoom => currentProvince.initialZoom;

  static double get _districtLabelZoom => currentProvince.districtLabelZoom;

  static double get _districtDetailZoom => currentProvince.districtDetailZoom;

  static double get _minZoom => currentProvince.minZoom;

  static double get _maxZoom => currentProvince.maxZoom;
  static const _barColors = [
    AppColors.error,
    AppColors.warning,
    AppColors.accentAmber,
    AppColors.accentTeal,
    AppColors.success,
    AppColors.muted,
    AppColors.body,
  ];

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

  String _selectedRegionFullName() {
    final region = _selectedRegion;
    if (region == null) return '';
    final provinceName = currentProvince.name;
    if (_showDistrictLayer) {
      final city = _cityRegions.where((c) => c.id == region.parentAdcode).firstOrNull;
      return '$provinceName${city?.name ?? ''}${region.name}';
    }
    return '$provinceName${region.name}';
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
      HttpUtil.init(baseUrl: Config.baseUrl);
      final resp = await HttpUtil.get(
        '/get_all_dg',
        headers: {'X-API-Token': Config.apiToken},
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
    // 地市级精度下，检查该市是否下辖有病害数据的区县
    if (!_showDistrictLayer && region.id.length == 6 && region.id.endsWith('00')) {
      return _cityCodesWithDistrictData.contains(region.id);
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

  Color _regionFillColor({
    required bool hasGeoData,
    required bool hasData,
    required bool isSelected,
    required double severityRatio,
  }) {
    // 无病害：绿色；有病害：按强度从浅红到深红渐变。
    if (hasGeoData && !hasData) {
      return isSelected
          ? AppColors.success.withValues(alpha: 0.46)
          : AppColors.success.withValues(alpha: 0.30);
    }
    if (!hasGeoData) {
      return isSelected
          ? AppColors.success.withValues(alpha: 0.24)
          : AppColors.success.withValues(alpha: 0.16);
    }

    final baseRed = Color.lerp(
      AppColors.error.withValues(alpha: 0.24),
      AppColors.error.withValues(alpha: 0.68),
      severityRatio,
    )!;
    return isSelected
        ? Color.lerp(baseRed, AppColors.error.withValues(alpha: 0.82), 0.35)!
        : baseRed;
  }

  Color _regionBorderColor({
    required bool hasGeoData,
    required bool hasData,
    required bool isSelected,
    required double severityRatio,
  }) {
    if (isSelected) return AppColors.error;
    if (hasGeoData && !hasData) {
      return AppColors.success.withValues(alpha: 0.82);
    }
    if (!hasGeoData) {
      return AppColors.success.withValues(alpha: 0.60);
    }
    return Color.lerp(
      AppColors.error.withValues(alpha: 0.58),
      AppColors.error.withValues(alpha: 0.92),
      severityRatio,
    )!;
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
        final fillColor = _regionFillColor(
          hasGeoData: hasGeoData,
          hasData: hasData,
          isSelected: isSelected,
          severityRatio: ratio,
        );
        final borderColor = _regionBorderColor(
          hasGeoData: hasGeoData,
          hasData: hasData,
          isSelected: isSelected,
          severityRatio: ratio,
        );

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

    final displayStats = summary.take(7).toList();
    final maxCount = displayStats.first.value;
    const cardWidth = 300.0;
    const markerHeight = 226.0;
    final chartMaxY = (maxCount < 3) ? 3.0 : (maxCount * 1.2).ceilToDouble();
    final yInterval = maxCount <= 3
        ? 1.0
        : (maxCount / 3).ceilToDouble().clamp(1.0, double.infinity);

    return [
      Marker(
        point: _popupAnchorForRegion(region),
        width: cardWidth + 20,
        height: markerHeight,
        child: IgnorePointer(
          child: Center(
            child: Container(
              width: cardWidth,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              decoration: BoxDecoration(
                color: AppColors.canvas.withAlpha(244),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '病害分布',
                        style: TextStyle(
                          fontFamily: "serif",
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          '${summary.length} 种',
                          style: TextStyle(
                            fontFamily: "serif",
                            fontSize: 11,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 152,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: chartMaxY,
                        minY: 0,
                        barGroups: List.generate(displayStats.length, (i) {
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: displayStats[i].value.toDouble(),
                                color: _barColors[i % _barColors.length],
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(2),
                                  topRight: Radius.circular(2),
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: chartMaxY,
                                  color: AppColors.backgroundDark.withAlpha(80),
                                ),
                              ),
                            ],
                          );
                        }),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= displayStats.length) {
                                  return const SizedBox.shrink();
                                }
                                return SideTitleWidget(
                                  meta: meta,
                                  space: 4,
                                  child: SizedBox(
                                    width: 46,
                                    child: Text(
                                      _formatChartLabel(displayStats[idx].key),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                        height: 1.15,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              interval: yInterval,
                              getTitlesWidget: (value, meta) {
                                final v = value.toInt();
                                if (v < 0 || (maxCount > 0 && v > maxCount)) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Text(
                                    '$v',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: yInterval,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: AppColors.divider,
                            strokeWidth: 0.6,
                            dashArray: [4, 4],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            tooltipMargin: 8,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${displayStats[group.x].key}\n${rod.toY.toInt()} 条记录',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  String _formatChartLabel(String name) {
    final trimmed = name.trim();
    if (trimmed.length <= 4) {
      return trimmed;
    }
    if (trimmed.length <= 8) {
      return '${trimmed.substring(0, 4)}\n${trimmed.substring(4)}';
    }
    final cut = (trimmed.length / 2).ceil().clamp(4, 6);
    return '${trimmed.substring(0, cut)}\n${trimmed.substring(cut)}';
  }

  LatLng _popupAnchorForRegion(GeoRegion region) {
    final bounds = _regionBounds(region);
    final camera = _mapController.camera;
    final vc = camera.center;
    final z = camera.zoom;
    final halfLat = 360 / z.clamp(5, 18);
    final halfLng = halfLat * 1.6;

    final latMargin = ((bounds.north - bounds.south) * 0.35).clamp(0.08, 0.32);
    final lngMargin = ((bounds.east - bounds.west) * 0.35).clamp(0.08, 0.36);

    final top = LatLng(bounds.north + latMargin, region.center.longitude);
    final bottom = LatLng(bounds.south - latMargin, region.center.longitude);
    final right = LatLng(region.center.latitude, bounds.east + lngMargin);
    final left = LatLng(region.center.latitude, bounds.west - lngMargin);
    final topRight = LatLng(bounds.north + latMargin, bounds.east + lngMargin);
    final topLeft = LatLng(bounds.north + latMargin, bounds.west - lngMargin);
    final bottomRight = LatLng(
      bounds.south - latMargin,
      bounds.east + lngMargin,
    );
    final bottomLeft = LatLng(
      bounds.south - latMargin,
      bounds.west - lngMargin,
    );

    final candidates = [
      top,
      bottom,
      right,
      left,
      topRight,
      topLeft,
      bottomRight,
      bottomLeft,
    ];
    LatLng best = topRight;
    double bestScore = double.negativeInfinity;

    // 估算弹层半尺寸（经纬度空间），用于判断是否覆盖选中区域。
    final popupHalfLat = halfLat * 0.34;
    final popupHalfLng = halfLng * 0.42;
    final avoidLatPad = (bounds.north - bounds.south) * 0.08;
    final avoidLngPad = (bounds.east - bounds.west) * 0.08;
    final avoidNorth = bounds.north + avoidLatPad;
    final avoidSouth = bounds.south - avoidLatPad;
    final avoidEast = bounds.east + avoidLngPad;
    final avoidWest = bounds.west - avoidLngPad;

    for (final c in candidates) {
      final latRatio = ((c.latitude - vc.latitude) / halfLat);
      final lngRatio = ((c.longitude - vc.longitude) / halfLng);
      final edgePenalty = latRatio.abs() * 1.2 + lngRatio.abs() * 1.0;

      final cardNorth = c.latitude + popupHalfLat;
      final cardSouth = c.latitude - popupHalfLat;
      final cardEast = c.longitude + popupHalfLng;
      final cardWest = c.longitude - popupHalfLng;
      final overlapLat = !(cardSouth > avoidNorth || cardNorth < avoidSouth);
      final overlapLng = !(cardWest > avoidEast || cardEast < avoidWest);
      final overlapPenalty = (overlapLat && overlapLng) ? 5.0 : 0.0;

      final distanceFromCenter =
          (c.latitude - region.center.latitude).abs() +
          (c.longitude - region.center.longitude).abs();
      final centerPreference = 0.8 - (latRatio.abs() + lngRatio.abs()) * 0.35;
      final score =
          (distanceFromCenter * 3.2) +
          centerPreference -
          edgePenalty -
          overlapPenalty;
      if (score > bestScore) {
        bestScore = score;
        best = c;
      }
    }

    return best;
  }

  LatLngBounds _regionBounds(GeoRegion region) {
    final points = <LatLng>[];
    for (final poly in region.polygons) {
      points.addAll(poly.outer);
    }
    if (points.isEmpty) {
      return LatLngBounds(region.center, region.center);
    }
    return LatLngBounds.fromPoints(points);
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
                    _selectedRegionFullName().isNotEmpty
                        ? _selectedRegionFullName()
                        : (_showDistrictLayer
                            ? '${currentProvince.name}县区'
                            : '${currentProvince.name}地市'),
                    style: TextStyle(
                      fontFamily: "serif",
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (selectedRegion != null &&
                      _regionHasData(selectedRegion)) ...[
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
                      !_regionHasData(selectedRegion)) ...[
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
                                currentProvince.center,
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
