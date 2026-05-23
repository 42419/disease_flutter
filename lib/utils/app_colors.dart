import 'package:flutter/material.dart';

/// 农业种植病虫害防治APP - 配色方案 (Claude Design System)
class AppColors {
  // ==========================================
  // Brand & Accent
  // ==========================================
  static const Color primary = Color(0xFFCC785C);
  static const Color primaryActive = Color(0xFFA9583E);
  static const Color primaryDisabled = Color(0xFFE6DFD8);
  
  static const Color accentTeal = Color(0xFF5DB8A6);
  static const Color accentAmber = Color(0xFFE8A55A);

  // ==========================================
  // Core Text & Foreground
  // ==========================================
  static const Color ink = Color(0xFF141413);
  static const Color body = Color(0xFF3D3D3A);
  static const Color bodyStrong = Color(0xFF252523);
  static const Color muted = Color(0xFF6C6A64);
  static const Color mutedSoft = Color(0xFF8E8B82);

  // ==========================================
  // Backgrounds & Surfaces (Light Mode)
  // ==========================================
  static const Color canvas = Color(0xFFFAF9F5);
  static const Color surfaceSoft = Color(0xFFF5F0E8);
  static const Color surfaceCard = Color(0xFFEFE9DE);
  static const Color surfaceCreamStrong = Color(0xFFE8E0D2);

  // ==========================================
  // Backgrounds & Surfaces (Dark Mode / Inverted)
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
  static const Color hairline = Color(0xFFE6DFD8);
  static const Color hairlineSoft = Color(0xFFEBE6DF);

  // ==========================================
  // Feedback & Status
  // ==========================================
  static const Color success = Color(0xFF5DB872);
  static const Color warning = Color(0xFFD4A017);
  static const Color error = Color(0xFFC64545);

  // ==========================================
  // Legacy aliases for compatibility
  // ==========================================
  static const Color primaryLight = primaryDisabled;
  static const Color primaryLightest = surfaceSoft;
  static const Color primaryDark = primaryActive;
  static const Color earthBrown = muted;
  static const Color soilLight = surfaceCard;
  static const Color harvestGold = accentAmber;
  static const Color danger = error;
  static const Color alert = warning;
  static const Color info = accentTeal;
  
  static const Color textPrimary = ink;
  static const Color textSecondary = body;
  static const Color textTertiary = muted;
  static const Color textDisabled = mutedSoft;
  
  static const Color white = Color(0xFFFFFFFF);
  static const Color backgroundLight = canvas;
  static const Color backgroundDark = surfaceSoft;
  static const Color divider = hairline;
  static const Color shadow = Color(0x1A000000);
  static const Color cardBackground = surfaceSoft;
  static const Color cardBorder = hairline;
  static const Color inputBackground = surfaceSoft;
  static const Color inputBorder = hairline;
  static const Color inputBorderFocused = primary;
  static const Color buttonText = onPrimary;
  static const Color iconDefault = muted;

  /// 输入框背景 - 极浅灰
  static const Color inputBackgroundLegacy = Color(0xFFF8F8F8);

  /// 输入框边框 - 浅灰
  static const Color inputBorderLegacy = Color(0xFFBDBDBD);

  /// 输入框聚焦边框 - 主色
  static const Color inputBorderFocusedLegacy = Color(0xFF2C2C2C);

  /// 按钮文字 - 白色
  static const Color buttonTextLegacy = Color(0xFFFFFFFF);

  /// 次要按钮文字 - 主色
  static const Color buttonTextSecondary = ink;

  /// 图标激活 - 主色（或可改为 success 森林绿）
  static const Color iconActive = ink;

  /// 导航栏背景 - 白色
  static const Color appBarBackground = canvas;

  /// 底部导航栏背景 - 白色
  static const Color bottomNavBackground = canvas;

  /// 底部导航栏选中 - 主色
  static const Color bottomNavSelected = ink;

  /// 底部导航栏未选中 - 灰色
  static const Color bottomNavUnselected = muted;

  // ==========================================
  // 病虫害等级颜色
  // ==========================================

  /// 轻度 - 森林绿
  static const Color pestLevelLow = success;

  /// 中度 - 赭石黄
  static const Color pestLevelMedium = accentAmber;

  /// 重度 - 古铜色
  static const Color pestLevelHigh = warning;

  /// 严重 - 铁锈红
  static const Color pestLevelSevere = error;

  // ==========================================
  // 植物状态颜色
  // ==========================================

  /// 健康 - 森林绿
  static const Color plantHealthy = success;

  /// 亚健康 - 橄榄绿
  static const Color plantSubHealthy = accentAmber;

  /// 生病 - 赭石红
  static const Color plantSick = error;

  /// 枯萎 - 棕灰
  static const Color plantWithered = muted;

  // ==========================================
  // 渐变色
  // ==========================================

  /// 主色渐变 - 从烟灰到深岩灰
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceCard, ink],
  );

  /// 警告渐变 - 从赭石黄到古铜色
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentAmber, warning],
  );

  /// 危险渐变 - 从古铜色到铁锈红
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, error],
  );

  // ==========================================
  // 季节主题色（改为黑白系）
  // ==========================================

  /// 春季 - 炭灰
  static const Color seasonSpring = muted;

  /// 夏季 - 深岩灰
  static const Color seasonSummer = ink;

  /// 秋季 - 中灰
  static const Color seasonAutumn = mutedSoft;

  /// 冬季 - 浅灰
  static const Color seasonWinter = hairline;

  // ==========================================
  // 特殊用途颜色
  // ==========================================

  /// 上传区域背景 - 极浅灰
  static const Color uploadAreaBackground = surfaceSoft;

  /// 上传区域边框 - 中岩灰
  static const Color uploadAreaBorder = hairline;

  /// 图片占位背景 - 浅灰
  static const Color imagePlaceholder = surfaceCard;

  /// 加载中颜色 - 主色
  static const Color loading = primary;

  /// 水印颜色 - 半透明黑
  static const Color watermark = Color(0x40000000);
}