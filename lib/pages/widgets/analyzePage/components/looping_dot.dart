import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';

class LoopingDot extends StatefulWidget {
  final int delay;
  const LoopingDot({super.key, required this.delay});

  @override
  State<LoopingDot> createState() => _LoopingDotState();
}

class _LoopingDotState extends State<LoopingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = (_controller.value * 3 + widget.delay / 2400) % 1;
        final scale = 0.3 + 0.7 * (1 - (2 * t - 1).abs());
        final alpha = 0.3 + 0.7 * (1 - (2 * t - 1).abs());
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: alpha),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
