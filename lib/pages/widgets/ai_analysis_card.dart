import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:farm_flutter/utils/app_colors.dart';

class AiAnalysisCard extends StatefulWidget {
  final String diseaseName;

  const AiAnalysisCard({super.key, required this.diseaseName});

  @override
  State<AiAnalysisCard> createState() => _AiAnalysisCardState();
}

class _AiAnalysisCardState extends State<AiAnalysisCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // 使用缓动曲线让动画更自然
    _progressAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    // 开始动画
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        color: AppColors.backgroundLight, // 浅灰背景
        child: Stack(
          children: [
            // 右上角背景装饰圆
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLightest,
                ),
              ),
            ),
            // 右下方背景装饰圆
            Positioned(
              bottom: -40,
              left: 60,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRect( // 1. 必须用 ClipRect 裁剪，否则模糊效果会溢出
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 2. 设置模糊强度
                  child: Container(
                    decoration: BoxDecoration(
                      // 3. 设置半透明颜色，让模糊的内容透出来
                      // 0.5 是透明度，颜色可以根据需要改成白色或黑色
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder), // 可选：加个边框更有质感
                    ),
                  ),
                ),
              )),
            // 卡片主要内容
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左上角标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.filter_center_focus,
                          size: 15,
                          color: AppColors.textPrimary,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'AI分析结果',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 主要病害名称
                  Text(
                    widget.diseaseName.isEmpty ? '未知病害' : widget.diseaseName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // 对应的学名/英文名
                  Text(
                    'Valsa mali Miyabe et Yamada',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 横向统计数据行
                  Row(
                    children: [
                      Expanded(child: _buildStatColumn('93.6%', '置信度')),
                      _buildDivider(),
                      Expanded(child: _buildStatColumn('高', '风险等级')),
                      _buildDivider(),
                      Expanded(child: _buildStatColumn('中期', '病害阶段')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 进度条部分头部
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        '智能诊断置信度',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '93.6%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 进度条组件（带动画）
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SizedBox(
                            height: 7,
                            width: double.infinity,
                            child: Stack(
                              children: [
                                // 底色条（100%宽度，始终可见）
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLightest, // 进度条底色
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color: AppColors.cardBorder,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                // 填充条（动画宽度）
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: constraints.maxWidth * _progressAnimation.value * 0.936,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.primary, // 进度条填充色
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.divider, // 分割线颜色
    );
  }
}
