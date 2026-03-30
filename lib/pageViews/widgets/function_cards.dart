import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';

class FunctionCards extends StatefulWidget {
  const FunctionCards({super.key});

  @override
  State<FunctionCards> createState() => _FunctionCardsState();
}

class _FunctionCardsState extends State<FunctionCards> {
  List<Map<String, dynamic>> _getCardsInfo = [
    {
      "icon": Icons.history,
      "iconColor": Color(0xFFD97706),
      "iconBackgroundColor": Color(0xFFFEF3C7),
      "title": "诊断历史",
      "subtitle": "查看以往的病理诊断记录与治疗方案",
    },
    {
      "icon": Icons.menu_book_sharp,
      "iconColor": Color(0xFF2563EB),
      "iconBackgroundColor": Color(0xFFDBEAFE),
      "title": "病害百科",
      "subtitle": "查询各类作物病害的症状、病因与防治方法",
    },
    {
      "icon": Icons.person,
      "iconColor": Color(0xFF059669),
      "iconBackgroundColor": Color(0xFFD1FAE5),
      "title": "专家咨询",
      "subtitle": "在线咨询农业专家，获取专业诊断与建议",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_getCardsInfo.length, (index) {
        final item = _getCardsInfo[index];
        return Column(
          children: [
            Card(
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
                title: Column(
                  children: [
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: item["iconBackgroundColor"],
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(item["icon"], color: item["iconColor"]),
                        ),
                        SizedBox(width: 10),
                        Text(
                          item["title"],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(item["subtitle"]),
                ),
                // leading: Icon(Icons.history),
                trailing: Icon(Icons.arrow_forward_ios_outlined, size: 18),
              ),
            ),
            SizedBox(height: 5),
          ],
        );
      }),
    );
  }
}
