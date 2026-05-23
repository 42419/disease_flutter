import 'package:flutter/material.dart';
import 'package:farm_flutter/utils/app_colors.dart';

class AiAnalysisCard extends StatelessWidget {
  final String diseaseName;

  const AiAnalysisCard({super.key, required this.diseaseName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(2),
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
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '智能识别',
                style: const TextStyle(
                  fontFamily: "serif",
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            diseaseName.isEmpty ? '未知病害' : diseaseName,
            style: const TextStyle(
              fontFamily: "serif",
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '基于图像识别结果，正在启动智能病因溯源分析',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
