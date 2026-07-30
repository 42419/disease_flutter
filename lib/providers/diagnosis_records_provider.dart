import 'dart:async';

import 'package:farm_flutter/models/diagnosis.dart';
import 'package:farm_flutter/services/region_option_loader.dart';
import 'package:farm_flutter/utils/datetime_util.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:flutter/foundation.dart';

/// 诊断记录数据提供者，负责记录的获取、排序、统计，以及定时轮询刷新。
/// MainPage / AdminMainPage 通过 startTimer / stopTimer 控制轮询生命周期。
class DiagnosisRecordsProvider extends ChangeNotifier {
  List<Diagnosis> _records = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _expandedId;
  bool _sortDescending = true;
  List<MapEntry<String, int>> _stats = [];
  int _fetchGeneration = 0;

  // ---- 地区名称（adcode -> 完整地名），供页面展示定位地区用 ----
  // 之前这段 GeoJSON 解析逻辑直接写在 DiagnosisRecordsPage 里，且和
  // RegionOptionLoader 里的解析逻辑重复了一份；现在统一收拢到这里，复用
  // RegionOptionLoader，页面只读取 [adcodeNameMap]。
  final Map<String, String> _adcodeNameMap = {};
  bool _adcodeNameMapLoaded = false;

  // ---- 定时轮询 ----
  Timer? _refreshTimer;
  DateTime? _lastFetchTime;
  String? _cachedRole;
  String? _cachedNickName;

  /// 轮询间隔
  static const Duration pollInterval = Duration(seconds: 90);

  /// 数据过期阈值
  static const Duration staleThreshold = Duration(seconds: 60);

  List<Diagnosis> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get expandedId => _expandedId;
  bool get sortDescending => _sortDescending;
  List<MapEntry<String, int>> get stats => _stats;
  Map<String, String> get adcodeNameMap => _adcodeNameMap;

  /// 数据是否过期（距上次成功拉取超过 [staleThreshold]）
  bool get isStale =>
      _lastFetchTime == null ||
      DateTime.now().difference(_lastFetchTime!) > staleThreshold;

  void toggleExpanded(int id) {
    _expandedId = _expandedId == id ? null : id;
    notifyListeners();
  }

  void setSortDescending(bool value) {
    _sortDescending = value;
    _resortRecords();
    notifyListeners();
  }

  /// 加载 adcode -> 完整地名 的映射，重复调用是安全的（只会真正加载一次）。
  Future<void> loadAdcodeNameMap() async {
    if (_adcodeNameMapLoaded) return;
    try {
      final regions = await const RegionOptionLoader()
          .loadCurrentProvinceRegions();
      _adcodeNameMap
        ..clear()
        ..addEntries(regions.map((r) => MapEntry(r.adcode, r.name)));
      _adcodeNameMapLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('加载地区名称失败: $e');
    }
  }

  String locationName(String? adcode) {
    if (adcode == null || adcode.isEmpty) return '';
    return _adcodeNameMap[adcode] ?? adcode;
  }

  // ---- Timer 生命周期 ----

  /// 启动定时轮询。重复调用安全，会先取消旧 Timer。
  void startTimer({required String role, required String nickName}) {
    _cachedRole = role;
    _cachedNickName = nickName;
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(pollInterval, (_) {
      if (isStale && _cachedRole != null && _cachedNickName != null) {
        fetchRecords(role: _cachedRole!, nickName: _cachedNickName!);
      }
    });
  }

  /// 停止定时轮询（App 切后台时调用）。
  void stopTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// 清空所有状态（退出登录时调用）。
  void clear() {
    stopTimer();
    _records = [];
    _stats = [];
    _errorMessage = null;
    _expandedId = null;
    _cachedRole = null;
    _cachedNickName = null;
    _lastFetchTime = null;
    _isLoading = true;
    notifyListeners();
  }

  /// 立即刷新（App 恢复前台时调用），仅在数据过期时实际请求。
  void refreshIfStale() {
    if (isStale && _cachedRole != null && _cachedNickName != null) {
      fetchRecords(role: _cachedRole!, nickName: _cachedNickName!);
    }
  }

  @override
  void dispose() {
    stopTimer();
    super.dispose();
  }

  void _resortRecords() {
    _records.sort((a, b) {
      final da = DateTimeUtil.parseFlexible(a.dtime);
      final db = DateTimeUtil.parseFlexible(b.dtime);
      return _sortDescending ? db.compareTo(da) : da.compareTo(db);
    });
  }

  List<Diagnosis> _filterRecords(
    List<Diagnosis> all, {
    required String role,
    required String nickName,
  }) {
    List<Diagnosis> filtered;
    if (role == '1') {
      filtered = all.toList();
    } else {
      filtered = all.where((r) => r.username == nickName).toList();
    }
    filtered.sort((a, b) {
      final da = DateTimeUtil.parseFlexible(a.dtime);
      final db = DateTimeUtil.parseFlexible(b.dtime);
      return _sortDescending ? db.compareTo(da) : da.compareTo(db);
    });
    return filtered;
  }

  Future<void> fetchRecords({
    required String role,
    required String nickName,
  }) async {
    final generation = ++_fetchGeneration;
    _cachedRole = role;
    _cachedNickName = nickName;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 默认后端的 X-API-Token 由 HttpUtil 统一自动注入，无需在这里手传。
      final resp = await HttpUtil.get('/get_all_dg');

      // 跳过过期请求的结果
      if (generation != _fetchGeneration) return;

      if (resp is Map && resp['data'] is List) {
        final all = (resp['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => Diagnosis.fromJson(e))
            .toList();
        final filtered = _filterRecords(all, role: role, nickName: nickName);
        final countMap = <String, int>{};
        for (final r in filtered) {
          final name = r.bhname.isNotEmpty ? r.bhname : '未知';
          countMap[name] = (countMap[name] ?? 0) + 1;
        }
        final stats = countMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        _records = filtered;
        _stats = stats;
        _lastFetchTime = DateTime.now();
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _errorMessage = '数据格式异常';
        notifyListeners();
      }
    } catch (e) {
      if (generation != _fetchGeneration) return;
      _isLoading = false;
      _errorMessage = '加载失败: $e';
      notifyListeners();
    }
  }
}
