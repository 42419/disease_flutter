import 'package:farm_flutter/config/config.dart';
import 'package:farm_flutter/models/map_models.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:flutter/material.dart';

/// 病害数据统计服务：负责从后端拉取诊断数据、计算区域病害统计和颜色。
class DiseaseStatsService {
  final Set<String> dataAdcodes = {};
  final Set<String> cityCodesWithDistrictData = {};
  final Map<String, Map<String, int>> diseaseStatsByCode = {};

  /// 从后端拉取全部诊断记录并解析为统计结构。
  Future<void> fetchDiseaseData() async {
    try {
      final resp = await HttpUtil.get(
        '/get_all_dg',
        headers: {'X-API-Token': Config.apiToken},
      );
      if (resp is Map && resp['data'] is List) {
        final dataList = resp['data'] as List;
        dataAdcodes.clear();
        final tempStats = <String, Map<String, int>>{};
        for (final item in dataList) {
          if (item is Map) {
            final loc = item['location']?.toString().trim();
            final name = item['bhname']?.toString().trim();
            if (loc == null || loc.isEmpty || loc == 'null') continue;
            if (name == null || name.isEmpty) continue;
            dataAdcodes.add(loc);
            tempStats.putIfAbsent(loc, () => {});
            tempStats[loc]!.update(name, (c) => c + 1, ifAbsent: () => 1);
          }
        }
        diseaseStatsByCode.clear();
        diseaseStatsByCode.addAll(tempStats);
      }
      cityCodesWithDistrictData.clear();
      for (final adcode in dataAdcodes) {
        if (adcode.length == 6 && !adcode.endsWith('00')) {
          cityCodesWithDistrictData.add('${adcode.substring(0, 4)}00');
        }
      }
    } catch (e) {
      debugPrint('fetch disease data failed: $e');
    }
  }

  /// 判断指定区域是否有病害数据。
  bool regionHasData(GeoRegion region, {required bool showDistrictLayer}) {
    if (dataAdcodes.contains(region.id)) return true;
    if (showDistrictLayer && region.parentAdcode != null) {
      if (cityCodesWithDistrictData.contains(region.parentAdcode)) {
        return false;
      }
      if (dataAdcodes.contains(region.parentAdcode)) {
        return true;
      }
    }
    if (!showDistrictLayer &&
        region.id.length == 6 &&
        region.id.endsWith('00')) {
      return cityCodesWithDistrictData.contains(region.id);
    }
    return false;
  }

  /// 计算指定区域的病害总数。
  int regionTotalCount(GeoRegion region, {required bool showDistrictLayer}) {
    final isCityLevel = !showDistrictLayer;
    final prefix = isCityLevel ? region.id.substring(0, 4) : region.id;
    int total = 0;
    for (final entry in diseaseStatsByCode.entries) {
      if (entry.key.startsWith(prefix)) {
        total += entry.value.values.fold(0, (s, c) => s + c);
      }
    }
    return total;
  }

  /// 获取指定区域的病害汇总（名称 → 数量），按数量降序。
  List<MapEntry<String, int>> getDiseaseSummary(
    String regionId, {
    required bool showDistrictLayer,
  }) {
    final merged = <String, int>{};
    final isCityLevel = !showDistrictLayer;
    final prefix = isCityLevel ? regionId.substring(0, 4) : regionId;

    for (final entry in diseaseStatsByCode.entries) {
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

  /// 根据区域状态计算填充颜色。
  Color regionFillColor({
    required bool hasGeoData,
    required bool hasData,
    required bool isSelected,
    required double severityRatio,
  }) {
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

  /// 根据区域状态计算边框颜色。
  Color regionBorderColor({
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
}
