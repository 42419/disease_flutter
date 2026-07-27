import 'package:farm_flutter/pages/widgets/analyzePage/components/highlight_utils.dart';
import 'package:farm_flutter/pages/widgets/common/miuix_dropdown_menu.dart';
import 'package:farm_flutter/providers/diagnosis_records_provider.dart';
import 'package:farm_flutter/providers/user_provider.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DiagnosisRecordsPage extends StatefulWidget {
  const DiagnosisRecordsPage({super.key});

  @override
  State<DiagnosisRecordsPage> createState() => _DiagnosisRecordsPageState();
}

class _DiagnosisRecordsPageState extends State<DiagnosisRecordsPage>
    with TickerProviderStateMixin {
  static const _barColors = [
    AppColors.error,
    AppColors.warning,
    AppColors.accentAmber,
    AppColors.accentTeal,
    AppColors.success,
    AppColors.muted,
    AppColors.body,
  ];

  // 排序方式下拉菜单，跟登录页角色菜单共用同一套 MiuixDropdownMenu。
  late final MiuixDropdownMenu<bool> _sortMenu = MiuixDropdownMenu<bool>(vsync: this);
  final GlobalKey _sortButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 地区名称（adcode -> 完整地名）的解析逻辑收拢在 Provider 里，和
    // RegionOptionLoader 共用一份实现，页面这里只是触发加载。
    context.read<DiagnosisRecordsProvider>().loadAdcodeNameMap();
    _fetchRecords();
  }

  @override
  void dispose() {
    _sortMenu.dispose();
    super.dispose();
  }

  Future<void> _showSortMenu(DiagnosisRecordsProvider recordsProvider) async {
    if (_sortMenu.isOpen) {
      await _sortMenu.close();
      return;
    }
    await _sortMenu.show(
      context: context,
      anchorKey: _sortButtonKey,
      items: const [
        MiuixMenuItem(value: true, label: '最新在前'),
        MiuixMenuItem(value: false, label: '最早在前'),
      ],
      selectedValue: recordsProvider.sortDescending,
      onSelected: (value) {
        if (recordsProvider.sortDescending != value) {
          recordsProvider.setSortDescending(value);
        }
      },
    );
  }

  Future<void> _fetchRecords() async {
    final user = context.read<UserProvider>();
    await context.read<DiagnosisRecordsProvider>().fetchRecords(
      role: user.role,
      nickName: user.nickName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordsProvider = context.watch<DiagnosisRecordsProvider>();
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              '诊断记录',
              style: TextStyle(
                fontFamily: "serif",
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 20,
                letterSpacing: 1.5,
              ),
            ),
            if (!recordsProvider.isLoading && recordsProvider.records.isNotEmpty)
              Text(
                '共 ${recordsProvider.records.length} 条记录',
                style: TextStyle(
                  fontFamily: "serif",
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            key: _sortButtonKey,
            tooltip: '排序方式',
            onPressed: () => _showSortMenu(recordsProvider),
            icon: Icon(
              recordsProvider.sortDescending
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: AppColors.muted,
              size: 20,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(recordsProvider, user),
    );
  }

  Widget _buildBody(DiagnosisRecordsProvider recordsProvider, UserProvider user) {
    if (recordsProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '加载中...',
              style: TextStyle(
                fontFamily: "serif",
                color: AppColors.muted,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    if (recordsProvider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 40,
                  color: AppColors.danger,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '加载失败',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                recordsProvider.errorMessage!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 140,
                height: 42,
                child: ElevatedButton(
                  onPressed: _fetchRecords,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('重新加载'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (recordsProvider.records.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLightest.withAlpha(100),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.content_paste_off_rounded,
                size: 36,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '暂无诊断记录',
              style: TextStyle(
                fontFamily: "serif",
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '完成一次诊断后，记录将显示在此',
              style: TextStyle(
                fontFamily: "serif",
                color: AppColors.muted,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchRecords,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: recordsProvider.records.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildChartCard(recordsProvider);
          return _buildRecordCard(recordsProvider.records[index - 1], recordsProvider, user);
        },
      ),
    );
  }

  Widget _buildChartCard(DiagnosisRecordsProvider recordsProvider) {
    if (recordsProvider.stats.isEmpty) return const SizedBox.shrink();
    final displayStats = recordsProvider.stats.take(7).toList();
    final maxCount = displayStats.first.value;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '病害分布',
                style: TextStyle(
                  fontFamily: "serif",
                  fontSize: 16,
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
                  '${recordsProvider.stats.length} 种',
                  style: TextStyle(
                    fontFamily: "serif",
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxCount < 3) ? 3 : (maxCount * 1.2).ceilToDouble(),
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
                          toY: (maxCount * 1.2).ceilToDouble(),
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
                      reservedSize: 56,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= displayStats.length) {
                          return const SizedBox.shrink();
                        }
                        final name = displayStats[idx].key;
                        String line1;
                        String line2;
                        if (name.length > 8) {
                          final half = (name.length / 2).ceil();
                          line1 = name.substring(0, half);
                          line2 = name.substring(half);
                        } else if (name.length > 4) {
                          final half = (name.length / 2).ceil();
                          line1 = name.substring(0, half);
                          line2 = name.substring(half);
                        } else {
                          line1 = name;
                          line2 = '';
                        }

                        return SideTitleWidget(
                          meta: meta,
                          space: 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                line1,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (line2.isNotEmpty)
                                Text(
                                  line2,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: maxCount <= 3 ? 1 : (maxCount / 3).ceilToDouble().clamp(1.0, double.infinity),
                      getTitlesWidget: (value, meta) {
                        final v = value.toInt();
                        if (v < 0 || (maxCount > 0 && v > maxCount)) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            '$v',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxCount <= 3 ? 1 : (maxCount / 3).ceilToDouble().clamp(1.0, double.infinity),
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
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${displayStats[group.x].key}\n${rod.toY.toInt()} 条记录',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent && response?.spot != null) {
                      setState(() {});
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(dynamic record, DiagnosisRecordsProvider recordsProvider, UserProvider user) {
    final isExpanded = recordsProvider.expandedId == record.id;
    
    // Evaluate severity based on name and description keywords
    final severity = _evaluateSeverity(record);
    final badgeColor = _severityBadgeColor(severity);
    final badgeLabel = _severityLabel(severity);
    
    final diseaseRank = recordsProvider.stats.indexWhere((e) => e.key == record.bhname);
    final accentColor = diseaseRank >= 0
        ? _barColors[diseaseRank % _barColors.length]
        : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(2),
            onTap: () {
              context.read<DiagnosisRecordsProvider>().toggleExpanded(record.id);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          color: accentColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          record.bhname,
                          style: TextStyle(
                            fontFamily: "serif",
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeLabel.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withAlpha(20),
borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        record.formattedTime,
                        style: TextStyle(fontFamily: "serif", fontSize: 13, color: AppColors.muted, fontStyle: FontStyle.italic),
                      ),
                      const Spacer(),
                      if (user.isAdmin) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLightest.withAlpha(60),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            record.username,
                            style: TextStyle(fontFamily: "serif", fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (recordsProvider.locationName(record.location).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            recordsProvider.locationName(record.location),
                            style: TextStyle(fontFamily: "serif", fontSize: 12, color: AppColors.muted, fontStyle: FontStyle.italic),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _expandedSection(
                    icon: Icons.science_rounded,
                    color: AppColors.danger,
                    title: '致病原因',
                    content: record.bhreason,
                  ),
                  if (record.bhadvice.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _expandedSection(
                      icon: Icons.eco_rounded,
                      color: AppColors.success,
                      title: '防治建议',
                      content: record.bhadvice,
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
          ),
        ],
      ),
    );
  }

  Widget _expandedSection({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: "serif",
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text.rich(
            TextSpan(
              children: buildHighlightedSpans(content.isEmpty ? '暂无' : content),
            ),
            style: TextStyle(
              fontFamily: "serif",
              fontSize: 14,
              color: AppColors.ink,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }

  // 0: 高危, 1: 中度, 2: 轻微, 3: 未知
  int _evaluateSeverity(dynamic record) {
    if (record.bhname.isEmpty || record.bhname == '未知') return 3;
    final name = record.bhname;
    final desc = record.bhreason + record.bhadvice;
    
    // 高危病害关键词
    if (name.contains('腐烂') || name.contains('枯萎') || 
        name.contains('疫病') || name.contains('病毒') || name.contains('溃疡') ||
        desc.contains('严重') || desc.contains('绝产') || desc.contains('致死')) {
      return 0;
    }
    // 中度病害关键词
    if (name.contains('斑') || name.contains('霉') || name.contains('锈') || 
        name.contains('炭疽') || name.contains('黑痘') ||
        desc.contains('较重') || desc.contains('落叶') || desc.contains('减产')) {
      return 1;
    }
    // 其他确诊均视为轻微
    return 2;
  }

  Color _severityBadgeColor(int severity) {
    switch (severity) {
      case 0:
        return AppColors.danger;
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.alert;
      default:
        return AppColors.success;
    }
  }

  String _severityLabel(int severity) {
    switch (severity) {
      case 0:
        return '高危';
      case 1:
        return '中等';
      case 2:
        return '轻微';
      default:
        return '';
    }
  }
}
