import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../utils/app_colors.dart';

/// 管理整个 App 的主题模式，始终跟随系统深浅色设置，不支持手动切换。
///
/// - 每当系统亮度发生变化时，会先把新的亮度同步给 [AppColors]（所有页面
///   用到的取色 getter 都读它），再调用 [notifyListeners]，保证依赖本
///   Provider 重建的 Widget 拿到的已经是最新配色，不会闪一帧旧颜色。
class ThemeModeController extends ChangeNotifier with WidgetsBindingObserver {
  ThemeModeController() {
    // 启动时先同步一次系统亮度到 AppColors，避免首帧颜色不对。
    _syncBrightness();
    WidgetsBinding.instance.addObserver(this);
  }

  bool get isDark => resolvedBrightness == Brightness.dark;

  /// 实际应显示的亮度，始终等于系统当前亮度。
  Brightness get resolvedBrightness =>
      SchedulerBinding.instance.platformDispatcher.platformBrightness;

  @override
  void didChangePlatformBrightness() {
    _syncBrightness();
    notifyListeners();
  }

  void _syncBrightness() {
    AppColors.setBrightness(resolvedBrightness);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
