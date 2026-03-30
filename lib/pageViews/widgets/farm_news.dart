import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class FarmNews extends StatefulWidget {
  const FarmNews({super.key});

  @override
  State<FarmNews> createState() => _FarmNewsState();
}

class _FarmNewsState extends State<FarmNews> {
  List<Map<String, dynamic>> _getNews = [
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
        Row(
          children: [
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "农技资讯",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("跳转更多资讯"),
                    duration: Duration(milliseconds: 500),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                padding: WidgetStateProperty.all(EdgeInsets.zero),
                minimumSize: WidgetStateProperty.all(Size.zero),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text("查看更多", style: TextStyle(color: AppColors.primary)),
            ),
            SizedBox(width: 10),
          ],
        ),
        SizedBox(height: 15),
        Column(
          children: List.generate(_getNews.length, (index) {
            final item = _getNews[index];
            return Card(
              color: AppColors.cardBackground,
              child: ListTile(
                onTap: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("跳转 ${item["title"]}"),
                      duration: Duration(milliseconds: 500),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(item["picture"], fit: BoxFit.contain),
                ),
                title: Column(
                  children: [
                    Text(
                      item["title"],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                  ],
                ),
                subtitle: Text("${item["time"]} · ${item["watched"]}"),
              ),
            );
          }),
        ),
      ],
    );
  }
}
