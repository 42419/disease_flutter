import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// 对文本中的关键词进行高亮处理，返回 InlineSpan 列表。
/// badgeKeywords 以黑色圆角标签显示，其余关键词以红色粗体显示。
List<InlineSpan> buildHighlightedSpans(String text) {
  const keywords = [
    // 病害特征
    '侵染', '传播', '高温', '高湿', '湿度', '温度',
    '通风', '修剪', '施肥', '钙肥', '硼肥',
    '抗病品种', '套袋', '伤口', '病原菌',
    '喷施', '农药', '微生物',
    // 防治方法
    '物理防治', '化学防治', '生物防治', '农业防治',
    // 农业措施
    '轮作', '间作', '深耕', '翻耕', '除草',
    '灌溉', '排水', '地膜覆盖', '遮阳网',
    // 生物类
    '天敌', '寄生', '捕食', '有益昆虫',
    '枯草芽孢杆菌', '木霉菌', '苏云金杆菌',
    // 化学类
    '杀菌剂', '杀虫剂', '杀螨剂', '内吸性',
    '触杀', '胃毒', '广谱', '低毒',
    // 物理类
    '诱杀', '防虫网', '黄板', '蓝板',
    '灯光诱杀', '高温闷棚', '土壤消毒',
    // 环境管理
    '果园管理', '田间管理', '清园', '越冬',
    '休眠期', '生长期', '花期', '果实膨大期',
  ];

  const badgeKeywords = ['物理防治', '化学防治', '生物防治', '农业防治'];

  final spans = <InlineSpan>[];
  var remaining = text;

  while (remaining.isNotEmpty) {
    int? earliestIdx;
    String? earliestKeyword;

    for (final kw in keywords) {
      final idx = remaining.indexOf(kw);
      if (idx >= 0 && (earliestIdx == null || idx < earliestIdx)) {
        earliestIdx = idx;
        earliestKeyword = kw;
      }
    }

    if (earliestIdx == null) {
      spans.add(TextSpan(text: remaining));
      break;
    }

    if (earliestIdx > 0) {
      spans.add(TextSpan(text: remaining.substring(0, earliestIdx)));
    }

    if (badgeKeywords.contains(earliestKeyword)) {
      spans.add(const TextSpan(text: '\n'));
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              earliestKeyword!,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                height: 1.2,
              ),
            ),
          ),
        ),
      );
      spans.add(const TextSpan(text: '\n'));
    } else {
      spans.add(
        TextSpan(
          text: earliestKeyword!,
          style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    remaining = remaining.substring(earliestIdx + earliestKeyword.length);
  }

  return spans;
}
