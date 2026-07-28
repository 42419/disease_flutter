import 'package:farm_flutter/pages/widgets/analyzePage/components/highlight_utils.dart';
import 'package:farm_flutter/pages/widgets/analyzePage/components/suggestion_item.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm_flutter/providers/theme_mode_provider.dart';

class AnalyzeResultWidget extends StatelessWidget {
  final String? diseaseType;
  final String? causeAnalysis;
  final int symptomCount;
  final ValueNotifier<String> displayedAnalysisNotifier;
  final ValueNotifier<bool> isTypingNotifier;
  final ValueNotifier<List<String>> displayedSuggestionsNotifier;

  const AnalyzeResultWidget({
    super.key,
    this.diseaseType,
    this.causeAnalysis,
    this.symptomCount = 0,
    required this.displayedAnalysisNotifier,
    required this.isTypingNotifier,
    required this.displayedSuggestionsNotifier,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeModeController>(); // 深色模式切换时用于触发本页面重建
    return ValueListenableBuilder<List<String>>(
      valueListenable: displayedSuggestionsNotifier,
      builder: (context, suggestions, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalysisParagraph(
              diseaseType,
              causeAnalysis,
              displayedAnalysisNotifier,
              isTypingNotifier,
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionHeader('防治建议'),
              const SizedBox(height: 8),
              ...suggestions
                  .asMap()
                  .entries
                  .where((e) => e.value.isNotEmpty)
                  .map((entry) {
                    final isLast = entry.key ==
                        suggestions.lastIndexWhere((s) => s.isNotEmpty);
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
          final content =
              displayed.isNotEmpty ? displayed : (causeAnalysis ?? '');
          return _buildStructuredAnalysisContent(content);
        },
      );
    }

    return ValueListenableBuilder<String>(
      valueListenable: displayedNotifier,
      builder: (context, displayed, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: isTypingNotifier,
          builder: (context, isTyping, _) {
            final content = isTyping && displayed.isNotEmpty
                ? displayed
                : (causeAnalysis ?? '');
            final showCursor =
                isTyping && displayedNotifier.value != causeAnalysis;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withAlpha(18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        const TextSpan(
                          text: '病害类型  ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: diseaseType,
                          style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (content.isNotEmpty) const SizedBox(height: 8),
                if (content.isNotEmpty)
                  _buildStructuredAnalysisContent(
                    content,
                    showCursor: showCursor,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: "serif",
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStructuredAnalysisContent(
    String content, {
    bool showCursor = false,
  }) {
    final rawLines = content
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (rawLines.isEmpty) {
      return const SizedBox.shrink();
    }

    final symptomStart = rawLines.indexWhere((l) => l == '病害症状');
    final hasSymptomSection = symptomStart >= 0;

    if (!hasSymptomSection) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rawLines.asMap().entries.map((entry) {
          final isLast = entry.key == rawLines.length - 1;
          return _buildAnalysisRow(
            entry.value,
            showCursor: showCursor && isLast,
            isLast: isLast,
          );
        }).toList(),
      );
    }

    final List<Widget> widgets = [];

    for (int i = 0; i < rawLines.length; i++) {
      if (i == symptomStart) {
        final symptomLines = <String>[];
        int j = i + 1;
        if (showCursor) {
          while (j < rawLines.length) {
            symptomLines.add(rawLines[j]);
            j++;
          }
        } else {
          while (j < rawLines.length &&
              j <= i + symptomCount &&
              rawLines[j].contains('：')) {
            symptomLines.add(rawLines[j]);
            j++;
          }
        }
        final cursorOnSymptom =
            showCursor && i + symptomLines.length == rawLines.length - 1;
        widgets.add(_buildSymptomTimeline(
          rawLines[i],
          symptomLines,
          showCursor: cursorOnSymptom,
        ));
        i = j - 1;
      } else {
        final isLast = i == rawLines.length - 1;
        widgets.add(_buildAnalysisRow(
          rawLines[i],
          showCursor: showCursor && isLast,
          isLast: isLast,
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildAnalysisRow(
    String line, {
    bool showCursor = false,
    bool isLast = false,
  }) {
    final colonIndex = line.indexOf('：');

    final bool isSectionHeader =
        colonIndex <= 0 || colonIndex >= line.length - 1;

    if (isSectionHeader) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 2),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: "serif",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    TextSpan(text: line),
                    if (showCursor)
                      TextSpan(
                        text: '▎',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final label = line.substring(0, colonIndex);
    final body = line.substring(colonIndex + 1).trimLeft();

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(70),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  height: 1.55,
                ),
                children: [
                  ...buildHighlightedSpans(body),
                  if (showCursor)
                    TextSpan(
                      text: '▎',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomTimeline(String header, List<String> stages,
      {bool showCursor = false}) {
    const lineWidth = 2.0;
    const dotSize = 10.0;
    const leftPad = 14.0;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                header,
                style: TextStyle(
                  fontFamily: "serif",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (stages.isEmpty && showCursor)
            Padding(
              padding: const EdgeInsets.only(left: leftPad + 10),
              child: Text(
                '▎',
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ...List.generate(stages.length, (i) {
            final isFirst = i == 0;
            final isLast = i == stages.length - 1;
            final stageLine = stages[i];
            final colonIdx = stageLine.indexOf('：');
            final hasColon = colonIdx > 0;
            final label = hasColon
                ? stageLine.substring(0, colonIdx)
                : stageLine;
            final body =
                hasColon ? stageLine.substring(colonIdx + 1).trimLeft() : '';
            final showStageCursor = showCursor && isLast;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: leftPad,
                    child: Column(
                      children: [
                        if (!isFirst)
                          Container(
                            width: lineWidth,
                            height: 4,
                            color: AppColors.cardBorder,
                          ),
                        const SizedBox(height: 2),
                        Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withAlpha(60),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: lineWidth,
                              color: AppColors.cardBorder,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              children: [
                                TextSpan(text: label),
                                if (showStageCursor && !hasColon)
                                  TextSpan(
                                    text: '▎',
                                    style: TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (hasColon) const SizedBox(height: 4),
                          if (hasColon)
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.textSecondary,
                                  height: 1.55,
                                ),
                                children: [
                                  ...buildHighlightedSpans(body),
                                  if (showStageCursor)
                                    TextSpan(
                                      text: '▎',
                                      style: TextStyle(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
