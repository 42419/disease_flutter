import 'dart:convert';

import 'package:farm_flutter/config/province_config.dart';
import 'package:flutter/services.dart';

class RegionOption {
  final String adcode;
  final String name;
  final String level;
  final String? parentAdcode;

  const RegionOption({
    required this.adcode,
    required this.name,
    required this.level,
    this.parentAdcode,
  });
}

class RegionOptionLoader {
  const RegionOptionLoader();

  Future<List<RegionOption>> loadCurrentProvinceRegions() async {
    final cityJson = await rootBundle.loadString(
      currentProvince.cityGeoJsonPath,
    );
    final districtJson = await rootBundle.loadString(
      currentProvince.districtGeoJsonPath,
    );

    final cities = parseRegions(cityJson, provinceName: currentProvince.name);
    final cityNames = {for (final city in cities) city.adcode: city.name};
    final districts = parseRegions(
      districtJson,
      provinceName: currentProvince.name,
      parentNames: cityNames,
    );

    return [...districts, ...cities];
  }

  static List<RegionOption> parseRegions(
    String rawJson, {
    required String provinceName,
    Map<String, String> parentNames = const {},
  }) {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final features = decoded['features'];
    if (features is! List) return const [];

    final regions = <RegionOption>[];
    for (final feature in features) {
      if (feature is! Map) continue;
      final props = feature['properties'];
      if (props is! Map) continue;

      final adcode = props['adcode']?.toString();
      final rawName = props['name']?.toString();
      if (adcode == null ||
          adcode.isEmpty ||
          rawName == null ||
          rawName.isEmpty) {
        continue;
      }

      final parent = props['parent'];
      final parentAdcode = parent is Map ? parent['adcode']?.toString() : null;
      final parentName = parentAdcode == null
          ? null
          : parentNames[parentAdcode];
      final fullName = parentName == null
          ? '$provinceName$rawName'
          : '$parentName$rawName';

      regions.add(
        RegionOption(
          adcode: adcode,
          name: fullName,
          level: props['level']?.toString() ?? '',
          parentAdcode: parentAdcode,
        ),
      );
    }

    return regions;
  }
}
