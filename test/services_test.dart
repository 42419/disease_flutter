import 'dart:convert';

import 'package:farm_flutter/models/map_models.dart';
import 'package:farm_flutter/services/disease_stats_service.dart';
import 'package:farm_flutter/services/region_option_loader.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  // ==================== DiseaseStatsService ====================
  group('DiseaseStatsService', () {
    late DiseaseStatsService service;

    setUp(() {
      service = DiseaseStatsService();
    });

    group('regionHasData', () {
      test('区域 id 直接匹配时返回 true', () {
        service.dataAdcodes.add('210701');
        final region = GeoRegion(
          id: '210701', name: '太和区', level: 'district',
          parentAdcode: '210700', center: LatLng(41, 121), polygons: [],
        );
        expect(service.regionHasData(region, showDistrictLayer: true), isTrue);
        expect(service.regionHasData(region, showDistrictLayer: false), isTrue);
      });

      test('区县级：父级有数据且自身无数据时返回 true', () {
        service.dataAdcodes.add('210700');
        final region = GeoRegion(
          id: '210701', name: '太和区', level: 'district',
          parentAdcode: '210700', center: LatLng(41, 121), polygons: [],
        );
        expect(service.regionHasData(region, showDistrictLayer: true), isTrue);
      });

      test('区县级：父级在 cityCodesWithDistrictData 中时返回 false', () {
        // 使用一个不在 dataAdcodes 中的区县 id
        // 其父级 cityCode 在 cityCodesWithDistrictData 中
        service.cityCodesWithDistrictData.add('210700');
        final region = GeoRegion(
          id: '210709', name: '某新区', level: 'district',
          parentAdcode: '210700', center: LatLng(41, 121), polygons: [],
        );
        expect(service.regionHasData(region, showDistrictLayer: true), isFalse);
      });

      test('地市级：下辖有病害数据的区县时返回 true', () {
        service.dataAdcodes.add('210701');
        service.cityCodesWithDistrictData.add('210700');
        final region = GeoRegion(
          id: '210700', name: '锦州市', level: 'city',
          parentAdcode: '210000', center: LatLng(41, 121), polygons: [],
        );
        expect(service.regionHasData(region, showDistrictLayer: false), isTrue);
      });

      test('地市级：无任何下辖数据时返回 false', () {
        final region = GeoRegion(
          id: '210700', name: '锦州市', level: 'city',
          parentAdcode: '210000', center: LatLng(41, 121), polygons: [],
        );
        expect(service.regionHasData(region, showDistrictLayer: false), isFalse);
      });

      test('无数据时返回 false', () {
        final region = GeoRegion(
          id: '999999', name: '无数据区', level: 'district',
          parentAdcode: null, center: LatLng(41, 121), polygons: [],
        );
        expect(service.regionHasData(region, showDistrictLayer: true), isFalse);
      });
    });

    group('regionTotalCount', () {
      test('地市级统计：汇总所有下辖区域', () {
        service.diseaseStatsByCode['210701'] = {'苹果黑斑病': 3, '白粉病': 1};
        service.diseaseStatsByCode['210702'] = {'锈病': 2};

        final region = GeoRegion(
          id: '210700', name: '锦州市', level: 'city',
          parentAdcode: '210000', center: LatLng(41, 121), polygons: [],
        );
        // 地市级取前4位匹配
        expect(service.regionTotalCount(region, showDistrictLayer: false), 6);
      });

      test('区县级统计：精确匹配', () {
        service.diseaseStatsByCode['210701'] = {'苹果黑斑病': 3};

        final region = GeoRegion(
          id: '210701', name: '太和区', level: 'district',
          parentAdcode: '210700', center: LatLng(41, 121), polygons: [],
        );
        expect(service.regionTotalCount(region, showDistrictLayer: true), 3);
      });

      test('无数据时返回 0', () {
        final region = GeoRegion(
          id: '999999', name: '无数据', level: 'city',
          parentAdcode: null, center: LatLng(41, 121), polygons: [],
        );
        expect(service.regionTotalCount(region, showDistrictLayer: false), 0);
      });
    });

    group('getDiseaseSummary', () {
      test('汇总并按数量降序排列', () {
        service.diseaseStatsByCode['210701'] = {'苹果黑斑病': 3, '白粉病': 1};
        service.diseaseStatsByCode['210702'] = {'苹果黑斑病': 2, '锈病': 4};

        final summary = service.getDiseaseSummary(
          '210700',
          showDistrictLayer: false,
        );

        // 苹果黑斑病: 3+2=5, 锈病: 4, 白粉病: 1
        expect(summary.length, 3);
        expect(summary[0].key, '苹果黑斑病');
        expect(summary[0].value, 5);
        expect(summary[1].key, '锈病');
        expect(summary[1].value, 4);
        expect(summary[2].key, '白粉病');
        expect(summary[2].value, 1);
      });

      test('无匹配数据时返回空列表', () {
        service.diseaseStatsByCode['210701'] = {'病': 1};
        final summary = service.getDiseaseSummary(
          '999999',
          showDistrictLayer: false,
        );
        expect(summary, isEmpty);
      });
    });

    group('regionFillColor', () {
      test('有 Geo 数据但无病害数据时返回绿色', () {
        final color = service.regionFillColor(
          hasGeoData: true, hasData: false,
          isSelected: false, severityRatio: 0,
        );
        expect(color, AppColors.success.withValues(alpha: 0.30));
      });

      test('无 Geo 数据时返回浅绿色', () {
        final color = service.regionFillColor(
          hasGeoData: false, hasData: false,
          isSelected: false, severityRatio: 0,
        );
        expect(color, AppColors.success.withValues(alpha: 0.16));
      });

      test('选中状态颜色更深', () {
        final unselected = service.regionFillColor(
          hasGeoData: true, hasData: false,
          isSelected: false, severityRatio: 0,
        );
        final selected = service.regionFillColor(
          hasGeoData: true, hasData: false,
          isSelected: true, severityRatio: 0,
        );
        // selected 应该 alpha 更高
        expect(selected.a, greaterThan(unselected.a));
      });

      test('severityRatio 影响颜色', () {
        final low = service.regionFillColor(
          hasGeoData: true, hasData: true,
          isSelected: false, severityRatio: 0.0,
        );
        final high = service.regionFillColor(
          hasGeoData: true, hasData: true,
          isSelected: false, severityRatio: 1.0,
        );
        expect(low, isNot(equals(high)));
      });
    });

    group('regionBorderColor', () {
      test('选中时返回 error 颜色', () {
        final color = service.regionBorderColor(
          hasGeoData: true, hasData: true,
          isSelected: true, severityRatio: 0.5,
        );
        expect(color, AppColors.error);
      });

      test('有 Geo 无病害数据时返回绿色边框', () {
        final color = service.regionBorderColor(
          hasGeoData: true, hasData: false,
          isSelected: false, severityRatio: 0,
        );
        expect(color, AppColors.success.withValues(alpha: 0.82));
      });

      test('无 Geo 数据时返回浅绿边框', () {
        final color = service.regionBorderColor(
          hasGeoData: false, hasData: false,
          isSelected: false, severityRatio: 0,
        );
        expect(color, AppColors.success.withValues(alpha: 0.60));
      });
    });
  });

  // ==================== RegionOptionLoader.parseRegions ====================
  group('RegionOptionLoader.parseRegions', () {
    test('正常解析 GeoJSON features', () {
      final json = jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {
              'adcode': '210700',
              'name': '锦州市',
              'level': 'city',
              'parent': {'adcode': '210000'},
            },
          },
          {
            'type': 'Feature',
            'properties': {
              'adcode': '210100',
              'name': '沈阳市',
              'level': 'city',
            },
          },
        ],
      });

      final regions = RegionOptionLoader.parseRegions(
        json,
        provinceName: '辽宁省',
      );

      expect(regions.length, 2);
      expect(regions[0].adcode, '210700');
      expect(regions[0].name, '辽宁省锦州市');
      expect(regions[0].level, 'city');
      expect(regions[0].parentAdcode, '210000');

      expect(regions[1].adcode, '210100');
      expect(regions[1].name, '辽宁省沈阳市');
      expect(regions[1].parentAdcode, isNull);
    });

    test('带 parentNames 时使用完整父级名称', () {
      final json = jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {
              'adcode': '210701',
              'name': '太和区',
              'level': 'district',
              'parent': {'adcode': '210700'},
            },
          },
        ],
      });

      final regions = RegionOptionLoader.parseRegions(
        json,
        provinceName: '辽宁省',
        parentNames: {'210700': '辽宁省锦州市'},
      );

      expect(regions.length, 1);
      expect(regions[0].name, '辽宁省锦州市太和区');
    });

    test('features 为空列表时返回空结果', () {
      final json = jsonEncode({
        'type': 'FeatureCollection',
        'features': [],
      });

      final regions = RegionOptionLoader.parseRegions(
        json,
        provinceName: '辽宁省',
      );
      expect(regions, isEmpty);
    });

    test('无 features 字段时返回空结果', () {
      final json = jsonEncode({'type': 'FeatureCollection'});
      final regions = RegionOptionLoader.parseRegions(
        json,
        provinceName: '辽宁省',
      );
      expect(regions, isEmpty);
    });

    test('缺少 adcode 或 name 的 feature 被跳过', () {
      final json = jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'properties': {'name': '锦州市'},  // 无 adcode
          },
          {
            'type': 'Feature',
            'properties': {'adcode': '210700'},  // 无 name
          },
          {
            'type': 'Feature',
            'properties': {
              'adcode': '210700',
              'name': '锦州市',
            },
          },
        ],
      });

      final regions = RegionOptionLoader.parseRegions(
        json,
        provinceName: '辽宁省',
      );
      expect(regions.length, 1);
      expect(regions[0].adcode, '210700');
    });

    test('非 Map 类型的 feature 被跳过', () {
      final json = jsonEncode({
        'type': 'FeatureCollection',
        'features': ['invalid', 123, null],
      });

      final regions = RegionOptionLoader.parseRegions(
        json,
        provinceName: '辽宁省',
      );
      expect(regions, isEmpty);
    });
  });
}
