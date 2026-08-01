import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/app_spacing.dart';
import 'package:flutter/material.dart';

/// 应用全局字体族的唯一声明入口。
///
/// 项目里原先有 60+ 处散落的 `TextStyle(fontFamily: "serif", ...)`，
/// 想统一换字体需要逐处修改；现在收拢成这一个常量，所有调用点改用
/// `fontFamily: kAppFontFamily`，以后只需要改这一处。
///
/// 注意：`pubspec.yaml` 目前没有随包携带任何自定义字体文件，"serif" 是
/// 平台自带的通用字族名——Android 会映射到系统的 Noto Serif 一类字体，
/// iOS 没有对应的系统字族名，会回退到系统默认无衬线字体，这也是
/// ANALYSIS.md 里提到的"iOS 和 Android 观感不一致"的真实原因。要彻底解决
/// 需要项目提供一份实际的衬线字体文件（如思源宋体/Noto Serif SC 的 .ttf），
/// 放进 `assets/fonts/` 并在 `pubspec.yaml` 的 `fonts:` 下声明，再把下面
/// 这个常量指向声明的字族名即可，不需要再改任何调用点。
const String kAppFontFamily = "serif";

/// 应用级 [ThemeData]，提供给 [MaterialApp] 的 `theme` / `darkTheme`。
///
/// 所有颜色都直接复用 [AppColorsX.light] / [AppColorsX.dark]（唯一的配色
/// 数据来源），既用来配置原生 Material 组件（TextField、Dialog、SnackBar、
/// Switch、NavigationBar 默认态等）的默认外观，也通过 `extensions` 把同一份
/// [AppColorsX] 暴露给业务 Widget（`context.colors.xxx`），不存在两份需要
/// 手动保持同步的颜色常量。
class AppTheme {
  AppTheme._();

  static ThemeData get light =>
      _build(brightness: Brightness.light, colors: AppColorsX.light);

  static ThemeData get dark =>
      _build(brightness: Brightness.dark, colors: AppColorsX.dark);

  static ThemeData _build({
    required Brightness brightness,
    required AppColorsX colors,
  }) {
    // 深色模式下按钮上的珊瑚色更亮，用墨色文字对比度优于纯白。
    final onPrimary = brightness == Brightness.dark
        ? colors.canvas
        : colors.white;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: onPrimary,
      secondary: colors.primary,
      onSecondary: onPrimary,
      error: colors.error,
      onError: colors.white,
      surface: colors.canvas,
      onSurface: colors.ink,
      surfaceContainerHighest: colors.surfaceCard,
      outline: colors.hairline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: kAppFontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      dividerColor: colors.hairline,
      splashColor: colors.primary.withValues(alpha: 0.08),
      highlightColor: colors.primary.withValues(alpha: 0.04),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.canvas,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.ink),
      ),
      iconTheme: IconThemeData(color: colors.muted),
      textTheme: ThemeData(
        brightness: brightness,
      ).textTheme.apply(bodyColor: colors.ink, displayColor: colors.ink),
      dividerTheme: DividerThemeData(color: colors.hairline, thickness: 1),
      cardTheme: CardThemeData(
        color: colors.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceSoft,
        hintStyle: TextStyle(color: colors.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.ink,
          foregroundColor: colors.canvas,
          elevation: 0,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary.withValues(alpha: 0.4)
              : colors.hairline,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceCard,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.ink,
        contentTextStyle: TextStyle(color: colors.canvas),
        behavior: SnackBarBehavior.floating,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.canvas,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primary.withValues(alpha: 0.14),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.muted,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
      // 通过 extensions 把完整配色暴露给业务 Widget：`context.colors.xxx`。
      extensions: [colors],
    );
  }
}
