import 'package:farm_flutter/utils/app_theme.dart';
import 'package:farm_flutter/utils/app_spacing.dart';
import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

class FarmNews extends StatefulWidget {
  const FarmNews({super.key});

  @override
  State<FarmNews> createState() => _FarmNewsState();
}

class _FarmNewsState extends State<FarmNews> {
  final List<Map<String, dynamic>> _getNews = [
    {
      "picture": "https://picsum.photos/400/200?random=1",
      "title": "夏季蔬菜病虫害防治要点与管理技巧",
      "time": "2026-03-24",
      "watched": "1.2k 阅读",
    },
    {
      "picture": "https://picsum.photos/400/200?random=2",
      "title": "有机肥使用指南：科学施肥提高作物品质",
      "time": "2026-03-23",
      "watched": "982 阅读",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: List.generate(_getNews.length, (index) {
            final item = _getNews[index];
            return InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("跳转 ${item["title"]}"),
                    duration: Duration(milliseconds: 500),
                    backgroundColor: context.colors.ink,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: index == 0
                          ? context.colors.hairline
                          : Colors.transparent,
                    ),
                    bottom: BorderSide(color: context.colors.hairline),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        border: Border.all(color: context.colors.hairline),
                        color: context.colors.surfaceSoft,
                      ),
                      child: Image.network(
                        item["picture"],
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.colors.muted,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.image_not_supported_outlined,
                            color: context.colors.mutedSoft,
                            size: 22,
                          );
                        },
                      ),
                    ),
                    SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["title"],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.colors.ink,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: AppSpacing.md),
                          Text(
                            "${item["time"]}   ·   ${item["watched"]}",
                            style: TextStyle(
                              fontFamily: kAppFontFamily,
                              color: context.colors.muted,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
