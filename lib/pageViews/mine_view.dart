import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/global.dart';

class MineView extends StatefulWidget {
  const MineView({super.key});

  @override
  State<MineView> createState() => _MineViewState();
}

class _MineViewState extends State<MineView> {
  Widget _getStatItem(String value, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Padding(
        padding: EdgeInsets.all(33),
        child: ListView(
          children: [
            SizedBox(height: 100),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("跳转个人资料"),
                    duration: Duration(milliseconds: 500),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("跳转个人资料"),
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
                    child: Row(
                      children: [
                        // SizedBox(width: 36),
                        Text(
                          Global.user.nickName,
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 13),
                        Icon(
                          Icons.arrow_forward_ios_outlined,
                          size: 16,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: Global.user.userAvatarUrl.isNotEmpty == true
                        ? NetworkImage(Global.user.userAvatarUrl)
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: (Global.user.userAvatarUrl.isEmpty)
                        ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                        : null,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Container(
              height: 100,
              padding: EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(child: _getStatItem("28", "诊断次数")),
                  Container(width: 1, height: 30, color: AppColors.cardBorder),
                  Expanded(child: _getStatItem("12", "已保存方案")),
                  Container(width: 1, height: 30, color: AppColors.cardBorder),
                  Expanded(child: _getStatItem("3", "专家咨询")),
                ],
              ),
            ),
            SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.history_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text("诊断记录", style: TextStyle(fontSize: 16)),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("跳转诊断记录"),
                          duration: Duration(milliseconds: 500),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    "/login",
                    (context) => false,
                  );
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool("remember_me", false);
                  await prefs.remove("username");
                  await prefs.remove("password");
                  await prefs.remove("role");
                },
                child: Text("退出登录"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
