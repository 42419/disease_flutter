import 'package:farm_flutter/providers/main_navigation_provider.dart';
import 'package:farm_flutter/providers/upload_provider.dart';
import 'package:farm_flutter/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ==================== UserProvider ====================
  group('UserProvider', () {
    late UserProvider provider;

    setUp(() {
      provider = UserProvider();
    });

    test('初始状态为空用户', () {
      expect(provider.nickName, '');
      expect(provider.role, '0');
      expect(provider.isAdmin, isFalse);
      expect(provider.userAvatarUrl, 'assets/img/avatar.jpg');
    });

    test('login 设置用户信息', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.login('张三', '1');

      expect(provider.nickName, '张三');
      expect(provider.role, '1');
      expect(provider.isAdmin, isTrue);
      expect(notified, isTrue);
    });

    test('login 农户角色', () {
      provider.login('李四', '0');
      expect(provider.isAdmin, isFalse);
    });

    test('clear 重置为默认值', () {
      provider.login('张三', '1');
      var notified = false;
      provider.addListener(() => notified = true);

      provider.clear();

      expect(provider.nickName, '');
      expect(provider.role, '0');
      expect(provider.userAvatarUrl, 'assets/img/avatar.jpg');
      expect(provider.isAdmin, isFalse);
      expect(notified, isTrue);
    });

    test('多次 login 不会累积', () {
      provider.login('张三', '1');
      provider.login('李四', '0');
      expect(provider.nickName, '李四');
      expect(provider.role, '0');
    });
  });

  // ==================== UploadProvider ====================
  group('UploadProvider', () {
    late UploadProvider provider;

    setUp(() {
      provider = UploadProvider();
    });

    test('初始状态', () {
      expect(provider.selectedImage, isNull);
      expect(provider.isUploading, isFalse);
      expect(provider.result, isNull);
      expect(provider.heatmapData, isNull);
      expect(provider.top5Classes, isNull);
      expect(provider.predictTop5, isNull);
      expect(provider.uploadImageName, '');
      expect(provider.amapAdcode, '');
    });

    test('setAdcode 更新并通知', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setAdcode('210711');

      expect(provider.amapAdcode, '210711');
      expect(notified, isTrue);
    });

    test('setUploading 更新并通知', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setUploading(true);
      expect(provider.isUploading, isTrue);
      expect(notified, isTrue);
    });

    test('setError 清除 uploading 并设置错误', () {
      provider.setUploading(true);
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setError('上传失败');

      expect(provider.isUploading, isFalse);
      expect(provider.result, '上传失败');
      expect(notified, isTrue);
    });

    test('setResult 设置结果并清除 uploading', () {
      provider.setUploading(true);
      provider.setResult(
        result: '苹果黑斑病',
        heatmapData: 'base64data',
        top5Classes: ['苹果黑斑病', '白粉病'],
        predictTop5: [0.85, 0.15],
      );

      expect(provider.isUploading, isFalse);
      expect(provider.result, '苹果黑斑病');
      expect(provider.heatmapData, 'base64data');
      expect(provider.top5Classes, ['苹果黑斑病', '白粉病']);
      expect(provider.predictTop5, [0.85, 0.15]);
    });

    test('reset 清除所有状态', () {
      provider.setAdcode('210711');
      provider.setUploading(true);
      provider.setResult(result: '病', top5Classes: ['a'], predictTop5: [0.9]);

      var notified = false;
      provider.addListener(() => notified = true);

      provider.reset();

      expect(provider.selectedImage, isNull);
      expect(provider.isUploading, isFalse);
      expect(provider.result, isNull);
      expect(provider.heatmapData, isNull);
      expect(provider.top5Classes, isNull);
      expect(provider.predictTop5, isNull);
      expect(provider.uploadImageName, '');
      expect(provider.amapAdcode, '');
      expect(notified, isTrue);
    });
  });

  // ==================== MainNavigationProvider ====================
  group('MainNavigationProvider', () {
    late MainNavigationProvider provider;

    setUp(() {
      provider = MainNavigationProvider();
    });

    test('初始索引为 0', () {
      expect(provider.currentIndex, 0);
    });

    test('setCurrentIndex 更新索引并通知', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setCurrentIndex(1);

      expect(provider.currentIndex, 1);
      expect(notified, isTrue);
    });

    test('多次切换索引', () {
      provider.setCurrentIndex(1);
      expect(provider.currentIndex, 1);
      provider.setCurrentIndex(0);
      expect(provider.currentIndex, 0);
      provider.setCurrentIndex(3);
      expect(provider.currentIndex, 3);
    });
  });
}
