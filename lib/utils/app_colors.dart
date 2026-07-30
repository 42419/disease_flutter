import 'package:flutter/material.dart';

/// 农业种植病虫害防治 APP - 配色方案 (Claude Design System)
///
/// 基于项目 DESIGN.md 中的 Claude 品牌配色体系扩展出完整的深色模式。
/// DESIGN.md 本身只定义了少量"深色卡片"级别的 token（surface-dark 系列），
/// 这里在同一套暖色调性（暖灰黑，而非冷蓝黑）基础上，补全了一整套用于
/// 深色模式下的文字、边框、品牌色、状态色，遵循的原则：
///   1. 深色背景不用纯黑（#000000），沿用 DESIGN.md 的暖炭黑 #181715；
///   2. 品牌珊瑚色 primary 在深色背景上适度提亮，保持辨识度又不刺眼；
///   3. 语义色（success/warning/error）在深色背景上同样提亮，保证对比度；
///   4. 文字对比度遵循 WCAG AA（正文文字与背景对比度 ≥ 4.5:1）。
///
/// 用法保持不变：`AppColors.ink`、`AppColors.canvas` 等，所有字段现在是
/// 会根据当前亮度动态返回取值的 getter，而不是编译期常量——因此不能再用
/// 在 `const` 表达式里（例如 `const TextStyle(color: AppColors.ink)` 需要
/// 去掉外层的 const）。
class AppColors {
  AppColors._();

  // ==========================================
  // 全局亮度状态
  // ==========================================

  static Brightness _brightness = Brightness.light;

  /// 由 [ThemeModeController] 在主题变化时调用，同步当前应处于的亮度。
  /// 必须在触发相关 Widget 重建（notifyListeners）之前调用，
  /// 这样重建时读取到的所有 AppColors.xxx 才是最新值。
  static void setBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get isDark => _brightness == Brightness.dark;

  // ==========================================
  // Brand & Accent
  // ==========================================
  static Color get primary => isDark ? _Dark.primary : _Light.primary;
  static Color get primaryActive =>
      isDark ? _Dark.primaryActive : _Light.primaryActive;
  static Color get primaryDisabled =>
      isDark ? _Dark.primaryDisabled : _Light.primaryDisabled;

  static Color get accentTeal => isDark ? _Dark.accentTeal : _Light.accentTeal;
  static Color get accentAmber =>
      isDark ? _Dark.accentAmber : _Light.accentAmber;

  // ==========================================
  // Core Text & Foreground
  // ==========================================
  static Color get ink => isDark ? _Dark.ink : _Light.ink;
  static Color get body => isDark ? _Dark.body : _Light.body;
  static Color get bodyStrong => isDark ? _Dark.bodyStrong : _Light.bodyStrong;
  static Color get muted => isDark ? _Dark.muted : _Light.muted;
  static Color get mutedSoft => isDark ? _Dark.mutedSoft : _Light.mutedSoft;

  // ==========================================
  // Backgrounds & Surfaces
  // 浅色模式下这组就是暖白/奶油背景；深色模式下 canvas 自动切换为
  // DESIGN.md 的 surface-dark 暖炭黑，surfaceCard/surfaceSoft 依次对应
  // 更亮一级的深色卡片面，形成和浅色模式一致的层级关系。
  // ==========================================
  static Color get canvas => isDark ? _Dark.canvas : _Light.canvas;
  static Color get surfaceSoft =>
      isDark ? _Dark.surfaceSoft : _Light.surfaceSoft;
  static Color get surfaceCard =>
      isDark ? _Dark.surfaceCard : _Light.surfaceCard;
  static Color get surfaceCreamStrong =>
      isDark ? _Dark.surfaceStrong : _Light.surfaceCreamStrong;

  // ==========================================
  // Backgrounds & Surfaces（原始"深色卡片" token，语义不随主题切换，
  // 始终是深色——例如浅色模式下用于个别强调卡片、深色模式下用于所有背景）
  // ==========================================
  static const Color surfaceDark = Color(0xFF181715);
  static const Color surfaceDarkElevated = Color(0xFF252320);
  static const Color surfaceDarkSoft = Color(0xFF1F1E1B);

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onDark = Color(0xFFFAF9F5);
  static const Color onDarkSoft = Color(0xFFA09D96);

  // ==========================================
  // Borders & Dividers
  // ==========================================
  static Color get hairline => isDark ? _Dark.hairline : _Light.hairline;
  static Color get hairlineSoft =>
      isDark ? _Dark.hairlineSoft : _Light.hairlineSoft;

  // ==========================================
  // Feedback & Status
  // ==========================================
  static Color get success => isDark ? _Dark.success : _Light.success;
  static Color get warning => isDark ? _Dark.warning : _Light.warning;
  static Color get error => isDark ? _Dark.error : _Light.error;

  // ==========================================
  // Legacy aliases for compatibility
  // ==========================================
  static Color get primaryLight => primaryDisabled;
  static Color get primaryLightest => surfaceSoft;
  static Color get primaryDark => primaryActive;
  static Color get earthBrown => muted;
  static Color get soilLight => surfaceCard;
  static Color get harvestGold => accentAmber;
  static Color get danger => error;
  static Color get alert => warning;
  static Color get info => accentTeal;

  static Color get textPrimary => ink;
  static Color get textSecondary => body;
  static Color get textTertiary => muted;
  static Color get textDisabled => mutedSoft;

  /// 恒定纯白，用于品牌色/深色底之上的强制白字白图标等场景，不随主题切换。
  static const Color white = Color(0xFFFFFFFF);
  static Color get backgroundLight => canvas;
  static Color get backgroundDark => surfaceSoft;
  static Color get divider => hairline;
  static Color get shadow =>
      isDark ? const Color(0x66000000) : const Color(0x1A000000);
  static Color get cardBackground => surfaceSoft;
  static Color get cardBorder => hairline;
  static Color get inputBackground => surfaceSoft;
  static Color get inputBorder => hairline;
  static Color get inputBorderFocused => primary;
  static Color get buttonText => onPrimary;
  static Color get iconDefault => muted;

  /// 输入框背景 - 极浅灰（深色模式下切换为深色输入框底）
  static Color get inputBackgroundLegacy =>
      isDark ? _Dark.surfaceSoft : const Color(0xFFF8F8F8);

  /// 输入框边框 - 浅灰
  static Color get inputBorderLegacy => hairline;

  /// 输入框聚焦边框 - 主色
  static Color get inputBorderFocusedLegacy => primary;

  /// 按钮文字 - 白色
  static const Color buttonTextLegacy = Color(0xFFFFFFFF);

  /// 次要按钮文字 - 主色
  static Color get buttonTextSecondary => ink;

  /// 图标激活 - 主色（或可改为 success 森林绿）
  static Color get iconActive => ink;

  /// 导航栏背景
  static Color get appBarBackground => canvas;

  /// 底部导航栏背景
  static Color get bottomNavBackground => canvas;

  /// 底部导航栏选中
  static Color get bottomNavSelected => ink;

  /// 底部导航栏未选中 - 灰色
  static Color get bottomNavUnselected => muted;

  // ==========================================
  // 病虫害等级颜色
  // ==========================================

  /// 轻度 - 森林绿
  static Color get pestLevelLow => success;

  /// 中度 - 赭石黄
  static Color get pestLevelMedium => accentAmber;

  /// 重度 - 古铜色
  static Color get pestLevelHigh => warning;

  /// 严重 - 铁锈红
  static Color get pestLevelSevere => error;

  // ==========================================
  // 植物状态颜色
  // ==========================================

  /// 健康 - 森林绿
  static Color get plantHealthy => success;

  /// 亚健康 - 橄榄绿
  static Color get plantSubHealthy => accentAmber;

  /// 生病 - 赭石红
  static Color get plantSick => error;

  /// 枯萎 - 棕灰
  static Color get plantWithered => muted;

  // ==========================================
  // 渐变色
  // ==========================================

  /// 主色渐变 - 从卡片面到墨色
  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceCard, ink],
  );

  /// 警告渐变 - 从赭石黄到古铜色
  static LinearGradient get warningGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentAmber, warning],
  );

  /// 危险渐变 - 从古铜色到铁锈红
  static LinearGradient get dangerGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, error],
  );

  // ==========================================
  // 季节主题色（黑白系）
  // ==========================================

  /// 春季 - 炭灰
  static Color get seasonSpring => muted;

  /// 夏季 - 深岩灰
  static Color get seasonSummer => ink;

  /// 秋季 - 中灰
  static Color get seasonAutumn => mutedSoft;

  /// 冬季 - 浅灰
  static Color get seasonWinter => hairline;

  // ==========================================
  // 特殊用途颜色
  // ==========================================

  /// 上传区域背景
  static Color get uploadAreaBackground => surfaceSoft;

  /// 上传区域边框
  static Color get uploadAreaBorder => hairline;

  /// 图片占位背景
  static Color get imagePlaceholder => surfaceCard;

  /// 加载中颜色 - 主色
  static Color get loading => primary;

  /// 水印颜色 - 半透明黑（深色模式下改为半透明白，避免在深色图片上不可见）
  static Color get watermark =>
      isDark ? const Color(0x40FFFFFF) : const Color(0x40000000);
}

/// 浅色模式调色板 —— 与 DESIGN.md `colors:` 部分一一对应，数值未改动。
class _Light {
  _Light._();

  static const Color primary = Color(0xFFCC785C);
  static const Color primaryActive = Color(0xFFA9583E);
  static const Color primaryDisabled = Color(0xFFE6DFD8);

  static const Color accentTeal = Color(0xFF5DB8A6);
  static const Color accentAmber = Color(0xFFE8A55A);

  static const Color ink = Color(0xFF141413);
  static const Color body = Color(0xFF3D3D3A);
  static const Color bodyStrong = Color(0xFF252523);
  static const Color muted = Color(0xFF6C6A64);
  static const Color mutedSoft = Color(0xFF8E8B82);

  static const Color canvas = Color(0xFFFAF9F5);
  static const Color surfaceSoft = Color(0xFFF5F0E8);
  static const Color surfaceCard = Color(0xFFEFE9DE);
  static const Color surfaceCreamStrong = Color(0xFFE8E0D2);

  static const Color hairline = Color(0xFFE6DFD8);
  static const Color hairlineSoft = Color(0xFFEBE6DF);

  static const Color success = Color(0xFF5DB872);
  static const Color warning = Color(0xFFD4A017);
  static const Color error = Color(0xFFC64545);
}

/// 深色模式调色板。
///
/// canvas/surfaceSoft/surfaceCard 直接复用 DESIGN.md 里已经定义好的
/// surface-dark（#181715）→ surface-dark-soft（#1F1E1B）→
/// surface-dark-elevated（#252320）三级层次；surfaceStrong 是在同一色相
/// 上外推出的第四级（弹窗/下拉菜单等最上层的面）。文字沿用 on-dark /
/// on-dark-soft，并在此基础上补出 bodyStrong / muted / mutedSoft 的层级。
/// 品牌色与语义色统一提亮，避免"又暗又灰"的低对比度观感。
class _Dark {
  _Dark._();

  static const Color primary = Color(0xFFDB9673); // 提亮版珊瑚色，保持品牌辨识度
  static const Color primaryActive = Color(0xFFC97C58);
  static const Color primaryDisabled = Color(0xFF3D3630);

  static const Color accentTeal = Color(0xFF6FC7B5);
  static const Color accentAmber = Color(0xFFF0B573);

  static const Color ink = onDark; // 主文字：暖白
  static const Color body = Color(0xFFC9C6BE); // 正文：介于 onDark 与 onDarkSoft 之间
  static const Color bodyStrong = Color(0xFFE4E1D9);
  static const Color muted = onDarkSoft; // 次要文字
  static const Color mutedSoft = Color(0xFF716D64); // 三级/禁用态文字

  static const Color canvas = Color(0xFF181715); // = DESIGN.md surface-dark
  static const Color surfaceSoft = Color(0xFF1F1E1B); // = surface-dark-soft
  static const Color surfaceCard = Color(0xFF252320); // = surface-dark-elevated
  static const Color surfaceStrong = Color(0xFF2F2C27); // 外推：弹层/最高层级

  static const Color hairline = Color(0xFF3A362F);
  static const Color hairlineSoft = Color(0xFF2C2924);

  static const Color success = Color(0xFF6FCB86);
  static const Color warning = Color(0xFFE8B93D);
  static const Color error = Color(0xFFE2685F);

  static const Color onDark = Color(0xFFFAF9F5);
  static const Color onDarkSoft = Color(0xFFA09D96);
}
