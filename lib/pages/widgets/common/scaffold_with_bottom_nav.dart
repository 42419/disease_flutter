import 'package:farm_flutter/pageViews/mine_view.dart';
import 'package:farm_flutter/providers/diagnosis_records_provider.dart';
import 'package:farm_flutter/providers/main_navigation_provider.dart';
import 'package:farm_flutter/providers/user_provider.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "首页 + 我的" 两个底部 Tab 的通用外壳。
///
/// 普通用户（[MainPage](../../main_page.dart)）和管理员
/// （[AdminMainPage](../../admin_main_page.dart)）除了"首页" Tab 的内容
/// （`MainView` / `AdminMapView`）不同之外，PageController 懒加载、
/// 诊断记录轮询的生命周期管理（前后台切换自动 start/stop）、底部导航栏
/// 样式这些结构完全一样，因此抽成本组件复用，避免两份几乎相同的代码，
/// 修 bug 或调整导航栏样式时也只需要改一处。
class ScaffoldWithBottomNav extends StatefulWidget {
  /// "首页" Tab 的内容；"我的" Tab 固定为 [MineView]。
  final Widget homeTab;

  const ScaffoldWithBottomNav({super.key, required this.homeTab});

  @override
  State<ScaffoldWithBottomNav> createState() => _ScaffoldWithBottomNavState();
}

class _ScaffoldWithBottomNavState extends State<ScaffoldWithBottomNav>
    with WidgetsBindingObserver {
  PageController? _pageController;

  PageController get _controller {
    return _pageController ??= PageController(
      initialPage: context.read<MainNavigationProvider>().currentIndex,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<DiagnosisRecordsProvider>().stopTimer();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<DiagnosisRecordsProvider>();
    if (state == AppLifecycleState.resumed) {
      provider.refreshIfStale();
      final user = context.read<UserProvider>();
      provider.startTimer(role: user.role, nickName: user.nickName);
    } else if (state == AppLifecycleState.paused) {
      provider.stopTimer();
    }
  }

  void _startPolling() {
    final user = context.read<UserProvider>();
    final provider = context.read<DiagnosisRecordsProvider>();
    // 立即拉一次数据，不要只是启动定时器。PageView 不会预先构建"我的"
    // 这个还没被看到的 Tab，MineView.initState 里那次拉取要等用户真的
    // 划到"我的"才会触发；定时器本身也不会立即执行第一次（Timer.periodic
    // 要等一个完整的轮询间隔才会跑第一次回调）。这就导致管理员登录后如果
    // 先停留在"首页"（地图），会一直没有数据，直到轮询周期到了或者手动
    // 去"我的"页面才刷新——这里主动拉一次，保证不管先停在哪个 Tab 数据
    // 都能尽快到位。
    if (provider.records.isEmpty && provider.isLoading) {
      provider.fetchRecords(role: user.role, nickName: user.nickName);
    }
    provider.startTimer(role: user.role, nickName: user.nickName);
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<MainNavigationProvider>();

    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _controller,
        onPageChanged: (index) {
          context.read<MainNavigationProvider>().setCurrentIndex(index);
        },
        children: [widget.homeTab, const MineView()],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: context.colors.canvas,
            elevation: 0,
            indicatorColor: context.colors.surfaceSoft,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  fontFamily: kAppFontFamily,
                  color: context.colors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                );
              }
              return TextStyle(
                fontFamily: kAppFontFamily,
                color: context.colors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(color: context.colors.primary, size: 22);
              }
              return IconThemeData(color: context.colors.muted, size: 22);
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navProvider.currentIndex,
          onDestinationSelected: (index) {
            _controller.jumpToPage(index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '首页',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
