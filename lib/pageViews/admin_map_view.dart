import 'dart:async';

import 'package:farm_flutter/config/province_config.dart';
import 'package:farm_flutter/models/map_models.dart';
import 'package:farm_flutter/pageViews/widgets/adminMap/disease_chart_marker.dart';
import 'package:farm_flutter/services/disease_stats_service.dart';
import 'package:farm_flutter/services/geojson_parser.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AdminMapView extends StatefulWidget {
  const AdminMapView({super.key});

  @override
  State<AdminMapView> createState() => AdminMapViewState();
}

class AdminMapViewState extends State<AdminMapView> {
  // ---- 省份配置快捷引用 ----
  static double get _initialZoom => currentProvince.initialZoom;
  static double get _districtLabelZoom => currentProvince.districtLabelZoom;
  static double get _districtDetailZoom => currentProvince.districtDetailZoom;
  static double get _minZoom => currentProvince.minZoom;
  static double get _maxZoom => currentProvince.maxZoom;

  // ---- 依赖服务 ----
  final _geoParser = const GeoJsonParser();
  final _statsService = DiseaseStatsService();

  // ---- 地图控制器 ----
  final MapController _mapController = MapController();
  final LayerHitNotifier<String> _hitNotifier = ValueNotifier(null);

  // ---- 页面状态 ----
  bool _isLoading = true;
  String? _errorMessage;
  List<GeoRegion> _cityRegions = const [];
  List<GeoRegion> _districtRegions = const [];
  LatLngBounds? _bounds;
  String? _selectedRegionId;
  double _currentZoom = _initialZoom;
  bool _showDistrictLayer = false;

  // ---- 相机弹跳 ----
  bool _lastGestureActive = false;
  bool _isBouncingCamera = false;
  Timer? _cameraBounceTimer;

  // ---- 多边形/标记缓存 ----
  List<Polygon<String>> _cachedPolygons = const [];
  List<Marker> _cachedLabels = const [];

  // ---- 计算属性 ----
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
      final city =
          _cityRegions.where((c) => c.id == region.parentAdcode).firstOrNull;
      return '$provinceName${city?.name ?? ''}${region.name}';
    }
    return '$provinceName${region.name}';
  }

  // ---- 生命周期 ----

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _cameraBounceTimer?.cancel();
    _hitNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _geoParser.loadFromAsset(currentProvince.cityGeoJsonPath),
        _geoParser.loadFromAsset(currentProvince.districtGeoJsonPath),
      ]);
      final cityData = results[0];
      final districtData = results[1];

      if (!mounted) return;
      setState(() {
        _cityRegions = cityData.regions;
        _districtRegions = districtData.regions;
        _bounds = cityData.bounds ?? districtData.bounds;
        _selectedRegionId = null;
        _isLoading = false;
      });
      _rebuildCache();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '加载 GeoJSON 失败：$e';
      });
    }

    await _statsService.fetchDiseaseData();
    if (mounted) {
      setState(() {});
      _rebuildCache();
    }
  }

  // ---- 缓存构建 ----

  void _rebuildCache() {
    _cachedPolygons = _buildMapPolygons();
    _cachedLabels = _buildLabelMarkers();
  }

  List<Polygon<String>> _buildMapPolygons() {
    final polygons = <Polygon<String>>[];
    final showStrongDetail = _currentZoom >= _districtDetailZoom;
    final hasGeoData = _statsService.dataAdcodes.isNotEmpty;
    int maxCount = 1;
    if (hasGeoData) {
      for (final r in _activeRegions) {
        final c = _statsService.regionTotalCount(r,
            showDistrictLayer: _showDistrictLayer);
        if (c > maxCount) maxCount = c;
      }
    }

    for (final region in _activeRegions) {
      final isSelected = region.id == _selectedRegionId;
      final hasData = _statsService.regionHasData(region,
          showDistrictLayer: _showDistrictLayer);
      final count = hasData
          ? _statsService.regionTotalCount(region,
              showDistrictLayer: _showDistrictLayer)
          : 0;
      final ratio = maxCount > 1 ? (count / maxCount).clamp(0.0, 1.0) : 0.0;

      for (final shape in region.polygons) {
        final fillColor = _statsService.regionFillColor(
          hasGeoData: hasGeoData,
          hasData: hasData,
          isSelected: isSelected,
          severityRatio: ratio,
        );
        final borderColor = _statsService.regionBorderColor(
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
    final hasGeoData = _statsService.dataAdcodes.isNotEmpty;
    return _activeRegions.map((region) {
      final isSelected = region.id == _selectedRegionId;
      final hasData = _statsService.regionHasData(region,
          showDistrictLayer: _showDistrictLayer);
      final dim = hasGeoData && !hasData;
      return Marker(
        point: region.center,
        width: isSelected ? (_showDistrictLayer ? 92 : 100) : (_showDistrictLayer ? 84 : 96),
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
    if (region == null ||
        !_statsService.regionHasData(region,
            showDistrictLayer: _showDistrictLayer)) {
      return [];
    }
    final summary = _statsService.getDiseaseSummary(region.id,
        showDistrictLayer: _showDistrictLayer);
    if (summary.isEmpty) return [];

    return [
      Marker(
        point: _popupAnchorForRegion(region),
        width: 320,
        height: 226,
        child: DiseaseChartMarker(summary: summary),
      ),
    ];
  }

  // ---- 交互处理 ----

  void _handlePolygonTap() {
    final hit = _hitNotifier.value;
    final hitId = hit?.hitValues.isNotEmpty == true
        ? hit!.hitValues.first
        : null;
    if (hitId == null) return;

    if (hitId == _selectedRegionId) {
      setState(() {
        _selectedRegionId = null;
        _rebuildCache();
      });
      return;
    }

    GeoRegion? tappedRegion;
    for (final r in _activeRegions) {
      if (r.id == hitId) {
        tappedRegion = r;
        break;
      }
    }

    setState(() {
      if (tappedRegion != null &&
          _statsService.regionHasData(tappedRegion,
              showDistrictLayer: _showDistrictLayer)) {
        _selectedRegionId = hitId;
      } else {
        _selectedRegionId = null;
      }
      _rebuildCache();
    });
  }

  // ---- 相机弹跳逻辑 ----

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

  LatLng _popupAnchorForRegion(GeoRegion region) {
    final bounds = _regionBounds(region);
    final camera = _mapController.camera;
    final vc = camera.center;
    final z = camera.zoom;
    final halfLat = 360 / z.clamp(5, 18);
    final halfLng = halfLat * 1.6;

    final latMargin = ((bounds.north - bounds.south) * 0.35).clamp(0.08, 0.32);
    final lngMargin = ((bounds.east - bounds.west) * 0.35).clamp(0.08, 0.36);

    final candidates = [
      LatLng(bounds.north + latMargin, region.center.longitude),
      LatLng(bounds.south - latMargin, region.center.longitude),
      LatLng(region.center.latitude, bounds.east + lngMargin),
      LatLng(region.center.latitude, bounds.west - lngMargin),
      LatLng(bounds.north + latMargin, bounds.east + lngMargin),
      LatLng(bounds.north + latMargin, bounds.west - lngMargin),
      LatLng(bounds.south - latMargin, bounds.east + lngMargin),
      LatLng(bounds.south - latMargin, bounds.west - lngMargin),
    ];
    LatLng best = candidates.first;
    double bestScore = double.negativeInfinity;

    final popupHalfLat = halfLat * 0.34;
    final popupHalfLng = halfLng * 0.42;
    final avoidLatPad = (bounds.north - bounds.south) * 0.08;
    final avoidLngPad = (bounds.east - bounds.west) * 0.08;
    final avoidNorth = bounds.north + avoidLatPad;
    final avoidSouth = bounds.south - avoidLatPad;
    final avoidEast = bounds.east + avoidLngPad;
    final avoidWest = bounds.west - avoidLngPad;

    for (final c in candidates) {
      final latRatio = (c.latitude - vc.latitude) / halfLat;
      final lngRatio = (c.longitude - vc.longitude) / halfLng;
      final edgePenalty = latRatio.abs() * 1.2 + lngRatio.abs() * 1.0;

      final overlapLat =
          !(c.latitude + popupHalfLat < avoidSouth ||
              c.latitude - popupHalfLat > avoidNorth);
      final overlapLng =
          !(c.longitude + popupHalfLng < avoidWest ||
              c.longitude - popupHalfLng > avoidEast);
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

  // ---- UI 构建 ----

  @override
  Widget build(BuildContext context) {
    final shouldShowDistrictLayer = _currentZoom >= _districtLabelZoom;
    if (shouldShowDistrictLayer != _showDistrictLayer) {
      _showDistrictLayer = shouldShowDistrictLayer;
      _rebuildCache();
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
            _buildInfoBar(),
            const SizedBox(height: 14),
            Expanded(child: _buildMapContainer()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar() {
    final selectedRegion = _selectedRegion;
    final detailLevelText = _currentZoom >= _districtDetailZoom
        ? '当前精度：区县边界详情'
        : (_showDistrictLayer ? '当前精度：区县级' : '当前精度：地市级');

    final title = _selectedRegionFullName().isNotEmpty
        ? _selectedRegionFullName()
        : (_showDistrictLayer
            ? '${currentProvince.name}县区'
            : '${currentProvince.name}地市');

    final hasData = selectedRegion != null &&
        _statsService.regionHasData(selectedRegion,
            showDistrictLayer: _showDistrictLayer);

    final subtitle = hasData
        ? '当前选中${_showDistrictLayer ? '区县' : '地市'}'
        : (selectedRegion == null
            ? detailLevelText
            : '当前选中${_showDistrictLayer ? '区县' : '地市'} — 暂无病害数据');

    return Container(
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
            title,
            style: TextStyle(
              fontFamily: "serif",
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: "serif",
              fontSize: 12,
              color: AppColors.muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapContainer() {
    final bounds = _bounds;
    final selectedRegion = _selectedRegion;

    return Container(
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
                      selectedRegion?.center ?? currentProvince.center,
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
                            polygons: _cachedPolygons,
                            hitNotifier: _hitNotifier,
                            drawInSingleWorld: true,
                          ),
                        ),
                        MarkerLayer(
                          markers: [
                            ..._cachedLabels,
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
    );
  }
}
