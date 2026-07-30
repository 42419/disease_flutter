import 'dart:convert';

import 'package:farm_flutter/models/diagnosis.dart';
import 'package:farm_flutter/models/map_models.dart';
import 'package:farm_flutter/models/prediction_result.dart';
import 'package:farm_flutter/models/user.dart';
import 'package:farm_flutter/services/auth_storage.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  // ==================== Diagnosis ====================
  group('Diagnosis', () {
    group('fromJson', () {
      test('正常解析完整字段', () {
        final json = {
          'id': 1,
          'imgname': 'test.jpg',
          'bhname': '苹果黑斑病',
          'bhreason': '链格孢菌',
          'bhadvice': '喷洒杀菌剂',
          'username': 'testuser',
          'location': '210711',
          'dtime': '2026-05-08 15:47:30',
        };
        final d = Diagnosis.fromJson(json);
        expect(d.id, 1);
        expect(d.imgname, 'test.jpg');
        expect(d.bhname, '苹果黑斑病');
        expect(d.bhreason, '链格孢菌');
        expect(d.bhadvice, '喷洒杀菌剂');
        expect(d.username, 'testuser');
        expect(d.location, '210711');
        expect(d.dtime, '2026-05-08 15:47:30');
      });

      test('location 为 null 时正常处理', () {
        final json = {
          'id': 2,
          'imgname': 'leaf.png',
          'bhname': '白粉病',
          'bhreason': '',
          'bhadvice': '',
          'username': 'user2',
          'location': null,
          'dtime': '2026-01-01 00:00:00',
        };
        final d = Diagnosis.fromJson(json);
        expect(d.location, isNull);
      });

      test('缺失字段时使用默认值', () {
        final json = <String, dynamic>{
          'id': 3,
          'imgname': null,
          'bhname': null,
          'bhreason': null,
          'bhadvice': null,
          'username': null,
          'dtime': null,
        };
        final d = Diagnosis.fromJson(json);
        expect(d.id, 3);
        expect(d.imgname, '');
        expect(d.bhname, '');
        expect(d.bhreason, '');
        expect(d.bhadvice, '');
        expect(d.username, '');
        expect(d.dtime, '');
      });

      test('location 为字符串 "null" 时保留原值', () {
        final json = {
          'id': 4,
          'imgname': 'a.jpg',
          'bhname': '病',
          'bhreason': '',
          'bhadvice': '',
          'username': 'u',
          'location': 'null',
          'dtime': '2026-01-01',
        };
        final d = Diagnosis.fromJson(json);
        expect(d.location, 'null');
      });
    });

    group('formattedTime', () {
      test('解析标准日期时间格式', () {
        final d = Diagnosis(
          id: 1,
          imgname: 'a.jpg',
          bhname: '病',
          bhreason: '',
          bhadvice: '',
          username: 'u',
          dtime: '2026-05-08 15:47:30',
        );
        expect(d.formattedTime, '2026年05月08日 15:47:30');
      });

      test('解析 RFC 1123 格式', () {
        final d = Diagnosis(
          id: 1,
          imgname: 'a.jpg',
          bhname: '病',
          bhreason: '',
          bhadvice: '',
          username: 'u',
          dtime: 'Fri, 08 May 2026 15:47:30 GMT',
        );
        expect(d.formattedTime, contains('2026'));
        expect(d.formattedTime, contains('05月'));
        expect(d.formattedTime, contains('08日'));
      });

      test('无法解析的时间格式原样返回', () {
        final d = Diagnosis(
          id: 1,
          imgname: 'a.jpg',
          bhname: '病',
          bhreason: '',
          bhadvice: '',
          username: 'u',
          dtime: 'bad-time-format',
        );
        expect(d.formattedTime, 'bad-time-format');
      });

      test('空字符串原样返回', () {
        final d = Diagnosis(
          id: 1,
          imgname: 'a.jpg',
          bhname: '病',
          bhreason: '',
          bhadvice: '',
          username: 'u',
          dtime: '',
        );
        expect(d.formattedTime, '');
      });
    });
  });

  // ==================== PredictionResult ====================
  group('PredictionResult', () {
    group('fromResponse', () {
      test('正常解析 top5 结果', () {
        final response = {
          'top5class': ['苹果黑斑病', '白粉病', '锈病', '霜霉病', '炭疽病'],
          'predicttop5': [0.85, 0.07, 0.04, 0.02, 0.01],
          'heatmap': null,
        };
        final r = PredictionResult.fromResponse(response);
        expect(r.result, '苹果黑斑病');
        expect(r.top5Classes.length, 5);
        expect(r.predictTop5.length, 5);
        expect(r.heatmapData, isNull);
      });

      test('top5class 为空时抛出异常', () {
        final response = {
          'top5class': <dynamic>[],
          'predicttop5': [0.9],
        };
        expect(
          () => PredictionResult.fromResponse(response),
          throwsA(isA<FormatException>()),
        );
      });

      test('top5class 缺失时抛出异常', () {
        final response = {
          'predicttop5': [0.9],
        };
        expect(
          () => PredictionResult.fromResponse(response),
          throwsA(isA<FormatException>()),
        );
      });

      test('predicttop5 缺失时抛出异常', () {
        final response = {
          'top5class': ['病'],
        };
        expect(
          () => PredictionResult.fromResponse(response),
          throwsA(isA<FormatException>()),
        );
      });

      test('predicttop5 非 List 时抛出异常', () {
        final response = {
          'top5class': ['病'],
          'predicttop5': 'invalid',
        };
        expect(
          () => PredictionResult.fromResponse(response),
          throwsA(isA<FormatException>()),
        );
      });

      test('数组长度不一致时正常处理', () {
        final response = {
          'top5class': ['苹果黑斑病', '白粉病'],
          'predicttop5': [0.85, 0.07, 0.04, 0.02, 0.01],
        };
        final r = PredictionResult.fromResponse(response);
        expect(r.top5Classes.length, 2);
        expect(r.predictTop5.length, 5);
        expect(r.displayCount, 2);
      });

      test('predicttop5 包含字符串数字时正常解析', () {
        final response = {
          'top5class': ['病A'],
          'predicttop5': ['0.9', '0.1'],
        };
        final r = PredictionResult.fromResponse(response);
        expect(r.predictTop5.first, 0.9);
      });

      test('heatmap 字段正常传递', () {
        final response = {
          'top5class': ['病'],
          'predicttop5': [0.9],
          'heatmap': 'base64data',
        };
        final r = PredictionResult.fromResponse(response);
        expect(r.heatmapData, 'base64data');
      });
    });

    group('displayCount', () {
      test('两个数组等长时取较小值', () {
        final r = PredictionResult(
          result: '病',
          heatmapData: null,
          top5Classes: ['a', 'b', 'c'],
          predictTop5: [0.1, 0.2, 0.3],
        );
        expect(r.displayCount, 3);
      });

      test('top5Classes 较短时取 top5Classes 长度', () {
        final r = PredictionResult(
          result: '病',
          heatmapData: null,
          top5Classes: ['a'],
          predictTop5: [0.1, 0.2, 0.3],
        );
        expect(r.displayCount, 1);
      });

      test('predictTop5 较短时取 predictTop5 长度', () {
        final r = PredictionResult(
          result: '病',
          heatmapData: null,
          top5Classes: ['a', 'b', 'c', 'd', 'e'],
          predictTop5: [0.1],
        );
        expect(r.displayCount, 1);
      });

      test('最大显示数为 5', () {
        final r = PredictionResult(
          result: '病',
          heatmapData: null,
          top5Classes: ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
          predictTop5: [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7],
        );
        expect(r.displayCount, 5);
      });
    });

    group('tryDecodeHeatmap', () {
      test('heatmap 为 null 时返回 null', () {
        final r = PredictionResult(
          result: '病',
          heatmapData: null,
          top5Classes: const [],
          predictTop5: const [],
        );
        expect(r.tryDecodeHeatmap(), isNull);
      });

      test('heatmap 为空字符串时返回 null', () {
        final r = PredictionResult(
          result: '病',
          heatmapData: '',
          top5Classes: const [],
          predictTop5: const [],
        );
        expect(r.tryDecodeHeatmap(), isNull);
      });

      test('heatmap 非法 base64 时返回 null', () {
        final r = PredictionResult(
          result: '病',
          heatmapData: '!!!not-base64!!!',
          top5Classes: const [],
          predictTop5: const [],
        );
        expect(r.tryDecodeHeatmap(), isNull);
      });

      test('合法 base64 正常解码', () {
        final fakeImage = base64Encode([0xFF, 0xD8, 0xFF, 0xE0]);
        final r = PredictionResult(
          result: '病',
          heatmapData: fakeImage,
          top5Classes: const [],
          predictTop5: const [],
        );
        final bytes = r.tryDecodeHeatmap();
        expect(bytes, isNotNull);
        expect(bytes!.length, 4);
        expect(bytes[0], 0xFF);
      });
    });
  });

  // ==================== User ====================
  group('User', () {
    test('默认值正确', () {
      final user = User();
      expect(user.nickName, '');
      expect(user.role, '0');
      expect(user.userAvatarUrl, 'assets/img/avatar.jpg');
    });

    test('构造函数可设置值', () {
      final user = User(
        nickName: '张三',
        role: '1',
        userAvatarUrl: 'assets/img/custom.jpg',
      );
      expect(user.nickName, '张三');
      expect(user.role, '1');
      expect(user.userAvatarUrl, 'assets/img/custom.jpg');
    });
  });

  // ==================== SavedCredentials ====================
  group('SavedCredentials', () {
    test('canAutoLogin 正常情况', () {
      const c = SavedCredentials(
        rememberMe: true,
        username: 'user',
        password: 'pass',
        role: '0',
      );
      expect(c.canAutoLogin, isTrue);
    });

    test('canAutoLogin rememberMe 为 false', () {
      const c = SavedCredentials(
        rememberMe: false,
        username: 'user',
        password: 'pass',
        role: '0',
      );
      expect(c.canAutoLogin, isFalse);
    });

    test('canAutoLogin 用户名为空', () {
      const c = SavedCredentials(
        rememberMe: true,
        username: '',
        password: 'pass',
        role: '0',
      );
      expect(c.canAutoLogin, isFalse);
    });

    test('canAutoLogin 密码为空', () {
      const c = SavedCredentials(
        rememberMe: true,
        username: 'user',
        password: '',
        role: '0',
      );
      expect(c.canAutoLogin, isFalse);
    });
  });

  // ==================== Map Models ====================
  group('GeoRegion', () {
    test('构造函数正常', () {
      final region = GeoRegion(
        id: '210700',
        name: '锦州市',
        level: 'city',
        parentAdcode: '210000',
        center: LatLng(41.1, 121.1),
        polygons: [],
      );
      expect(region.id, '210700');
      expect(region.name, '锦州市');
      expect(region.level, 'city');
      expect(region.parentAdcode, '210000');
      expect(region.center.latitude, 41.1);
      expect(region.polygons, isEmpty);
    });

    test('parentAdcode 可为 null', () {
      final region = GeoRegion(
        id: '210000',
        name: '辽宁省',
        level: 'province',
        parentAdcode: null,
        center: LatLng(41.3, 123.0),
        polygons: [],
      );
      expect(region.parentAdcode, isNull);
    });
  });

  group('GeoPolygonData', () {
    test('构造含孔洞的多边形', () {
      final outer = [LatLng(0, 0), LatLng(1, 0), LatLng(1, 1)];
      final hole = [LatLng(0.2, 0.2), LatLng(0.8, 0.2), LatLng(0.5, 0.8)];
      final poly = GeoPolygonData(outer: outer, holes: [hole]);
      expect(poly.outer.length, 3);
      expect(poly.holes.length, 1);
      expect(poly.holes[0].length, 3);
    });

    test('无孔洞多边形', () {
      final poly = GeoPolygonData(
        outer: [LatLng(0, 0), LatLng(1, 0), LatLng(1, 1)],
        holes: const [],
      );
      expect(poly.holes, isEmpty);
    });
  });

  group('GeoDataBundle', () {
    test('构造含边界', () {
      final bundle = GeoDataBundle(
        regions: [],
        bounds: LatLngBounds(LatLng(0, 0), LatLng(1, 1)),
      );
      expect(bundle.regions, isEmpty);
      expect(bundle.bounds, isNotNull);
    });

    test('边界可为 null', () {
      const bundle = GeoDataBundle(regions: [], bounds: null);
      expect(bundle.bounds, isNull);
    });
  });
}
