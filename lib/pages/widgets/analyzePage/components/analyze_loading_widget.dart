import 'package:farm_flutter/pages/widgets/analyzePage/components/looping_dot.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/app_theme.dart';
import 'package:farm_flutter/utils/app_spacing.dart';
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
                    fontFamily: kAppFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: text.isEmpty
                        ? context.colors.muted
                        : context.colors.body,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) => LoopingDot(delay: i * 300)),
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: context.colors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 14,
                            color: context.colors.muted,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '推理过程',
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              fontSize: 12,
                              color: context.colors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: context.colors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: context.colors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: SingleChildScrollView(
                          controller: _innerScrollController,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.body,
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
        color: context.colors.surfaceSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(Icons.auto_awesome, size: 14, color: context.colors.primary),
    );
  }
}
