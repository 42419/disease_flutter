import 'package:flutter/material.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/app_theme.dart';
import 'package:farm_flutter/utils/app_spacing.dart';

class AiAnalysisCard extends StatelessWidget {
  final String diseaseName;

  const AiAnalysisCard({super.key, required this.diseaseName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: context.colors.canvas,
        border: Border.all(color: context.colors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 20,
                decoration: BoxDecoration(
                  color: context.colors.error,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '智能识别',
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.colors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            diseaseName.isEmpty ? '未知病害' : diseaseName,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: context.colors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '基于图像识别结果，正在启动智能病因溯源分析',
            style: TextStyle(fontSize: 13, color: context.colors.muted),
          ),
        ],
      ),
    );
  }
}
