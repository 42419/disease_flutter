import 'dart:async';
import 'dart:math' as math;

import 'package:farm_flutter/config/province_config.dart';
import 'package:farm_flutter/models/map_models.dart';
import 'package:farm_flutter/pageViews/widgets/adminMap/disease_chart_marker.dart';
import 'package:farm_flutter/services/disease_stats_service.dart';
import 'package:farm_flutter/services/geojson_parser.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/app_theme.dart';
import 'package:farm_flutter/utils/app_spacing.dart';
import 'package:farm_flutter/utils/miuix_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AdminMapView extends StatefulWidget {
  const AdminMapView({super.key});

  @override
  State<AdminMapView> createState() => AdminMapViewState();
}

class AdminMapViewState extends State<AdminMapView>
    with TickerProviderStateMixin {
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

  // ---- 统计弹窗弹出/收起动画 ----
  // 复用 MiuixDropdownMenu 同款弹簧参数，保持全 App 弹层手感一致。
  //
  // _popupRegion 和 _selectedRegionId 不是一回事：取消选中后 _popupRegion
  // 还会多保留一小段时间，直到收起动画播放完才清空，这样卡片消失前才有
  // "缩小 + 淡出"的退场效果，而不是被取消选中就瞬间消失。
  GeoRegion? _popupRegion;
  List<MapEntry<String, int>>? _popupSummary;
  // 已经展开着一个弹窗、又点了另一个区域时，_popupFromRegion 记录"从哪个
  // 区域切过来的"，配合 _popupMorphCtrl 做纯平移的过渡（不整个收起再
  // 重新弹出）；null 表示这是一次全新弹出，走"从区域中心生长"的效果。
  GeoRegion? _popupFromRegion;
  int _popupToken = 0;
  late final AnimationController _popupFractionCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final AnimationController _popupAlphaCtrl = AnimationController(
    vsync: this,
    duration: MiuixMotion.alphaEnterDuration,
  );
  late final AnimationController _popupMorphCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  // 弹窗现在画在地图图层*外面*（Positioned），不再是 flutter_map 自己的
  // Marker，所以不会随相机移动自动重新定位——每次相机变化（拖动/缩放）
  // 都让这个计数器 +1，弹窗的 AnimatedBuilder 监听它来触发重新定位。
  final ValueNotifier<int> _cameraTick = ValueNotifier(0);

  // ---- 相机弹跳 ----
  bool _lastGestureActive = false;
  bool _isBouncingCamera = false;
  Timer? _cameraBounceTimer;

  // ---- 多边形/标记缓存 ----
  // 按区域 id 分开缓存，而不是直接存一份拍平的 List：选中/取消选中时
  // 只有 1~2 个区域的高亮颜色真的变了，用这份按 id 索引的缓存可以只
  // 重算这 1~2 个区域、其余几十上百个区域的 Polygon/Marker 对象原样复用，
  // 不用每次都把全部区域的颜色重新算一遍。_cachedPolygons/_cachedLabels
  // 是给 PolygonLayer/MarkerLayer 用的拍平结果，只在这两个 Map 变化后
  // 重新拼一次（拼接本身很便宜，真正费的是颜色计算，避免了才是重点）。
  Map<String, List<Polygon<String>>> _polygonsByRegionId = {};
  Map<String, Marker> _labelByRegionId = {};
  List<Polygon<String>> _cachedPolygons = const [];
  // 字段初始化时 context 还不存在，先给个默认值；build() 里第一次比较
  // 时会自动发现和当前系统亮度不一致并触发一次 _rebuildCache()，不影响正确性。
  bool _lastIsDark = false;
  List<Marker> _cachedLabels = const [];
  // 病害总数的最大值，用来算填色的深浅比例——只跟"当前图层有哪些数据"
  // 有关，跟选中哪个区域无关，不需要跟着选中态变化重新算。
  int _maxRegionCount = 1;

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
      final city = _cityRegions
          .where((c) => c.id == region.parentAdcode)
          .firstOrNull;
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
    _mapController.dispose();
    _hitNotifier.dispose();
    _popupFractionCtrl.dispose();
    _popupAlphaCtrl.dispose();
    _popupMorphCtrl.dispose();
    _cameraTick.dispose();
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

  /// 全量重建：区/市图层切换、初次加载、主题变化这些"整个 _activeRegions
  /// 集合都可能变了"的场景用这个。
  void _rebuildCache() {
    _maxRegionCount = _computeMaxRegionCount();
    _polygonsByRegionId = {
      for (final region in _activeRegions)
        region.id: _buildPolygonsForRegion(region),
    };
    _labelByRegionId = {
      for (final region in _activeRegions) region.id: _buildLabelForRegion(region),
    };
    _flattenCache();
  }

  /// 只更新 [regionIds] 这几个区域的高亮颜色/描边/标签样式，其余区域的
  /// Polygon/Marker 对象原样复用，不重新计算颜色。
  ///
  /// 选中/取消选中一个区域时，视觉上会变的最多只有"之前选中的区域"和
  /// "新选中的区域"这 1~2 个，其余可能有几十上百个的区域完全不受影响。
  /// 之前的做法是不管三七二十一整批重算一遍 [_rebuildCache]，在区/县级别
  /// 精度、区域数量多的时候，这份没必要的计算量会跟"取消选中、播放弹窗
  /// 收起动画"挤在差不多的时间，容易造成掉帧、感觉上像是顿了一下。
  void _updateRegionHighlight(Iterable<String> regionIds) {
    for (final id in regionIds) {
      GeoRegion? region;
      for (final r in _activeRegions) {
        if (r.id == id) {
          region = r;
          break;
        }
      }
      if (region == null) continue;
      _polygonsByRegionId[id] = _buildPolygonsForRegion(region);
      _labelByRegionId[id] = _buildLabelForRegion(region);
    }
    _flattenCache();
  }

  void _flattenCache() {
    _cachedPolygons = _polygonsByRegionId.values.expand((p) => p).toList();
    _cachedLabels = _labelByRegionId.values.toList();
  }

  /// 把 [_rebuildCache] 挪到当前帧渲染完之后再执行。
  ///
  /// [_rebuildCache] 要遍历所有区域重新计算高亮/描边颜色，量不算小；如果
  /// 跟"取消选中、播放弹窗收起动画"这类操作放在同一次手势回调里同步执行，
  /// 会和动画的第一帧抢时间，容易在动画刚开始的瞬间掉一帧，让人感觉像是
  /// "顿了一下"。挪到 postFrameCallback 里，动画能先顺畅地开始播放，区域
  /// 高亮颜色最多晚一帧刷新，肉眼几乎察觉不到。
  void _scheduleRebuildCache() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(_rebuildCache);
    });
  }

  /// [_scheduleRebuildCache] 的"只更新受影响区域"版本，selection 变化时用
  /// 这个而不是全量重建。
  void _scheduleUpdateRegionHighlight(Iterable<String> regionIds) {
    final ids = regionIds.toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _updateRegionHighlight(ids));
    });
  }

  int _computeMaxRegionCount() {
    if (_statsService.dataAdcodes.isEmpty) return 1;
    var maxCount = 1;
    for (final r in _activeRegions) {
      final c = _statsService.regionTotalCount(
        r,
        showDistrictLayer: _showDistrictLayer,
      );
      if (c > maxCount) maxCount = c;
    }
    return maxCount;
  }

  List<Polygon<String>> _buildPolygonsForRegion(GeoRegion region) {
    final showStrongDetail = _currentZoom >= _districtDetailZoom;
    final hasGeoData = _statsService.dataAdcodes.isNotEmpty;
    final isSelected = region.id == _selectedRegionId;
    final hasData = _statsService.regionHasData(
      region,
      showDistrictLayer: _showDistrictLayer,
    );
    final count = hasData
        ? _statsService.regionTotalCount(
            region,
            showDistrictLayer: _showDistrictLayer,
          )
        : 0;
    final ratio = _maxRegionCount > 1
        ? (count / _maxRegionCount).clamp(0.0, 1.0)
        : 0.0;

    return [
      for (final shape in region.polygons)
        Polygon<String>(
          points: shape.outer,
          holePointsList: shape.holes.isEmpty ? null : shape.holes,
          color: _statsService.regionFillColor(
            hasGeoData: hasGeoData,
            hasData: hasData,
            isSelected: isSelected,
            severityRatio: ratio,
            successColor: context.colors.success,
            errorColor: context.colors.error,
          ),
          borderColor: _statsService.regionBorderColor(
            hasGeoData: hasGeoData,
            hasData: hasData,
            isSelected: isSelected,
            severityRatio: ratio,
            successColor: context.colors.success,
            errorColor: context.colors.error,
          ),
          borderStrokeWidth: isSelected
              ? (showStrongDetail ? 3.2 : 2.8)
              : (hasGeoData && hasData
                    ? (showStrongDetail ? 2.2 : 1.6)
                    : (showStrongDetail ? 1.8 : 1.1)),
          hitValue: region.id,
          label: null,
        ),
    ];
  }

  Marker _buildLabelForRegion(GeoRegion region) {
    final hasGeoData = _statsService.dataAdcodes.isNotEmpty;
    final isSelected = region.id == _selectedRegionId;
    final hasData = _statsService.regionHasData(
      region,
      showDistrictLayer: _showDistrictLayer,
    );
    final dim = hasGeoData && !hasData;
    return Marker(
      point: region.center,
      width: isSelected
          ? (_showDistrictLayer ? 92 : 100)
          : (_showDistrictLayer ? 84 : 96),
      height: isSelected ? 28 : 24,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: context.colors.canvas.withValues(
                alpha: dim ? 0.78 : (isSelected ? 0.92 : 0.82),
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
                    ? context.colors.error
                    : dim
                    ? context.colors.muted
                    : context.colors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const double _popupCardWidth = 320;
  static const double _popupCardHeight = 226;

  /// 统计卡片弹窗，用 [Positioned] 画在地图图层*外面*（跟右上角提示条是
  /// 同一层级），不再放进 flutter_map 的 [MarkerLayer]。
  ///
  /// 之前几版都是把卡片当成 flutter_map 的 [Marker]放在图层内部，反复
  /// 在"该用哪个坐标系换算像素"上出错——flutter_map 内部图层坐标系和
  /// 外部 widget 坐标系并不通用，靠猜很容易猜错。
  /// [MapCamera.latLngToScreenOffset] 官方文档明确写的就是"给 FlutterMap
  /// 图层*之外*的 widget 用、配合 Positioned"，现在卡片本身也确实是画在
  /// 图层外面的 Positioned 里，用法和文档描述完全对应，不用再猜。
  /// 越界裁剪也不再依赖 camera 的视口尺寸估算，直接用 [LayoutBuilder]
  /// 拿到地图容器的真实渲染尺寸来夹限，这部分是纯 Flutter 布局机制，
  /// 跟 flutter_map 内部实现无关，可以完全确定行为正确。
  Widget _buildDiseaseInfoOverlay(Size viewportSize) {
    final region = _popupRegion;
    final summary = _popupSummary;
    if (region == null || summary == null || summary.isEmpty) {
      // 注意：这里必须返回一个 Positioned（哪怕内容是空的），不能直接
      // 返回裸的 SizedBox.shrink()。Stack 在"没有任何非 Positioned 子项"
      // 时才会撑满可用空间；一旦出现哪怕一个非 Positioned 子项（比如裸的
      // SizedBox.shrink()），Stack 就会改成"收缩到刚好包住非 Positioned
      // 子项"的模式——由于这个子项是 0 大小，整个 Stack（连带整张地图）
      // 会直接收缩成一条线，这正是"地图变成竖线"的真实原因。
      return const Positioned(
        left: 0,
        top: 0,
        child: SizedBox.shrink(),
      );
    }
    if (viewportSize.width <= 0 || viewportSize.height <= 0) {
      return const Positioned(
        left: 0,
        top: 0,
        child: SizedBox.shrink(),
      );
    }

    final anchor = _popupAnchorForRegion(region);
    final scale = MiuixMotion.scaleForFraction(_popupFractionCtrl.value);
    final opacity = _popupAlphaCtrl.value.clamp(0.0, 1.0);

    // 位置/朝向的起点有两种情况：
    // - 全新弹出（_popupFromRegion 为空）：从"区域自己的中心 +
    //   Alignment.center"过渡到贴边锚点，进度用 _popupFractionCtrl（跟
    //   缩放/透明度同步），也就是"从区域中心生长出来"的效果；
    // - 从另一个已展开的弹窗切换过来：从"上一个区域的贴边锚点"过渡到
    //   "新区域的贴边锚点"，进度用专门的 _popupMorphCtrl，缩放/透明度
    //   全程保持在"已展开"状态不变——纯平移，不整个收起再重新弹出。
    final fromRegion = _popupFromRegion;
    final ({LatLng point, Alignment alignment}) fromAnchor;
    final double shapeFraction;
    if (fromRegion != null) {
      fromAnchor = _popupAnchorForRegion(fromRegion);
      shapeFraction = _popupMorphCtrl.value.clamp(0.0, 1.0);
    } else {
      fromAnchor = (point: region.center, alignment: Alignment.center);
      shapeFraction = _popupFractionCtrl.value.clamp(0.0, 1.0);
    }

    final animatedAlignment = Alignment.lerp(
      fromAnchor.alignment,
      anchor.alignment,
      shapeFraction,
    )!;
    final animatedPoint = LatLng(
      fromAnchor.point.latitude +
          (anchor.point.latitude - fromAnchor.point.latitude) * shapeFraction,
      fromAnchor.point.longitude +
          (anchor.point.longitude - fromAnchor.point.longitude) *
              shapeFraction,
    );

    final camera = _mapController.camera;
    final anchorPx = camera.latLngToScreenOffset(animatedPoint);
    final rawLeft =
        anchorPx.dx - _popupCardWidth * (animatedAlignment.x + 1) / 2;
    final rawTop =
        anchorPx.dy - _popupCardHeight * (animatedAlignment.y + 1) / 2;

    const margin = 8.0;
    final maxLeft = viewportSize.width - _popupCardWidth - margin;
    final maxTop = viewportSize.height - _popupCardHeight - margin;
    final left = maxLeft >= margin
        ? rawLeft.clamp(margin, maxLeft)
        : (viewportSize.width - _popupCardWidth) / 2;
    final top = maxTop >= margin
        ? rawTop.clamp(margin, maxTop)
        : (viewportSize.height - _popupCardHeight) / 2;

    return Positioned(
      left: left,
      top: top,
      width: _popupCardWidth,
      height: _popupCardHeight,
      child: IgnorePointer(
        ignoring: opacity < 0.05,
        child: RepaintBoundary(
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              alignment: animatedAlignment,
              scale: scale,
              child: DiseaseChartMarker(summary: summary),
            ),
          ),
        ),
      ),
    );
  }

  // ---- 交互处理 ----

  /// 根据当前选中区域是否有可展示的统计数据，驱动统计卡片的弹出/收起
  /// 动画（复用 [MiuixDropdownMenu] 同款弹簧参数）。凡是修改了
  /// [_selectedRegionId] 的地方，都应该在 setState 之后调用一次本方法。
  void _syncPopupForSelection() {
    final region = _selectedRegion;
    final summary = region == null
        ? null
        : _statsService.getDiseaseSummary(
            region.id,
            showDistrictLayer: _showDistrictLayer,
          );

    if (region != null && summary != null && summary.isNotEmpty) {
      final previousRegion = _popupRegion;
      final isNewRegion = previousRegion?.id != region.id;
      _popupToken++;

      if (!isNewRegion) {
        // 同一个区域，数据可能刷新了，内容更新一下就行，不用重播动画。
        setState(() {
          _popupRegion = region;
          _popupSummary = summary;
        });
        return;
      }

      // 已经有一个弹窗展开着（哪怕正在收起途中），这次是切换到另一个
      // 区域——参考 iOS / HyperOS 的可打断动画：不整个收起归零再重新
      // 弹出，而是保持"已展开"的缩放/透明度不变，只把位置从旧锚点平移
      // 到新锚点，动画可以在半路被新的一次点击再次打断、重定向。
      final alreadyOpen = previousRegion != null && _popupFractionCtrl.value > 0.01;

      setState(() {
        _popupFromRegion = alreadyOpen ? previousRegion : null;
        _popupRegion = region;
        _popupSummary = summary;
      });

      if (alreadyOpen) {
        _popupFractionCtrl
          ..stop()
          ..value = 1;
        _popupAlphaCtrl
          ..stop()
          ..value = 1;
        final morphVelocity = _popupMorphCtrl.isAnimating
            ? _popupMorphCtrl.velocity
            : 0.0;
        _popupMorphCtrl
          ..stop()
          ..value = 0
          ..animateWith(
            SpringSimulation(MiuixMotion.spring, 0, 1, morphVelocity),
          );
      } else {
        _popupMorphCtrl
          ..stop()
          ..value = 1;
        _popupFractionCtrl
          ..stop()
          ..value = 0
          ..animateWith(SpringSimulation(MiuixMotion.spring, 0, 1, 0));
        _popupAlphaCtrl
          ..value = 0
          ..animateTo(
            1,
            duration: MiuixMotion.alphaEnterDuration,
            curve: Curves.fastOutSlowIn,
          );
      }
      return;
    }

    if (_popupRegion == null) return; // 本来就没显示，不需要播放收起动画

    final token = ++_popupToken;
    final fractionVelocity = _popupFractionCtrl.isAnimating
        ? _popupFractionCtrl.velocity
        : 0.0;
    _popupFractionCtrl.animateWith(
      SpringSimulation(
        MiuixMotion.spring,
        _popupFractionCtrl.value,
        0,
        fractionVelocity,
      ),
    );
    _popupAlphaCtrl
        .animateTo(
          0,
          duration: MiuixMotion.alphaExitDuration,
          curve: Curves.fastOutSlowIn,
        )
        .then((_) {
          if (!mounted || token != _popupToken) return;
          _popupFractionCtrl.stop();
          setState(() {
            _popupRegion = null;
            _popupSummary = null;
            _popupFromRegion = null;
          });
        });
  }

  void _handlePolygonTap() {
    final hit = _hitNotifier.value;
    final hitId = hit?.hitValues.isNotEmpty == true
        ? hit!.hitValues.first
        : null;
    if (hitId == null) return;

    if (hitId == _selectedRegionId) {
      final previousId = _selectedRegionId!;
      setState(() {
        _selectedRegionId = null;
      });
      _scheduleUpdateRegionHighlight([previousId]);
      _syncPopupForSelection();
      return;
    }

    GeoRegion? tappedRegion;
    for (final r in _activeRegions) {
      if (r.id == hitId) {
        tappedRegion = r;
        break;
      }
    }

    final previousId = _selectedRegionId;
    setState(() {
      if (tappedRegion != null &&
          _statsService.regionHasData(
            tappedRegion,
            showDistrictLayer: _showDistrictLayer,
          )) {
        _selectedRegionId = hitId;
      } else {
        _selectedRegionId = null;
      }
    });
    _scheduleUpdateRegionHighlight([
      if (previousId != null) previousId,
      if (_selectedRegionId != null) _selectedRegionId!,
    ]);
    _syncPopupForSelection();
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

  /// 计算统计卡片的地图锚点，以及卡片相对锚点的对齐方式。
  ///
  /// 之前只返回一个"贴着区域外侧一点"的 LatLng，但 [Marker] 默认按
  /// [Alignment.center] 把卡片*居中*画在这个点上——卡片有一半宽/高会
  /// 折回区域内部，选中区域还是被挡住一半。现在改成返回
  /// `(point, alignment)`：alignment 跟随锚点相对区域的方位（比如锚点在
  /// 区域正上方，就用 [Alignment.bottomCenter] 让卡片的下边贴着锚点、
  /// 整个卡片朝上展开），卡片会完全长在区域外侧，不会再盖住选中区域。
  ({LatLng point, Alignment alignment}) _popupAnchorForRegion(
    GeoRegion region,
  ) {
    final bounds = _regionBounds(region);
    final camera = _mapController.camera;
    final vc = camera.center;
    final z = camera.zoom;
    final halfLat = 360 / (1 << z.clamp(5, 18).toInt());
    final halfLng = halfLat * 1.6;

    // margin 是"锚点离区域边界多远"，不能只按区域自身包围盒算：区/县级别
    // 缩放很深时，视口本身只能看到零点几公里，region 包围盒虽小，但固定
    // 的角度下限（0.08°）却可能比半个视口还大，直接把锚点甩到屏幕外几倍
    // 远的地方——不仅越界，marker 本身的经纬度点离视口太远时还可能被
    // flutter_map 当成"视口外"直接跳过渲染，导致 Transform 位移修正根本
    // 没机会生效。这里把上限和下限都额外用当前半视口（halfLat/halfLng）
    // 的一个比例夹住，保证锚点无论缩放到多深都停留在视口附近。
    final latMarginCap = math.min(0.32, halfLat * 0.6);
    final latMarginFloor = math.min(0.08, latMarginCap);
    final latMargin = ((bounds.north - bounds.south) * 0.35).clamp(
      latMarginFloor,
      latMarginCap,
    );
    final lngMarginCap = math.min(0.36, halfLng * 0.6);
    final lngMarginFloor = math.min(0.08, lngMarginCap);
    final lngMargin = ((bounds.east - bounds.west) * 0.35).clamp(
      lngMarginFloor,
      lngMarginCap,
    );

    final candidates = <({LatLng point, Alignment alignment})>[
      (
        point: LatLng(bounds.north + latMargin, region.center.longitude),
        alignment: Alignment.bottomCenter,
      ),
      (
        point: LatLng(bounds.south - latMargin, region.center.longitude),
        alignment: Alignment.topCenter,
      ),
      (
        point: LatLng(region.center.latitude, bounds.east + lngMargin),
        alignment: Alignment.centerLeft,
      ),
      (
        point: LatLng(region.center.latitude, bounds.west - lngMargin),
        alignment: Alignment.centerRight,
      ),
      (
        point: LatLng(bounds.north + latMargin, bounds.east + lngMargin),
        alignment: Alignment.bottomLeft,
      ),
      (
        point: LatLng(bounds.north + latMargin, bounds.west - lngMargin),
        alignment: Alignment.bottomRight,
      ),
      (
        point: LatLng(bounds.south - latMargin, bounds.east + lngMargin),
        alignment: Alignment.topLeft,
      ),
      (
        point: LatLng(bounds.south - latMargin, bounds.west - lngMargin),
        alignment: Alignment.topRight,
      ),
    ];
    var best = candidates.first;
    double bestScore = double.negativeInfinity;

    final popupHalfLat = halfLat * 0.34;
    final popupHalfLng = halfLng * 0.42;
    final avoidLatPad = (bounds.north - bounds.south) * 0.08;
    final avoidLngPad = (bounds.east - bounds.west) * 0.08;
    final avoidNorth = bounds.north + avoidLatPad;
    final avoidSouth = bounds.south - avoidLatPad;
    final avoidEast = bounds.east + avoidLngPad;
    final avoidWest = bounds.west - avoidLngPad;

    for (final candidate in candidates) {
      final c = candidate.point;
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

      // Prefer candidates closer to region center (subtract distance, not add)
      final distanceFromCenter =
          (c.latitude - region.center.latitude).abs() +
          (c.longitude - region.center.longitude).abs();
      final centerPreference = 0.8 - (latRatio.abs() + lngRatio.abs()) * 0.35;
      final score =
          -(distanceFromCenter * 3.2) +
          centerPreference -
          edgePenalty -
          overlapPenalty;
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return (point: best.point, alignment: best.alignment);
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
    if (_lastIsDark != context.isDarkMode) {
      // 亮度变化后，_cachedPolygons/_cachedLabels 里缓存的颜色是旧主题算出来的，
      // 这里强制重新计算一次，避免地图图层颜色和其余 UI 不同步。
      _lastIsDark = context.isDarkMode;
      _rebuildCache();
    }
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colors.canvas,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: context.colors.primary),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: context.colors.canvas,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  color: context.colors.ink,
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
      backgroundColor: context.colors.canvas,
      appBar: AppBar(
        backgroundColor: context.colors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          '管理员首页',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            color: context.colors.ink,
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

    final hasData =
        selectedRegion != null &&
        _statsService.regionHasData(
          selectedRegion,
          showDistrictLayer: _showDistrictLayer,
        );

    final subtitle = hasData
        ? '当前选中${_showDistrictLayer ? '区县' : '地市'}'
        : (selectedRegion == null
              ? detailLevelText
              : '当前选中${_showDistrictLayer ? '区县' : '地市'} — 暂无病害数据');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: context.colors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.colors.ink,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 12,
              color: context.colors.muted,
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
        color: context.colors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: context.colors.hairline),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = constraints.biggest;
          return Stack(
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
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                        ),
                  initialCenter:
                      selectedRegion?.center ?? currentProvince.center,
                  initialZoom: _initialZoom,
                  minZoom: _minZoom - 2.5,
                  maxZoom: _maxZoom + 3.0,
                  keepAlive: true,
                  cameraConstraint: _dragLimitBounds() == null
                      ? const CameraConstraint.unconstrained()
                      : CameraConstraint.contain(bounds: _dragLimitBounds()!),
                  interactionOptions: const InteractionOptions(
                    flags:
                        InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                  onPositionChanged: (camera, hasGesture) {
                    if (_popupRegion != null) {
                      _cameraTick.value++;
                    }
                    final zoom = camera.zoom;
                    if (mounted && (zoom - _currentZoom).abs() >= 0.05) {
                      final shouldShowDistrictLayer =
                          zoom >= _districtLabelZoom;
                      setState(() {
                        _currentZoom = zoom;
                        if (shouldShowDistrictLayer != _showDistrictLayer) {
                          _showDistrictLayer = shouldShowDistrictLayer;
                        }
                      });
                      _scheduleRebuildCache();
                      _syncPopupForSelection();
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
                    final previousId = _selectedRegionId!;
                    setState(() {
                      _selectedRegionId = null;
                    });
                    _scheduleUpdateRegionHighlight([previousId]);
                    _syncPopupForSelection();
                  },
                ),
                children: [
                  Container(color: context.colors.canvas),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
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
                        MarkerLayer(markers: _cachedLabels),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(color: context.colors.hairline),
              ),
              child: Text(
                '默认显示市级，放大后切换到县区级',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 12,
                  color: context.colors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // 统计卡片弹窗：画在地图图层外面，跟随弹出/收起动画以及地图
          // 平移/缩放（通过 _cameraTick 触发重建）实时重新定位。
          AnimatedBuilder(
            animation: Listenable.merge([
              _popupFractionCtrl,
              _popupAlphaCtrl,
              _popupMorphCtrl,
              _cameraTick,
            ]),
            builder: (context, _) => _buildDiseaseInfoOverlay(viewportSize),
          ),
        ],
      );
        },
      ),
    );
  }
}
