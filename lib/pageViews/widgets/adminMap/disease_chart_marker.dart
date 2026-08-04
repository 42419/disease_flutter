import 'package:fl_chart/fl_chart.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/app_theme.dart';
import 'package:farm_flutter/utils/app_spacing.dart';
import 'package:flutter/material.dart';

/// 地图弹窗中的病害分布柱状图。
class DiseaseChartMarker extends StatelessWidget {
  final List<MapEntry<String, int>> summary;

  const DiseaseChartMarker({super.key, required this.summary});

  List<Color> _barColors(BuildContext context) => [
    context.colors.error,
    context.colors.warning,
    context.colors.accentAmber,
    context.colors.accentTeal,
    context.colors.success,
    context.colors.muted,
    context.colors.body,
  ];

  @override
  Widget build(BuildContext context) {
    final displayStats = summary.take(7).toList();
    final maxCount = displayStats.first.value;
    const cardWidth = 300.0;
    const markerHeight = 226.0;
    final chartMaxY = (maxCount < 3) ? 3.0 : (maxCount * 1.2).ceilToDouble();
    final yInterval = maxCount <= 3
        ? 1.0
        : (maxCount / 3).ceilToDouble().clamp(1.0, double.infinity);
    final barColors = _barColors(context);

    return SizedBox(
      width: cardWidth + 20,
      height: markerHeight,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? context.colors.surfaceCard
                  : context.colors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: context.isDarkMode ? 0.36 : 0.16,
                  ),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, displayStats),
                const SizedBox(height: AppSpacing.sm),
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
                              color: barColors[i % barColors.length],
                              width: 20,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(2),
                                topRight: Radius.circular(2),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: chartMaxY,
                                color: context.colors.surfaceSoft.withAlpha(80),
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
                                      color: context.colors.body,
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
                                    color: context.colors.muted,
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
                          color: context.colors.hairline,
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

  Widget _buildHeader(
    BuildContext context,
    List<MapEntry<String, int>> displayStats,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: context.colors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '病害分布',
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.colors.ink,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: context.colors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Text(
            '${displayStats.length} 种',
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 11,
              color: context.colors.muted,
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
