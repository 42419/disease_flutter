import 'package:flutter/material.dart';

/// 农业种植病虫害防治 APP - 配色方案 (Claude Design System)
///
/// 通过 [ThemeExtension] 把配色挂在 [ThemeData] 上，替代此前"全局可变
/// 静态 getter（`AppColors.ink` 等） + 每个 Widget 手动
/// `context.watch<ThemeModeController>()` 才能在深色模式切换时重建"的方案：
///   - 颜色值现在是 `ThemeData.extensions` 的一部分，属于 InheritedWidget；
///   - Widget 只要在 build() 里通过 `context.colors.xxx` 读取（内部调用
///     `Theme.of(context)`），Flutter 会自动建立依赖——主题变化时该 Widget
///     自动重建，不存在"忘记 watch 导致颜色没刷新"的隐患；
///   - light/dark 两套取值集中定义在本文件，[AppTheme] 直接复用，
///     不再有第二份重复的颜色常量需要手动保持同步。
///
/// 用法：`context.colors.primary`、`context.colors.canvas` 等。
///
/// 配色原则（与 DESIGN.md 的 Claude 品牌配色体系一致）：
///   1. 深色背景不用纯黑（#000000），也不追求过深，采用暖炭灰 #201F1C，
///      降低背景与文字之间过强的黑白冲击对比，兼顾长时间阅读的舒适度；
///   2. 品牌珊瑚色 primary 在深色背景上适度提亮，保持辨识度又不刺眼；
///   3. 语义色（success/warning/error）在深色背景上同样提亮，保证对比度；
///   4. 文字对比度遵循 WCAG AA（正文文字与背景对比度 ≥ 4.5:1）。
@immutable
class AppColorsX extends ThemeExtension<AppColorsX> {
  const AppColorsX({
    required this.primary,
    required this.primaryActive,
    required this.accentTeal,
    required this.accentAmber,
    required this.ink,
    required this.body,
    required this.muted,
    required this.mutedSoft,
    required this.canvas,
    required this.surfaceSoft,
    required this.surfaceCard,
    required this.hairline,
    required this.success,
    required this.warning,
    required this.error,
    required this.white,
  });

  /// 浅色模式调色板 —— 与 DESIGN.md `colors:` 部分一一对应，数值未改动。
  static const light = AppColorsX(
    primary: Color(0xFFCC785C),
    primaryActive: Color(0xFFA9583E),
    accentTeal: Color(0xFF5DB8A6),
    accentAmber: Color(0xFFE8A55A),
    ink: Color(0xFF141413),
    body: Color(0xFF3D3D3A),
    muted: Color(0xFF6C6A64),
    mutedSoft: Color(0xFF8E8B82),
    canvas: Color(0xFFFAF9F5),
    surfaceSoft: Color(0xFFF5F0E8),
    surfaceCard: Color(0xFFEFE9DE),
    hairline: Color(0xFFE6DFD8),
    success: Color(0xFF5DB872),
    warning: Color(0xFFD4A017),
    error: Color(0xFFC64545),
    white: Color(0xFFFFFFFF),
  );

  /// 深色模式调色板。
  ///
  /// canvas/surfaceSoft/surfaceCard 采用暖炭灰而非纯黑；主文字 ink 用暖白
  /// #E6E3DB 而非纯白，与 canvas 的对比度约 12.8:1（仍远超 WCAG AA 的
  /// 4.5:1），比早期"纯黑配纯白"（约 17:1）更适合长时间阅读。
  /// 品牌色与语义色统一提亮，避免"又暗又灰"的低对比度观感。
  static const dark = AppColorsX(
    primary: Color(0xFFDB9673), // 提亮版珊瑚色，保持品牌辨识度
    primaryActive: Color(0xFFC97C58),
    accentTeal: Color(0xFF6FC7B5),
    accentAmber: Color(0xFFF0B573),
    ink: Color(0xFFE6E3DB), // 暖白（约 90% 亮度），而非纯白
    body: Color(0xFFC9C6BE),
    muted: Color(0xFFA09D96),
    mutedSoft: Color(0xFF716D64),
    canvas: Color(0xFF201F1C),
    surfaceSoft: Color(0xFF262521),
    surfaceCard: Color(0xFF2C2A25),
    hairline: Color(0xFF3A362F),
    success: Color(0xFF6FCB86),
    warning: Color(0xFFE8B93D),
    error: Color(0xFFE2685F),
    white: Color(0xFFFFFFFF),
  );

  final Color primary;
  final Color primaryActive;
  final Color accentTeal;
  final Color accentAmber;
  final Color ink;
  final Color body;
  final Color muted;
  final Color mutedSoft;
  final Color canvas;
  final Color surfaceSoft;
  final Color surfaceCard;
  final Color hairline;
  final Color success;
  final Color warning;
  final Color error;
  final Color white;

  @override
  AppColorsX copyWith({
    Color? primary,
    Color? primaryActive,
    Color? accentTeal,
    Color? accentAmber,
    Color? ink,
    Color? body,
    Color? muted,
    Color? mutedSoft,
    Color? canvas,
    Color? surfaceSoft,
    Color? surfaceCard,
    Color? hairline,
    Color? success,
    Color? warning,
    Color? error,
    Color? white,
  }) {
    return AppColorsX(
      primary: primary ?? this.primary,
      primaryActive: primaryActive ?? this.primaryActive,
      accentTeal: accentTeal ?? this.accentTeal,
      accentAmber: accentAmber ?? this.accentAmber,
      ink: ink ?? this.ink,
      body: body ?? this.body,
      muted: muted ?? this.muted,
      mutedSoft: mutedSoft ?? this.mutedSoft,
      canvas: canvas ?? this.canvas,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      hairline: hairline ?? this.hairline,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      white: white ?? this.white,
    );
  }

  @override
  AppColorsX lerp(covariant ThemeExtension<AppColorsX>? other, double t) {
    if (other is! AppColorsX) return this;
    return AppColorsX(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryActive: Color.lerp(primaryActive, other.primaryActive, t)!,
      accentTeal: Color.lerp(accentTeal, other.accentTeal, t)!,
      accentAmber: Color.lerp(accentAmber, other.accentAmber, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      body: Color.lerp(body, other.body, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedSoft: Color.lerp(mutedSoft, other.mutedSoft, t)!,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      white: Color.lerp(white, other.white, t)!,
    );
  }
}

/// 在 build() 里通过 `context.colors` 读取当前主题下的配色；
/// `context.isDarkMode` 等价于 `Theme.of(context).brightness == Brightness.dark`。
extension AppColorsContext on BuildContext {
  AppColorsX get colors => Theme.of(this).extension<AppColorsX>()!;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
