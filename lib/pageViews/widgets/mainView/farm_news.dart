import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:farm_flutter/providers/theme_mode_provider.dart';

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
    context.watch<ThemeModeController>(); // 深色模式切换时用于触发本页面重建
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
                    backgroundColor: AppColors.ink,
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: index == 0 ? AppColors.hairline : Colors.transparent),
                    bottom: BorderSide(color: AppColors.hairline),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Image.network(
                        item["picture"], 
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item["title"],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "${item["time"]}   ·   ${item["watched"]}",
                            style: TextStyle(
                              fontFamily: "serif",
                              color: AppColors.muted,
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
