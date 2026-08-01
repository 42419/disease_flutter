import 'package:farm_flutter/pages/widgets/analyzePage/components/highlight_utils.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/app_theme.dart';
import 'package:farm_flutter/utils/app_spacing.dart';
import 'package:flutter/material.dart';

class SuggestionItem extends StatelessWidget {
  final String suggestion;
  final bool showCursor;

  const SuggestionItem({
    super.key,
    required this.suggestion,
    this.showCursor = false,
  });

  @override
  Widget build(BuildContext context) {
    String? title;
    String body = suggestion;

    final colonIdx = suggestion.indexOf('：');
    if (colonIdx > 0 && colonIdx <= 10) {
      title = suggestion.substring(0, colonIdx);
      body = suggestion.substring(colonIdx + 1).trimLeft();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
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
            if (title != null) ...[
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.colors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.colors.ink,
                        ),
                        children: buildHighlightedSpans(
                          title,
                          labelColor: context.colors.ink,
                          highlightColor: context.colors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.5,
                  color: title != null
                      ? context.colors.body
                      : context.colors.ink,
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
                      text: '\u258E',
                      style: TextStyle(
                        color: context.colors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
