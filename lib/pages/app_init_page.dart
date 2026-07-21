import 'package:dio/dio.dart';
import 'package:farm_flutter/config/config.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/response_util.dart';
import 'package:farm_flutter/providers/user_provider.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:farm_flutter/services/auth_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    try {
      final rawResponse = await HttpUtil.post(
        "/login",
        {
          "username": credentials.username,
          "pwd": credentials.password,
          "role": credentials.role,
        },
        headers: {"X-API-Token": Config.apiToken},
      );

      if (!mounted) return;

      final response = ResponseUtil.asMap(rawResponse);
      if (response != null && ResponseUtil.isLoginSuccess(response)) {
        final resolvedRole = ResponseUtil.resolveRole(response, credentials.role);
        context.read<UserProvider>().login(
          response['username']?.toString() ?? credentials.username,
          resolvedRole,
        );
        HttpUtil.init(baseUrl: Config.baseUrl);
        _goTo(resolvedRole == '1' ? "/admin_main" : "/main");
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
