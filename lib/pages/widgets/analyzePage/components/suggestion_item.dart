import 'package:farm_flutter/pages/widgets/analyzePage/components/highlight_utils.dart';
import 'package:farm_flutter/utils/app_colors.dart';
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: AppColors.hairline),
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
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: "serif",
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        children: buildHighlightedSpans(title),
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
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  height: 1.55,
                ),
                children: [
                  ...buildHighlightedSpans(body),
                  if (showCursor)
                    const TextSpan(
                      text: '\u258E',
                      style: TextStyle(
                        color: AppColors.danger,
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
