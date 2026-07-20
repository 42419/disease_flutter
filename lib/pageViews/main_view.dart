import 'package:farm_flutter/pageViews/widgets/mainView/farm_news.dart';
import 'package:farm_flutter/pageViews/widgets/mainView/function_cards.dart';
import 'package:farm_flutter/pageViews/widgets/mainView/upload_widget.dart';
import 'package:farm_flutter/providers/user_provider.dart';
import 'package:farm_flutter/providers/upload_provider.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>();
    final upload = context.watch<UploadProvider>();
    final hasImageSelected = upload.selectedImage != null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '病理分析',
              style: TextStyle(
                fontFamily: "serif",
                fontSize: 32,
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                user.nickName,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        titleSpacing: 32,
        centerTitle: false,
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.hairline, height: 1.0),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. 图像诊断版块
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              border: Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "图像诊断",
                  style: TextStyle(
                    fontFamily: "serif",
                    fontSize: 22,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "上传作物叶片细节，获取准确的病理分析及防治建议。",
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 24),

                UploadWidget(),
              ],
            ),
          ),

          if (!hasImageSelected) ...[
            // 2. 更多工具版块
            Container(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                border: Border(
                  bottom: BorderSide(color: AppColors.ink, width: 1.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "更多工具",
                    style: TextStyle(
                      fontFamily: "serif",
                      fontSize: 22,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "涵盖历史档案与专家知识库，全方位协助作物管理。",
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 24),
                  FunctionCards(),
                ],
              ),
            ),

            // 3. 农事资讯版块
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(color: AppColors.canvas),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "农事资讯",
                        style: TextStyle(
                          fontFamily: "serif",
                          fontSize: 22,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("跳转更多资讯"),
                              duration: Duration(milliseconds: 500),
                              backgroundColor: AppColors.ink,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          overlayColor: Colors.black
                        ),
                        child: Row(
                          children: [
                            Text(
                              "查看更多资讯",
                              style: TextStyle(
                                fontFamily: "serif",
                                color: AppColors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_ios_outlined,
                              color: AppColors.ink,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "掌握最新的时令农事与管理经验指引。",
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 24),
                  FarmNews(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
