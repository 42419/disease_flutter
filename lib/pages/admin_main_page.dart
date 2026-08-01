import 'package:farm_flutter/pageViews/admin_map_view.dart';
import 'package:farm_flutter/pages/widgets/common/scaffold_with_bottom_nav.dart';
import 'package:flutter/material.dart';

/// 管理员的主页面："首页"（病害地图）+ "我的"。
class AdminMainPage extends StatelessWidget {
  const AdminMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScaffoldWithBottomNav(homeTab: AdminMapView());
  }
}
