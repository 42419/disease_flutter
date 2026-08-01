/// 间距常量集，对应项目里原先散落各处的 `SizedBox(height: 16)`、
/// `EdgeInsets.all(24)` 等硬编码数值——这些数值本身没变，只是收拢到
/// 一套命名好的常量里，方便保持视觉一致性，以后要整体调整间距节奏时
/// 也只需要改这一处。
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;
}

/// 圆角常量集，对应原先散落各处的 `BorderRadius.circular(8)` 等硬编码
/// 数值。
class AppRadius {
  AppRadius._();

  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 20;
}
