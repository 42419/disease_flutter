import 'package:farm_flutter/pages/widgets/analyzePage/components/highlight_utils.dart';
import 'package:farm_flutter/pages/widgets/analyzePage/components/suggestion_item.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/app_theme.dart';
import 'package:farm_flutter/utils/app_spacing.dart';
import 'package:flutter/material.dart';

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
    return ValueListenableBuilder<List<String>>(
      valueListenable: displayedSuggestionsNotifier,
      builder: (context, suggestions, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalysisParagraph(
              context,
              diseaseType,
              causeAnalysis,
              displayedAnalysisNotifier,
              isTypingNotifier,
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _buildSectionHeader(context, '防治建议'),
              const SizedBox(height: AppSpacing.sm),
              ...suggestions
                  .asMap()
                  .entries
                  .where((e) => e.value.isNotEmpty)
                  .map((entry) {
                    final isLast =
                        entry.key ==
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
    BuildContext context,
    String? diseaseType,
    String? causeAnalysis,
    ValueNotifier<String> displayedNotifier,
    ValueNotifier<bool> isTypingNotifier,
  ) {
    if (diseaseType == null) {
      return ValueListenableBuilder<String>(
        valueListenable: displayedNotifier,
        builder: (context, displayed, _) {
          final content = displayed.isNotEmpty
              ? displayed
              : (causeAnalysis ?? '');
          return _buildStructuredAnalysisContent(context, content);
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.error.withAlpha(18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13.5,
                        color: context.colors.ink,
                      ),
                      children: [
                        const TextSpan(
                          text: '病害类型  ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: diseaseType,
                          style: TextStyle(
                            color: context.colors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (content.isNotEmpty) const SizedBox(height: AppSpacing.sm),
                if (content.isNotEmpty)
                  _buildStructuredAnalysisContent(
                    context,
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: context.colors.success,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.colors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildStructuredAnalysisContent(
    BuildContext context,
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
            context,
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
        widgets.add(
          _buildSymptomTimeline(
            context,
            rawLines[i],
            symptomLines,
            showCursor: cursorOnSymptom,
          ),
        );
        i = j - 1;
      } else {
        final isLast = i == rawLines.length - 1;
        widgets.add(
          _buildAnalysisRow(
            context,
            rawLines[i],
            showCursor: showCursor && isLast,
            isLast: isLast,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildAnalysisRow(
    BuildContext context,
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
                color: context.colors.error,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.ink,
                  ),
                  children: [
                    TextSpan(text: line),
                    if (showCursor)
                      TextSpan(
                        text: '▎',
                        style: TextStyle(
                          color: context.colors.error,
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
                  color: context.colors.primary.withAlpha(70),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.colors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.ink,
                  height: 1.55,
                ),
                children: [
                  ...buildHighlightedSpans(
                    body,
                    labelColor: context.colors.ink,
                    highlightColor: context.colors.error,
                  ),
                  if (showCursor)
                    TextSpan(
                      text: '▎',
                      style: TextStyle(
                        color: context.colors.error,
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

  Widget _buildSymptomTimeline(
    BuildContext context,
    String header,
    List<String> stages, {
    bool showCursor = false,
  }) {
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
                  color: context.colors.error,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                header,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (stages.isEmpty && showCursor)
            Padding(
              padding: const EdgeInsets.only(left: leftPad + 10),
              child: Text(
                '▎',
                style: TextStyle(
                  color: context.colors.error,
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
            final body = hasColon
                ? stageLine.substring(colonIdx + 1).trimLeft()
                : '';
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
                            color: context.colors.hairline,
                          ),
                        const SizedBox(height: AppSpacing.xxs),
                        Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.success,
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.success.withAlpha(60),
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
                              color: context.colors.hairline,
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
                                color: context.colors.ink,
                              ),
                              children: [
                                TextSpan(text: label),
                                if (showStageCursor && !hasColon)
                                  TextSpan(
                                    text: '▎',
                                    style: TextStyle(
                                      color: context.colors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (hasColon) const SizedBox(height: AppSpacing.xs),
                          if (hasColon)
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: context.colors.body,
                                  height: 1.55,
                                ),
                                children: [
                                  ...buildHighlightedSpans(
                                    body,
                                    labelColor: context.colors.ink,
                                    highlightColor: context.colors.error,
                                  ),
                                  if (showStageCursor)
                                    TextSpan(
                                      text: '▎',
                                      style: TextStyle(
                                        color: context.colors.error,
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
