import 'package:fl_chart/fl_chart.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm_flutter/providers/theme_mode_provider.dart';

/// 地图弹窗中的病害分布柱状图。
class DiseaseChartMarker extends StatelessWidget {
  final List<MapEntry<String, int>> summary;

  const DiseaseChartMarker({super.key, required this.summary});

  static List<Color> get _barColors => [
    AppColors.error,
    AppColors.warning,
    AppColors.accentAmber,
    AppColors.accentTeal,
    AppColors.success,
    AppColors.muted,
    AppColors.body,
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeModeController>(); // 深色模式切换时用于触发本页面重建
    final displayStats = summary.take(7).toList();
    final maxCount = displayStats.first.value;
    const cardWidth = 300.0;
    const markerHeight = 226.0;
    final chartMaxY = (maxCount < 3) ? 3.0 : (maxCount * 1.2).ceilToDouble();
    final yInterval = maxCount <= 3
        ? 1.0
        : (maxCount / 3).ceilToDouble().clamp(1.0, double.infinity);

    return SizedBox(
      width: cardWidth + 20,
      height: markerHeight,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: AppColors.canvas.withAlpha(244),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(displayStats),
                const SizedBox(height: 8),
                SizedBox(
                  height: 152,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      minY: 0,
                      barGroups: List.generate(displayStats.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: displayStats[i].value.toDouble(),
                              color: _barColors[i % _barColors.length],
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(2),
                                topRight: Radius.circular(2),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: chartMaxY,
                                color: AppColors.backgroundDark.withAlpha(80),
                              ),
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= displayStats.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                space: 4,
                                child: SizedBox(
                                  width: 46,
                                  child: Text(
                                    _formatChartLabel(displayStats[idx].key),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                      height: 1.15,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: yInterval,
                            getTitlesWidget: (value, meta) {
                              final v = value.toInt();
                              if (v < 0 || (maxCount > 0 && v > maxCount)) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  '$v',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textTertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.divider,
                          strokeWidth: 0.6,
                          dashArray: [4, 4],
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          tooltipMargin: 8,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${displayStats[group.x].key}\n${rod.toY.toInt()} 条记录',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(List<MapEntry<String, int>> displayStats) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '病害分布',
          style: TextStyle(
            fontFamily: "serif",
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            '${displayStats.length} 种',
            style: TextStyle(
              fontFamily: "serif",
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  static String _formatChartLabel(String name) {
    final trimmed = name.trim();
    if (trimmed.length <= 4) return trimmed;
    if (trimmed.length <= 8) {
      return '${trimmed.substring(0, 4)}\n${trimmed.substring(4)}';
    }
    final cut = (trimmed.length / 2).ceil().clamp(4, 6);
    return '${trimmed.substring(0, cut)}\n${trimmed.substring(cut)}';
  }
}
