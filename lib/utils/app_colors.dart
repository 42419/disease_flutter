import 'package:flutter/material.dart';

/// 农业种植病虫害防治APP - 配色方案
/// 设计理念：高级、稳重、专业、优雅
class AppColors {
  // ==========================================
  // 主色调 - 墨岩系（代表专业、稳重、高级）
  // ==========================================

  /// 主色 - 深岩灰（用于主要按钮、导航栏等，替代纯黑）
  static const Color primary = Color(0xFF2C2C2C);

  /// 主色浅色 - 中岩灰（用于次要按钮、标签等）
  static const Color primaryLight = Color(0xFF5A5A5A);

  /// 主色极浅色 - 烟灰（用于背景装饰、轻微高亮）
  static const Color primaryLightest = Color(0xFFE0E0E0);

  /// 主色深色 - 极深岩灰（用于强调、选中状态）
  static const Color primaryDark = Color(0xFF1A1A1A);

  // ==========================================
  // 辅助色 - 灰度与生机系（代表稳重、专业、农业）
  // ==========================================

  /// 辅助灰 - 炭灰（用于次要信息、边框）
  static const Color earthBrown = Color(0xFF4F4F4F);

  /// 浅灰 - 银灰（用于背景、卡片，更有质感）
  static const Color soilLight = Color(0xFFD6D6D6);

  /// 白银色 - 铂金灰（用于强调、重要信息）
  static const Color harvestGold = Color(0xFFA3A3A3);

  // ==========================================
  // 警示色 - 锈迹系（用于病虫害提醒、警告）
  // ==========================================

  /// 危险红 - 铁锈红（用于严重病虫害、错误提示，更稳重）
  static const Color danger = Color(0xFFB71C1C);

  /// 警告橙 - 古铜色（用于中等病虫害、警告，更高级）
  static const Color warning = Color(0xFFD35400);

  /// 提醒黄 - 赭石黄（用于轻微病虫害、提示，不刺眼）
  static const Color alert = Color(0xFFE67E22);

  // ==========================================
  // 功能色 - 森林系（用于信息、链接、操作）
  // ==========================================

  /// 信息蓝 - 深青灰（用于信息提示、链接，融入黑白系）
  static const Color info = Color(0xFF37474F);

  /// 成功绿 - 森林绿（用于成功状态、完成操作，代表生机）
  static const Color success = Color(0xFF2E7D32);

  /// 失败红 - 深红（用于失败状态、错误）
  static const Color error = Color(0xFFC62828);

  // ==========================================
  // 中性色 - 灰色系（用于文字、背景、边框）
  // ==========================================

  /// 主要文字 - 炭灰（用于标题、正文，比纯黑柔和）
  static const Color textPrimary = Color(0xFF2C2C2C);

  /// 次要文字 - 中灰（用于说明文字、副标题）
  static const Color textSecondary = Color(0xFF5F5F5F);

  /// 辅助文字 - 浅灰（用于占位符、提示文字）
  static const Color textTertiary = Color(0xFF9E9E9E);

  /// 禁用文字 - 银灰（用于禁用状态）
  static const Color textDisabled = Color(0xFFBDBDBD);

  /// 白色 - 纯白（用于背景、卡片）
  static const Color white = Color(0xFFFFFFFF);

  /// 浅灰背景 - 极浅灰（用于页面背景，保护视力）
  static const Color backgroundLight = Color(0xFFF8F8F8);

  /// 中灰背景 - 浅灰（用于深色模式或对比背景）
  static const Color backgroundDark = Color(0xFFECECEC);

  /// 分割线 - 浅灰（用于分割线、边框）
  static const Color divider = Color(0xFFE0E0E0);

  /// 阴影色 - 半透明黑（用于阴影效果）
  static const Color shadow = Color(0x1A000000);

  // ==========================================
  // 组件颜色
  // ==========================================

  /// 卡片背景 - 白色
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// 卡片边框 - 浅灰
  static const Color cardBorder = Color(0xFFE0E0E0);

  /// 输入框背景 - 极浅灰
  static const Color inputBackground = Color(0xFFF8F8F8);

  /// 输入框边框 - 浅灰
  static const Color inputBorder = Color(0xFFBDBDBD);

  /// 输入框聚焦边框 - 主色
  static const Color inputBorderFocused = Color(0xFF2C2C2C);

  /// 按钮文字 - 白色
  static const Color buttonText = Color(0xFFFFFFFF);

  /// 次要按钮文字 - 主色
  static const Color buttonTextSecondary = Color(0xFF2C2C2C);

  /// 图标默认 - 中灰
  static const Color iconDefault = Color(0xFF5F5F5F);

  /// 图标激活 - 主色（或可改为 success 森林绿）
  static const Color iconActive = Color(0xFF2C2C2C);

  /// 导航栏背景 - 白色
  static const Color appBarBackground = Color(0xFFFFFFFF);

  /// 底部导航栏背景 - 白色
  static const Color bottomNavBackground = Color(0xFFFFFFFF);

  /// 底部导航栏选中 - 主色
  static const Color bottomNavSelected = Color(0xFF2C2C2C);

  /// 底部导航栏未选中 - 灰色
  static const Color bottomNavUnselected = Color(0xFF9E9E9E);

  // ==========================================
  // 病虫害等级颜色
  // ==========================================

  /// 轻度 - 森林绿
  static const Color pestLevelLow = Color(0xFF2E7D32);

  /// 中度 - 赭石黄
  static const Color pestLevelMedium = Color(0xFFE67E22);

  /// 重度 - 古铜色
  static const Color pestLevelHigh = Color(0xFFD35400);

  /// 严重 - 铁锈红
  static const Color pestLevelSevere = Color(0xFFB71C1C);

  // ==========================================
  // 植物状态颜色
  // ==========================================

  /// 健康 - 森林绿
  static const Color plantHealthy = Color(0xFF2E7D32);

  /// 亚健康 - 橄榄绿
  static const Color plantSubHealthy = Color(0xFF689F38);

  /// 生病 - 赭石红
  static const Color plantSick = Color(0xFFC0392B);

  /// 枯萎 - 棕灰
  static const Color plantWithered = Color(0xFF795548);

  // ==========================================
  // 渐变色
  // ==========================================

  /// 主色渐变 - 从烟灰到深岩灰
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE0E0E0), Color(0xFF2C2C2C)],
  );

  /// 警告渐变 - 从赭石黄到古铜色
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE67E22), Color(0xFFD35400)],
  );

  /// 危险渐变 - 从古铜色到铁锈红
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD35400), Color(0xFFB71C1C)],
  );

  // ==========================================
  // 季节主题色（改为黑白系）
  // ==========================================

  /// 春季 - 炭灰
  static const Color seasonSpring = Color(0xFF4F4F4F);

  /// 夏季 - 深岩灰
  static const Color seasonSummer = Color(0xFF2C2C2C);

  /// 秋季 - 中灰
  static const Color seasonAutumn = Color(0xFF8C8C8C);

  /// 冬季 - 浅灰
  static const Color seasonWinter = Color(0xFFC0C0C0);

  // ==========================================
  // 特殊用途颜色
  // ==========================================

  /// 上传区域背景 - 极浅灰
  static const Color uploadAreaBackground = Color(0xFFF8F8F8);

  /// 上传区域边框 - 中岩灰
  static const Color uploadAreaBorder = Color(0xFF5A5A5A);

  /// 图片占位背景 - 浅灰
  static const Color imagePlaceholder = Color(0xFFE0E0E0);

  /// 加载中颜色 - 主色
  static const Color loading = Color(0xFF2C2C2C);

  /// 水印颜色 - 半透明黑
  static const Color watermark = Color(0x40000000);
}