import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/providers/user_provider.dart';
import 'package:farm_flutter/services/auth_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm_flutter/providers/theme_mode_provider.dart';

class AppInitPage extends StatefulWidget {
  const AppInitPage({super.key});

  @override
  State<AppInitPage> createState() => _AppInitPageState();
}

class _AppInitPageState extends State<AppInitPage> {
  final AuthStorage _authStorage = const AuthStorage();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final credentials = await _authStorage.readCredentials();

    if (!mounted) return;

    if (!credentials.canAutoLogin) {
      _goTo('/login');
      return;
    }

    // 与手动登录（login_page.dart）共用同一份请求/解析逻辑，见
    // UserProvider.loginWithCredentials。
    final result = await context.read<UserProvider>().loginWithCredentials(
      username: credentials.username,
      password: credentials.password,
      role: credentials.role,
    );

    if (!mounted) return;

    if (result.success) {
      _goTo(result.role == '1' ? "/admin_main" : "/main");
    } else {
      _goTo('/login');
    }
  }

  void _goTo(String route) {
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeModeController>(); // 深色模式切换时用于触发本页面重建
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/img/logo.png', width: 120, height: 120),
            const SizedBox(height: 24),
            Text(
              '禾康智诊',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
                color: AppColors.ink,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
