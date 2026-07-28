import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm_flutter/providers/theme_mode_provider.dart';

class FunctionCards extends StatefulWidget {
  const FunctionCards({super.key});

  @override
  State<FunctionCards> createState() => _FunctionCardsState();
}

class _FunctionCardsState extends State<FunctionCards> {
  final List<Map<String, dynamic>> _getCardsInfo = [
    {
      "icon": Icons.history,
      "iconColor": Color(0xFFD97706),
      "iconBackgroundColor": Color(0xFFFEF3C7),
      "title": "诊断记录",
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
    context.watch<ThemeModeController>(); // 深色模式切换时用于触发本页面重建
    return Column(
      children: List.generate(_getCardsInfo.length, (index) {
        final item = _getCardsInfo[index];
        return InkWell(
          onTap: () {
            if (item["title"] == "诊断记录" || item["title"] == "诊断历史") {
              Navigator.pushNamed(context, "/diagnosis_records");
              return;
            }
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
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: AppColors.ink),
                  ),
                  child: Icon(
                    item["icon"], 
                    color: AppColors.ink,
                    size: 20,
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
                          fontFamily: "serif",
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        item["subtitle"],
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Icon(
                    Icons.arrow_forward_rounded, 
                    size: 20, 
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
