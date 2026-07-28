import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_colors.dart';

/// 管理整个 App 的主题模式（跟随系统 / 始终浅色 / 始终深色）。
///
/// - 用户的选择会持久化到本地（[SharedPreferences]），下次启动自动恢复。
/// - 每当"实际应显示的亮度"（[resolvedBrightness]）发生变化时，会先把新的
///   亮度同步给 [AppColors]（所有页面用到的取色 getter 都读它），再调用
///   [notifyListeners]，保证依赖本 Provider 重建的 Widget 拿到的已经是
///   最新配色，不会闪一帧旧颜色。
/// - 当用户选择"跟随系统"时，会监听系统深色模式切换（如晚上系统自动
///   开启深色模式）并实时联动。
class ThemeModeController extends ChangeNotifier with WidgetsBindingObserver {
  static const _prefsKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeModeController() {
    // 启动时先用系统亮度同步一次 AppColors，避免首帧颜色不对。
    _syncBrightness();
    WidgetsBinding.instance.addObserver(this);
    _restoreSavedPreference();
  }

  /// 当前的主题模式选择（跟随系统 / 浅色 / 深色）。
  ThemeMode get themeMode => _themeMode;

  bool get isDark => resolvedBrightness == Brightness.dark;

  Brightness get _platformBrightness =>
      SchedulerBinding.instance.platformDispatcher.platformBrightness;

  /// 结合用户选择与系统设置后，实际应该显示的亮度。
  Brightness get resolvedBrightness {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return _platformBrightness;
    }
  }

  Future<void> _restoreSavedPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      switch (saved) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    } catch (_) {
      // 读取失败时保持默认的"跟随系统"，不影响正常使用。
    }
    _syncBrightness();
    notifyListeners();
  }

  /// 切换主题模式，并持久化保存。
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _syncBrightness();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.name);
    } catch (_) {
      // 持久化失败不影响当前会话内的显示效果，下次启动会回退到默认值。
    }
  }

  @override
  void didChangePlatformBrightness() {
    if (_themeMode == ThemeMode.system) {
      _syncBrightness();
      notifyListeners();
    }
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
