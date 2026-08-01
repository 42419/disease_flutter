import 'package:farm_flutter/pageViews/main_view.dart';
import 'package:farm_flutter/pages/widgets/common/scaffold_with_bottom_nav.dart';
import 'package:flutter/material.dart';

/// 普通用户的主页面："首页"（图像诊断）+ "我的"。
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScaffoldWithBottomNav(homeTab: MainView());
  }
}
