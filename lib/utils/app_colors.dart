import 'package:flutter/material.dart';

/// 农业种植病虫害防治APP - 配色方案
/// 设计理念：高级、稳重、专业、优雅
class AppColors {
  // ==========================================
  // 主色调 - 黑白系（代表专业、稳重、高级）
  // ==========================================
  
  /// 主色 - 纯黑色（用于主要按钮、导航栏等）
  static const Color primary = Color(0xFF1A1A1A);

  /// 主色浅色 - 深灰色（用于次要按钮、标签等）
  static const Color primaryLight = Color(0xFF4A4A4A);
  
  /// 主色极浅色 - 浅灰色（用于背景装饰、轻微高亮）
  static const Color primaryLightest = Color(0xFFE8E8E8);
  
  /// 主色深色 - 极深黑色（用于强调、选中状态）
  static const Color primaryDark = Color(0xFF0D0D0D);

  // ==========================================
  // 辅助色 - 灰度系（代表稳重、专业）
  // ==========================================
  
  /// 辅助灰 - 深灰色（用于次要信息、边框）
  static const Color earthBrown = Color(0xFF696969);
  
  /// 浅灰 - 中浅灰色（用于背景、卡片）
  static const Color soilLight = Color(0xFFD3D3D3);
  
  /// 白银色 - 高级银灰（用于强调、重要信息）
  static const Color harvestGold = Color(0xFFC0C0C0);

  // ==========================================
  // 警示色 - 红橙系（用于病虫害提醒、警告）
  // ==========================================
  
  /// 危险红 - 深红色（用于严重病虫害、错误提示）
  static const Color danger = Color(0xFFD32F2F);
  
  /// 警告橙 - 橙色（用于中等病虫害、警告）
  static const Color warning = Color(0xFFFF9800);
  
  /// 提醒黄 - 黄色（用于轻微病虫害、提示）
  static const Color alert = Color(0xFFFFC107);

  // ==========================================
  // 功能色 - 蓝色系（用于信息、链接、操作）
  // ==========================================
  
  /// 信息蓝 - 天蓝色（用于信息提示、链接）
  static const Color info = Color(0xFF2196F3);
  
  /// 成功绿 - 绿色（用于成功状态、完成操作）
  static const Color success = Color(0xFF4CAF50);
  
  /// 失败红 - 红色（用于失败状态、错误）
  static const Color error = Color(0xFFE53935);

  // ==========================================
  // 中性色 - 灰色系（用于文字、背景、边框）
  // ==========================================
  
  /// 主要文字 - 深灰色（用于标题、正文）
  static const Color textPrimary = Color(0xFF212121);
  
  /// 次要文字 - 中灰色（用于说明文字、副标题）
  static const Color textSecondary = Color(0xFF616161);
  
  /// 辅助文字 - 浅灰色（用于占位符、提示文字）
  static const Color textTertiary = Color(0xFF9E9E9E);
  
  /// 禁用文字 - 灰色（用于禁用状态）
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  /// 白色 - 纯白（用于背景、卡片）
  static const Color white = Color(0xFFFFFFFF);
  
  /// 浅灰背景 - 极浅灰色（用于页面背景）
  static const Color backgroundLight = Color(0xFFF5F5F5);
  
  /// 中灰背景 - 中灰色（用于深色模式或对比背景）
  static const Color backgroundDark = Color(0xFFE0E0E0);
  
  /// 分割线 - 浅灰色（用于分割线、边框）
  static const Color divider = Color(0xFFE0E0E0);
  
  /// 阴影色 - 半透明黑色（用于阴影效果）
  static const Color shadow = Color(0x1A000000);

  // ==========================================
  // 组件颜色
  // ==========================================
  
  /// 卡片背景 - 白色
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  /// 卡片边框 - 浅灰色
  static const Color cardBorder = Color(0xFFE0E0E0);
  
  /// 输入框背景 - 极浅灰色
  static const Color inputBackground = Color(0xFFF5F5F5);
  
  /// 输入框边框 - 浅灰色
  static const Color inputBorder = Color(0xFFBDBDBD);
  
  /// 输入框聚焦边框 - 主色
  static const Color inputBorderFocused = Color(0xFF1A1A1A);
  
  /// 按钮文字 - 白色
  static const Color buttonText = Color(0xFFFFFFFF);
  
  /// 次要按钮文字 - 主色
  static const Color buttonTextSecondary = Color(0xFF1A1A1A);
  
  /// 图标默认 - 深灰色
  static const Color iconDefault = Color(0xFF616161);
  
  /// 图标激活 - 主色
  static const Color iconActive = Color(0xFF1A1A1A);
  
  /// 导航栏背景 - 白色
  static const Color appBarBackground = Color(0xFFFFFFFF);
  
  /// 底部导航栏背景 - 白色
  static const Color bottomNavBackground = Color(0xFFFFFFFF);
  
  /// 底部导航栏选中 - 主色
  static const Color bottomNavSelected = Color(0xFF1A1A1A);
  
  /// 底部导航栏未选中 - 灰色
  static const Color bottomNavUnselected = Color(0xFF9E9E9E);

  // ==========================================
  // 病虫害等级颜色
  // ==========================================
  
  /// 轻度 - 绿色
  static const Color pestLevelLow = Color(0xFF4CAF50);
  
  /// 中度 - 黄色
  static const Color pestLevelMedium = Color(0xFFFFC107);
  
  /// 重度 - 橙色
  static const Color pestLevelHigh = Color(0xFFFF9800);
  
  /// 严重 - 红色
  static const Color pestLevelSevere = Color(0xFFD32F2F);

  // ==========================================
  // 植物状态颜色
  // ==========================================
  
  /// 健康 - 绿色
  static const Color plantHealthy = Color(0xFF4CAF50);
  
  /// 亚健康 - 黄绿色
  static const Color plantSubHealthy = Color(0xFFAED581);
  
  /// 生病 - 橙红色
  static const Color plantSick = Color(0xFFFF7043);
  
  /// 枯萎 - 棕色
  static const Color plantWithered = Color(0xFF8D6E63);

  // ==========================================
  // 渐变色
  // ==========================================
  
  /// 主色渐变 - 从浅灰到深黑
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8E8E8), Color(0xFF1A1A1A)],
  );
  
  /// 警告渐变 - 从黄色到橙色
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC107), Color(0xFFFF9800)],
  );
  
  /// 危险渐变 - 从橙色到红色
  static const LinearGradient dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9800), Color(0xFFD32F2F)],
  );

  // ==========================================
  // 季节主题色（改为黑白系）
  // ==========================================
  
  /// 春季 - 深灰色
  static const Color seasonSpring = Color(0xFF5A5A5A);
  
  /// 夏季 - 黑色
  static const Color seasonSummer = Color(0xFF1A1A1A);
  
  /// 秋季 - 中灰色
  static const Color seasonAutumn = Color(0xFF808080);
  
  /// 冬季 - 浅灰色
  static const Color seasonWinter = Color(0xFFC0C0C0);

  // ==========================================
  // 特殊用途颜色
  // ==========================================
  
  /// 上传区域背景 - 浅灰色
  static const Color uploadAreaBackground = Color(0xFFF5F5F5);
  
  /// 上传区域边框 - 深灰色
  static const Color uploadAreaBorder = Color(0xFF4A4A4A);
  
  /// 图片占位背景 - 浅灰色
  static const Color imagePlaceholder = Color(0xFFE0E0E0);
  
  /// 加载中颜色 - 主色
  static const Color loading = Color(0xFF1A1A1A);
  
  /// 水印颜色 - 半透明黑色
  static const Color watermark = Color(0x40000000);
}