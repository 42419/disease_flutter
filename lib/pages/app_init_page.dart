import 'package:dio/dio.dart';
import 'package:farm_flutter/utils/api_config.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/global.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppInitPage extends StatefulWidget {
  const AppInitPage({super.key});

  @override
  State<AppInitPage> createState() => _AppInitPageState();
}

class _AppInitPageState extends State<AppInitPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    final username = prefs.getString('username') ?? '';
    final password = prefs.getString('password') ?? '';
    final role = prefs.getString('role') ?? '1';

    if (!mounted) return;

    if (!rememberMe || username.isEmpty || password.isEmpty) {
      _goTo('/login');
      return;
    }

    try {
      final response = await HttpUtil.post(
        "/login",
        {"username": username, "pwd": password, "role": role},
        headers: {"X-API-Token": ApiConfig.apiToken},
      );

      if (!mounted) return;

      if (response["msg"] == "success") {
        Global.user.nickName = response["username"] ?? username;
        Global.user.role = role;
        HttpUtil.init(baseUrl: ApiConfig.baseUrl);
        _goTo(role == "1" ? "/admin_main" : "/main");
      } else {
        _goTo('/login');
      }
    } on DioException catch (_) {
      if (!mounted) return;
      _goTo('/login');
    } catch (_) {
      if (!mounted) return;
      _goTo('/login');
    }
  }

  void _goTo(String route) {
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/img/logo.png', width: 120, height: 120),
            const SizedBox(height: 24),
            Text(
              '慧田良方',
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
