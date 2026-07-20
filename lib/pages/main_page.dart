import 'package:farm_flutter/pageViews/main_view.dart';
import 'package:farm_flutter/pageViews/mine_view.dart';
import 'package:farm_flutter/providers/diagnosis_records_provider.dart';
import 'package:farm_flutter/providers/main_navigation_provider.dart';
import 'package:farm_flutter/providers/user_provider.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
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
        children: const [MainView(), MineView()],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: AppColors.white,
            elevation: 0,
            indicatorColor: AppColors.primaryLightest,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  fontFamily: "serif",
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                );
              }
              return TextStyle(
                fontFamily: "serif",
                color: AppColors.bottomNavUnselected,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(color: AppColors.primary, size: 22);
              }
              return IconThemeData(
                color: AppColors.bottomNavUnselected,
                size: 22,
              );
            }),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navProvider.currentIndex,
          onDestinationSelected: (index) {
            _controller.jumpToPage(index);
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: "首页",
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: "我的",
            ),
          ],
        ),
      ),
    );
  }
}
