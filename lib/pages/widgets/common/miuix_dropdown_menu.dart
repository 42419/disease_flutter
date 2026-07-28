import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'package:farm_flutter/utils/app_colors.dart';

/// 一个下拉菜单选项。
class MiuixMenuItem<T> {
  final T value;
  final String label;

  const MiuixMenuItem({required this.value, required this.label});
}

/// 通用下拉菜单：缩放 + 纵向裁剪揭示 + 独立的内容/蒙层透明度动画。
///
/// 用法：调用方 State 需要 `with TickerProviderStateMixin`，持有一个本类
/// 实例，在 dispose() 里调用它的 dispose()，需要弹出菜单时调用 show()。
class MiuixDropdownMenu<T> {
  MiuixDropdownMenu({required TickerProvider vsync}) : _vsync = vsync;

  final TickerProvider _vsync;

  AnimationController? _fractionCtrl;
  AnimationController? _alphaCtrl;
  AnimationController? _dimCtrl;
  OverlayEntry? _overlayEntry;
  ValueChanged<T>? _onSelected;
  bool _disposed = false;

  bool get isOpen => _overlayEntry != null;

  static const SpringDescription _fractionSpring = SpringDescription(
    mass: 1,
    stiffness: 362.5,
    damping: 31.22,
  );
  static const Duration _alphaEnterDuration = Duration(milliseconds: 200);
  static const Duration _alphaExitDuration = Duration(milliseconds: 150);
  static const Duration _dimEnterDuration = Duration(milliseconds: 300);
  static const Duration _dimExitDuration = Duration(milliseconds: 150);

  void _ensureControllers() {
    _fractionCtrl ??= AnimationController(
      vsync: _vsync,
      duration: const Duration(milliseconds: 320),
    );
    _alphaCtrl ??= AnimationController(vsync: _vsync, duration: _alphaEnterDuration);
    _dimCtrl ??= AnimationController(vsync: _vsync, duration: _dimEnterDuration);
  }

  /// 弹出菜单。[anchorKey] 是触发控件的 GlobalKey，用来定位菜单该出现在哪。
  Future<void> show({
    required BuildContext context,
    required GlobalKey anchorKey,
    required List<MiuixMenuItem<T>> items,
    required T? selectedValue,
    required ValueChanged<T> onSelected,
    double menuWidth = 200,
    double menuItemHeight = 64,
  }) async {
    if (_disposed) return;
    if (isOpen) {
      await close();
      return;
    }
    _ensureControllers();

    final RenderBox? button =
        anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final Offset buttonPos = button.localToGlobal(Offset.zero);
    final Size buttonSize = button.size;
    final screenSize = MediaQuery.of(context).size;

    final double menuHeight = menuItemHeight * items.length + 24;

    double menuLeft = buttonPos.dx + buttonSize.width - menuWidth;
    double menuTop = buttonPos.dy + buttonSize.height + 6;
    if (menuLeft < 8) menuLeft = 8;
    if (menuLeft + menuWidth > screenSize.width - 8) {
      menuLeft = screenSize.width - menuWidth - 8;
    }
    // 下方空间不够时向上弹出，裁剪揭示方向要跟着切换。
    bool expandFromTop = true;
    if (menuTop + menuHeight > screenSize.height - 8) {
      menuTop = buttonPos.dy - menuHeight - 6;
      expandFromTop = false;
    }

    _onSelected = onSelected;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: Listenable.merge([_fractionCtrl!, _alphaCtrl!, _dimCtrl!]),
          builder: (context, _) {
            final fraction = _fractionCtrl!.value;
            final clipFraction = fraction.clamp(0.0, 1.0);
            final scale = 0.15 + 0.85 * fraction;
            final alpha = _alphaCtrl!.value.clamp(0.0, 1.0);
            final dimAlpha = _dimCtrl!.value.clamp(0.0, 1.0);

            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: close,
                    behavior: HitTestBehavior.translucent,
                    child: Opacity(
                      opacity: dimAlpha,
                      child: Container(color: Colors.black.withValues(alpha: 0.16)),
                    ),
                  ),
                ),
                Positioned(
                  left: menuLeft,
                  top: menuTop,
                  child: Opacity(
                    opacity: alpha,
                    child: Transform.scale(
                      alignment: expandFromTop
                          ? Alignment.topRight
                          : Alignment.bottomRight,
                      scale: scale,
                      child: ClipPath(
                        clipper: _MiuixRevealClipper(
                          progress: clipFraction,
                          radius: 16,
                          fromTop: expandFromTop,
                        ),
                        child: SizedBox(
                          width: menuWidth,
                          child: Material(
                            color: AppColors.isDark
                                ? AppColors.surfaceCard
                                : AppColors.canvas,
                            elevation: 16,
                            shadowColor: Colors.black.withValues(alpha: 0.22),
                            shape: const ContinuousRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final item in items)
                                    _MiuixMenuItemTile<T>(
                                      label: item.label,
                                      selected: item.value == selectedValue,
                                      onTap: () => close(result: item.value),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _fractionCtrl!
      ..stop()
      ..value = 0
      ..animateWith(SpringSimulation(_fractionSpring, 0, 1, 0));
    _alphaCtrl!
      ..value = 0
      ..animateTo(1, duration: _alphaEnterDuration, curve: Curves.fastOutSlowIn);
    _dimCtrl!
      ..value = 0
      ..animateTo(1, duration: _dimEnterDuration, curve: Curves.easeOutSine);
  }

  /// 关闭菜单，[result] 非空时视为选中该项。
  Future<void> close({T? result}) async {
    if (!isOpen) return;

    final fractionVelocity =
        _fractionCtrl!.isAnimating ? _fractionCtrl!.velocity : 0.0;
    _fractionCtrl!.animateWith(
      SpringSimulation(_fractionSpring, _fractionCtrl!.value, 0, fractionVelocity),
    );
    _dimCtrl!.animateTo(0, duration: _dimExitDuration, curve: Curves.easeOutSine);
    await _alphaCtrl!.animateTo(0, duration: _alphaExitDuration, curve: Curves.fastOutSlowIn);

    if (_disposed) return;

    _fractionCtrl!.stop();
    _fractionCtrl!.value = 0;
    _alphaCtrl!.value = 0;
    _dimCtrl!.value = 0;

    _overlayEntry?.remove();
    _overlayEntry = null;

    final onSelected = _onSelected;
    _onSelected = null;
    if (result != null) {
      onSelected?.call(result);
    }
  }

  void dispose() {
    _disposed = true;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _fractionCtrl?.dispose();
    _alphaCtrl?.dispose();
    _dimCtrl?.dispose();
  }
}

/// 纵向裁剪揭示：一条与菜单等宽的横向色带从锚点一侧向另一侧长高，
/// 只裁高度不裁宽度。
class _MiuixRevealClipper extends CustomClipper<Path> {
  final double progress;
  final double radius;
  final bool fromTop;

  const _MiuixRevealClipper({
    required this.progress,
    required this.radius,
    required this.fromTop,
  });

  @override
  Path getClip(Size size) {
    final visibleHeight = size.height * progress;
    final clipStart = fromTop ? 0.0 : size.height - visibleHeight;
    final rect = Rect.fromLTWH(0, clipStart, size.width, visibleHeight);
    return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  }

  @override
  bool shouldReclip(covariant _MiuixRevealClipper oldClipper) {
    return oldClipper.progress != progress ||
        oldClipper.fromTop != fromTop ||
        oldClipper.radius != radius;
  }
}

class _MiuixMenuItemTile<T> extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MiuixMenuItemTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: selected ? AppColors.primary : AppColors.ink,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
