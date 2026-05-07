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
          color: AppColors.success.withAlpha(10),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: AppColors.success.withAlpha(60),
              width: 3,
            ),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
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
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}
