import 'package:flutter/physics.dart';

/// HyperOS / Miuix 风格的"弹出、收起"动效参数。
///
/// 原本只在 [MiuixDropdownMenu]（下拉菜单）里用，现在抽成公共常量，
/// 供其他需要同款"弹出/收起"手感的弹层复用（例如管理员地图页点击区域
/// 弹出的病害统计卡片），保证全 App 里这类弹层的动效手感一致，也不用
/// 到处复制同一组弹簧参数。
class MiuixMotion {
  MiuixMotion._();

  /// 缩放用的弹簧参数：源自 Compose-Miuix 的 ListPopup 弹出动效。
  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 362.5,
    damping: 31.22,
  );

  static const Duration alphaEnterDuration = Duration(milliseconds: 200);
  static const Duration alphaExitDuration = Duration(milliseconds: 150);

  /// 弹簧驱动的 fraction（0~1）到缩放比例的映射：起始并不从 0 开始缩放，
  /// 而是从 0.15 开始，视觉上更接近"从锚点弹出"而不是"凭空长大"。
  static double scaleForFraction(double fraction) => 0.15 + 0.85 * fraction;
}
