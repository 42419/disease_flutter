import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:farm_flutter/providers/theme_mode_provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeModeController>(); // 深色模式切换时用于触发本页面重建
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 150),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text("注册账号", style: TextStyle(fontSize: 35)),
            ),
            const SizedBox(height: 60),
            TextFormField(
              maxLines: 1,
              textInputAction: TextInputAction.next,
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: "请输入用户名",
                labelText: "用户名",
                prefixIcon: Icon(
                  Icons.account_circle_outlined,
                  color: AppColors.iconDefault,
                ),
                hintStyle: TextStyle(color: AppColors.textTertiary),
                labelStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.inputBackground,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.inputBorder,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.inputBorderFocused,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.error, width: 1),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.error, width: 2),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              maxLines: 1,
              obscureText: true,
              controller: _passwordController,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: "请输入密码",
                labelText: "密码",
                prefixIcon: Icon(
                  Icons.password_rounded,
                  color: AppColors.iconDefault,
                ),
                hintStyle: TextStyle(color: AppColors.textTertiary),
                labelStyle: TextStyle(
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.inputBackground,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.inputBorder,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.inputBorderFocused,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.error,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.error,
                    width: 2,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
