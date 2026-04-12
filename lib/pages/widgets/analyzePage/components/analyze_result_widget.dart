import 'package:farm_flutter/pages/widgets/analyzePage/components/highlight_utils.dart';
import 'package:farm_flutter/pages/widgets/analyzePage/components/suggestion_item.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';

class AnalyzeResultWidget extends StatelessWidget {
  final String? diseaseType;
  final String? causeAnalysis;
  final ValueNotifier<String> displayedAnalysisNotifier;
  final ValueNotifier<bool> isTypingNotifier;
  final ValueNotifier<List<String>> displayedSuggestionsNotifier;

  const AnalyzeResultWidget({
    super.key,
    this.diseaseType,
    this.causeAnalysis,
    required this.displayedAnalysisNotifier,
    required this.isTypingNotifier,
    required this.displayedSuggestionsNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<String>>(
      valueListenable: displayedSuggestionsNotifier,
      builder: (context, suggestions, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAiIcon(),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildAnalysisParagraph(
                    diseaseType,
                    causeAnalysis,
                    displayedAnalysisNotifier,
                    isTypingNotifier,
                  ),
                ),
              ],
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...suggestions
                  .asMap()
                  .entries
                  .where((e) => e.value.isNotEmpty)
                  .map((entry) {
                    final isLast =
                        entry.key == suggestions.lastIndexWhere((s) => s.isNotEmpty);
                    return ValueListenableBuilder<bool>(
                      valueListenable: isTypingNotifier,
                      builder: (context, isTyping, _) {
                        return SuggestionItem(
                          suggestion: entry.value,
                          showCursor: isTyping && isLast,
                        );
                      },
                    );
                  }),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAnalysisParagraph(
    String? diseaseType,
    String? causeAnalysis,
    ValueNotifier<String> displayedNotifier,
    ValueNotifier<bool> isTypingNotifier,
  ) {
    if (diseaseType == null) {
      return ValueListenableBuilder<String>(
        valueListenable: displayedNotifier,
        builder: (context, displayed, _) {
          return Text(
            displayed.isNotEmpty ? displayed : (causeAnalysis ?? ''),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.7,
            ),
          );
        },
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: displayedNotifier,
      builder: (context, displayed, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isTypingNotifier,
          builder: (context, isTyping, _) {
            if (isTyping && displayed.isNotEmpty) {
              return RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.7,
                  ),
                  children: [
                    const TextSpan(
                      text: '根据图像特征与数据分析，当前作物感染的病害为 ',
                    ),
                    TextSpan(
                      text: diseaseType,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.danger,
                      ),
                    ),
                    const TextSpan(text: '。\n\n'),
                    TextSpan(text: displayed),
                    if (displayedNotifier.value != causeAnalysis)
                      const TextSpan(
                        text: '▎',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            }

            return RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                  height: 1.7,
                ),
                children: [
                  const TextSpan(
                    text: '根据图像特征与数据分析，当前作物感染的病害为 ',
                  ),
                  TextSpan(
                    text: diseaseType,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.danger,
                    ),
                  ),
                  const TextSpan(text: '。\n\n'),
                  if (causeAnalysis != null)
                    ...buildHighlightedSpans(causeAnalysis),
                ],
              ),
            );
          },
        );
      },
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
