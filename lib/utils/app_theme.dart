import 'package:flutter/material.dart';

/// 应用级 [ThemeData]，提供给 [MaterialApp] 的 `theme` / `darkTheme`。
///
/// 页面里绝大部分颜色仍然是通过 [AppColors] 的动态 getter 直接取值的
/// （详见 lib/utils/app_colors.dart 的说明），这里的 ThemeData 主要负责：
///   1. 让原生 Material 组件（TextField、Dialog、SnackBar、Switch、
///      NavigationBar 默认态等）在两种模式下也有正确、协调的默认外观；
///   2. 提供 `MaterialApp.themeMode` 切换所需的、独立于 AppColors 全局
///      状态之外的一份"静态"深浅色配置（ThemeData 本身必须是不可变的、
///      light/dark 两份固定实例，不能像 AppColors 那样做成运行时 getter）。
///
/// 数值上与 lib/utils/app_colors.dart 中 `_Light` / `_Dark` 两个私有调色板
/// 保持同步，来源都是项目 DESIGN.md 的 Claude 品牌配色体系。
class AppTheme {
  AppTheme._();

  // 浅色 —— 与 _Light 调色板一致
  static const _lPrimary = Color(0xFFCC785C);
  static const _lPrimaryActive = Color(0xFFA9583E);
  static const _lInk = Color(0xFF141413);
  static const _lBody = Color(0xFF3D3D3A);
  static const _lMuted = Color(0xFF6C6A64);
  static const _lCanvas = Color(0xFFFAF9F5);
  static const _lSurfaceSoft = Color(0xFFF5F0E8);
  static const _lSurfaceCard = Color(0xFFEFE9DE);
  static const _lHairline = Color(0xFFE6DFD8);
  static const _lError = Color(0xFFC64545);

  // 深色 —— 与 _Dark 调色板一致
  static const _dPrimary = Color(0xFFDB9673);
  static const _dPrimaryActive = Color(0xFFC97C58);
  static const _dInk = Color(0xFFFAF9F5);
  static const _dBody = Color(0xFFC9C6BE);
  static const _dMuted = Color(0xFFA09D96);
  static const _dCanvas = Color(0xFF181715);
  static const _dSurfaceSoft = Color(0xFF1F1E1B);
  static const _dSurfaceCard = Color(0xFF252320);
  static const _dHairline = Color(0xFF3A362F);
  static const _dError = Color(0xFFE2685F);

  static ThemeData get light => _build(
    brightness: Brightness.light,
    primary: _lPrimary,
    primaryActive: _lPrimaryActive,
    ink: _lInk,
    body: _lBody,
    muted: _lMuted,
    canvas: _lCanvas,
    surfaceSoft: _lSurfaceSoft,
    surfaceCard: _lSurfaceCard,
    hairline: _lHairline,
    error: _lError,
    onPrimary: Colors.white,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    primary: _dPrimary,
    primaryActive: _dPrimaryActive,
    ink: _dInk,
    body: _dBody,
    muted: _dMuted,
    canvas: _dCanvas,
    surfaceSoft: _dSurfaceSoft,
    surfaceCard: _dSurfaceCard,
    hairline: _dHairline,
    error: _dError,
    // 深色模式下按钮上的珊瑚色更亮，用墨色文字对比度优于纯白。
    onPrimary: _dCanvas,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color primaryActive,
    required Color ink,
    required Color body,
    required Color muted,
    required Color canvas,
    required Color surfaceSoft,
    required Color surfaceCard,
    required Color hairline,
    required Color error,
    required Color onPrimary,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: primary,
      onSecondary: onPrimary,
      error: error,
      onError: Colors.white,
      surface: canvas,
      onSurface: ink,
      surfaceContainerHighest: surfaceCard,
      outline: hairline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      canvasColor: canvas,
      dividerColor: hairline,
      splashColor: primary.withValues(alpha: 0.08),
      highlightColor: primary.withValues(alpha: 0.04),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: ink),
      ),
      iconTheme: IconThemeData(color: muted),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
      dividerTheme: DividerThemeData(color: hairline, thickness: 1),
      cardTheme: CardThemeData(
        color: surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSoft,
        hintStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: canvas,
          elevation: 0,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.4)
              : hairline,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceCard,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: canvas),
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      // 深色模式下 primaryActive 也一并暴露给需要"按下态"的自定义组件参考。
      extensions: [_PressedColor(primaryActive)],
    );
  }
}

/// 少数自定义组件想拿到"主色按下态"时可以用 `Theme.of(context).extension<_PressedColor>()`。
/// 目前大多数地方仍直接读 AppColors.primaryActive，这里主要是为未来扩展留口子。
class _PressedColor extends ThemeExtension<_PressedColor> {
  const _PressedColor(this.color);
  final Color color;

  @override
  ThemeExtension<_PressedColor> copyWith({Color? color}) =>
      _PressedColor(color ?? this.color);

  @override
  ThemeExtension<_PressedColor> lerp(
    covariant ThemeExtension<_PressedColor>? other,
    double t,
  ) {
    if (other is! _PressedColor) return this;
    return _PressedColor(Color.lerp(color, other.color, t) ?? color);
  }
}
