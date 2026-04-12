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
    final commaIdx = suggestion.indexOf('，');
    int splitIdx = -1;
    if (colonIdx > 0 && colonIdx <= 10) {
      splitIdx = colonIdx;
    } else if (commaIdx > 0 && commaIdx <= 12) {
      splitIdx = commaIdx;
    }
    if (splitIdx > 0) {
      title = suggestion.substring(0, splitIdx);
      body = suggestion.substring(splitIdx + 1);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      children: buildHighlightedSpans(title),
                    ),
                  ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: title != null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      height: 1.5,
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
        ],
      ),
    );
  }
}
