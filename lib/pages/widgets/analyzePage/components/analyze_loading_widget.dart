import 'package:farm_flutter/pages/widgets/analyzePage/components/looping_dot.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AnalyzeLoadingWidget extends StatefulWidget {
  final ValueNotifier<String> streamingTextNotifier;
  final ScrollController scrollController;

  const AnalyzeLoadingWidget({
    super.key,
    required this.streamingTextNotifier,
    required this.scrollController,
  });

  @override
  State<AnalyzeLoadingWidget> createState() => _AnalyzeLoadingWidgetState();
}

class _AnalyzeLoadingWidgetState extends State<AnalyzeLoadingWidget> {
  final ScrollController _innerScrollController = ScrollController();
  bool _innerScrollScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.streamingTextNotifier.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    widget.streamingTextNotifier.removeListener(_scrollToBottom);
    _innerScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_innerScrollScheduled) return;
    _innerScrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _innerScrollScheduled = false;
      if (!mounted || !_innerScrollController.hasClients) return;
      try {
        final position = _innerScrollController.position;
        _innerScrollController.jumpTo(position.maxScrollExtent);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<String>(
          valueListenable: widget.streamingTextNotifier,
          builder: (context, text, _) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAiIcon(),
                const SizedBox(width: 10),
                Text(
                  text.isEmpty ? '分析中' : '思考中',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: text.isEmpty
                        ? AppColors.textTertiary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    3,
                    (i) => LoopingDot(delay: i * 300),
                  ),
                ),
              ],
            );
          },
        ),
        ValueListenableBuilder<String>(
          valueListenable: widget.streamingTextNotifier,
          builder: (context, text, _) {
            if (text.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '推理过程',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: SingleChildScrollView(
                          controller: _innerScrollController,
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAiIcon() {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.primaryLightest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.auto_awesome,
        size: 14,
        color: AppColors.primary,
      ),
    );
  }
}
