import 'dart:convert';

import 'package:farm_flutter/models/diagnosis.dart';
import 'package:farm_flutter/models/prediction_result.dart';
import 'package:farm_flutter/services/auth_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Diagnosis.fromJson', () {
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
      expect(d.username, '');
    });

    test('formattedTime 解析 ISO 8601 格式', () {
      final d = Diagnosis(
        id: 1,
        imgname: 'a.jpg',
        bhname: '病',
        bhreason: '',
        bhadvice: '',
        username: 'u',
        dtime: '2026-05-08 15:47:30',
      );
      expect(d.formattedTime, contains('2026'));
      expect(d.formattedTime, contains('05月'));
      expect(d.formattedTime, contains('08日'));
    });

    test('formattedTime 解析 RFC 1123 格式', () {
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
  });

  group('PredictionResult.fromResponse', () {
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
      expect(r.displayCount, 5);
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

    test('displayCount 最大为 5', () {
      final response = {
        'top5class': ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
        'predicttop5': [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
      };
      final r = PredictionResult.fromResponse(response);
      expect(r.displayCount, 5);
    });

    test('predicttop5 包含字符串数字时正常解析', () {
      final response = {
        'top5class': ['病A'],
        'predicttop5': ['0.9', '0.1'],
      };
      final r = PredictionResult.fromResponse(response);
      expect(r.predictTop5.first, 0.9);
    });

    test('tryDecodeHeatmap 返回 null 当 heatmap 为空', () {
      final r = PredictionResult(
        result: '病',
        heatmapData: null,
        top5Classes: const [],
        predictTop5: const [],
      );
      expect(r.tryDecodeHeatmap(), isNull);
    });

    test('tryDecodeHeatmap 返回 null 当 heatmap 非法 base64', () {
      final r = PredictionResult(
        result: '病',
        heatmapData: '!!!not-base64!!!',
        top5Classes: const [],
        predictTop5: const [],
      );
      expect(r.tryDecodeHeatmap(), isNull);
    });

    test('tryDecodeHeatmap 正常解码合法 base64', () {
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
    });
  });

  group('SavedCredentials', () {
    test('canAutoLogin 在用户名密码非空且 rememberMe 为 true 时返回 true', () {
      const c = SavedCredentials(
        rememberMe: true,
        username: 'user',
        password: 'pass',
        role: '0',
      );
      expect(c.canAutoLogin, isTrue);
    });

    test('canAutoLogin 在 rememberMe 为 false 时返回 false', () {
      const c = SavedCredentials(
        rememberMe: false,
        username: 'user',
        password: 'pass',
        role: '0',
      );
      expect(c.canAutoLogin, isFalse);
    });

    test('canAutoLogin 在用户名为空时返回 false', () {
      const c = SavedCredentials(
        rememberMe: true,
        username: '',
        password: 'pass',
        role: '0',
      );
      expect(c.canAutoLogin, isFalse);
    });

    test('canAutoLogin 在密码为空时返回 false', () {
      const c = SavedCredentials(
        rememberMe: true,
        username: 'user',
        password: '',
        role: '0',
      );
      expect(c.canAutoLogin, isFalse);
    });
  });
}
