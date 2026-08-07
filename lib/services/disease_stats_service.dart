import 'package:farm_flutter/config/province_config.dart';
import 'package:farm_flutter/models/diagnosis.dart';
import 'package:farm_flutter/models/map_models.dart';
import 'package:flutter/material.dart';

/// 病害数据统计服务：负责把诊断记录解析成区域病害统计、计算地图着色。
class DiseaseStatsService {
  final Set<String> dataAdcodes = {};
  final Set<String> cityCodesWithDistrictData = {};
  final Map<String, Map<String, int>> diseaseStatsByCode = {};

  /// 根据 [records] 重新计算区域病害统计，纯内存计算，不发网络请求。
  void updateFromRecords(List<Diagnosis> records, {String? adcodePrefix}) {
    final prefix = adcodePrefix ?? currentProvince.adcodePrefix;
    dataAdcodes.clear();
    final tempStats = <String, Map<String, int>>{};
    for (final r in records) {
      final loc = r.location?.trim();
      final name = r.bhname.trim();
      if (loc == null || loc.isEmpty || loc == 'null') continue;
      if (name.isEmpty) continue;
      if (prefix.isNotEmpty && !loc.startsWith(prefix)) continue;
      dataAdcodes.add(loc);
      tempStats.putIfAbsent(loc, () => {});
      tempStats[loc]!.update(name, (c) => c + 1, ifAbsent: () => 1);
    }
    diseaseStatsByCode.clear();
    diseaseStatsByCode.addAll(tempStats);

    cityCodesWithDistrictData.clear();
    for (final adcode in dataAdcodes) {
      if (adcode.length == 6 && !adcode.endsWith('00')) {
        cityCodesWithDistrictData.add('${adcode.substring(0, 4)}00');
      }
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
    if (!region.id.startsWith(RegExp(r'^\d{4,6}$'))) return 0;
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
    if (!regionId.startsWith(RegExp(r'^\d{4,6}$'))) return [];
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
  ///
  /// [successColor] / [errorColor] 由调用方（有 BuildContext 的 Widget）
  /// 传入当前主题下的语义色，服务层本身不持有全局配色状态。
  Color regionFillColor({
    required bool hasGeoData,
    required bool hasData,
    required bool isSelected,
    required double severityRatio,
    required Color successColor,
    required Color errorColor,
  }) {
    if (hasGeoData && !hasData) {
      return isSelected
          ? successColor.withValues(alpha: 0.46)
          : successColor.withValues(alpha: 0.30);
    }
    if (!hasGeoData) {
      return isSelected
          ? successColor.withValues(alpha: 0.24)
          : successColor.withValues(alpha: 0.16);
    }

    final baseRed = Color.lerp(
      errorColor.withValues(alpha: 0.24),
      errorColor.withValues(alpha: 0.68),
      severityRatio,
    )!;
    return isSelected
        ? Color.lerp(baseRed, errorColor.withValues(alpha: 0.82), 0.35)!
        : baseRed;
  }

  /// 根据区域状态计算边框颜色。
  Color regionBorderColor({
    required bool hasGeoData,
    required bool hasData,
    required bool isSelected,
    required double severityRatio,
    required Color successColor,
    required Color errorColor,
  }) {
    if (isSelected) return errorColor;
    if (hasGeoData && !hasData) {
      return successColor.withValues(alpha: 0.82);
    }
    if (!hasGeoData) {
      return successColor.withValues(alpha: 0.60);
    }
    return Color.lerp(
      errorColor.withValues(alpha: 0.58),
      errorColor.withValues(alpha: 0.92),
      severityRatio,
    )!;
  }
}
