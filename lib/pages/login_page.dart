import 'package:dio/dio.dart';
import 'package:farm_flutter/config/config.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:farm_flutter/utils/global.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole = "0";
  final _formKey = GlobalKey<FormState>();
  bool _isSelected = false;
  bool _rememberMe = false;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? false;
      if (_rememberMe) {
        _usernameController.text = prefs.getString('username') ?? '';
        _passwordController.text = prefs.getString('password') ?? '';
        _selectedRole = prefs.getString('role') ?? '1';
        _isSelected = true;
      }
    });
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return "请输入用户名";
    }

    if (value.length < 3) {
      return "用户名至少 3 个字符";
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "请输入密码";
    }

    if (value.length < 6) {
      return "密码至少 6 位";
    }

    return null;
  }

  String? _validateRole(String? value) {
    if (value == null || value.isEmpty) {
      return "请选择角色";
    }
    return null;
  }

  void _login() async {
    if (_isLoggingIn) return;
    FocusScope.of(context).unfocus();

    if (!_isSelected) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("请勾选《用户协议》和《隐私政策》"),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoggingIn = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final response = await HttpUtil.post(
        "/login",
        {
          "username": _usernameController.text,
          "pwd": _passwordController.text,
          "role": _selectedRole,
        },
        headers: {"X-API-Token": Config.apiToken},
      );
      if (mounted) Navigator.pop(context);
      if (response["msg"] == "success") {
        Global.user.nickName = response["username"] ?? _usernameController.text;
        Global.user.role = _selectedRole ?? "1";
        HttpUtil.init(baseUrl: Config.baseUrl);

        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setBool('remember_me', true);
          await prefs.setString('username', _usernameController.text);
          await prefs.setString('password', _passwordController.text);
          await prefs.setString('role', _selectedRole ?? "1");
        } else {
          await prefs.setBool('remember_me', false);
          await prefs.remove('username');
          await prefs.remove('password');
          await prefs.remove('role');
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "登录成功, 欢迎 ${response["username"] ?? _usernameController.text}",
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(milliseconds: 500),
          ),
        );

        if (Global.user.role == "1") {
          Navigator.pushNamedAndRemoveUntil(
            context,
            "/admin_main",
            (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(context, "/main", (route) => false);
        }
      } else {
        if (!mounted) return;
        setState(() => _isLoggingIn = false);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("登录失败，${response["msg"]}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } on DioException catch (e) {
      debugPrint("DioException: ${e.type}, ${e.message}, ${e.error}");
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isLoggingIn = false);
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("网络连接失败，请检查网络和服务器"),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      debugPrint("登录异常: $e");
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isLoggingIn = false);
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("登录异常: $e"), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 56),

                      // Logo & Editorial Title
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          "assets/img/logo.png",
                          width: 80,
                          height: 80,
                        ),
                      ),
                      // const SizedBox(height: 24),
                      Text(
                        "Sign in to\ncontinue.",
                        style: TextStyle(
                          fontFamily: "serif",
                          fontWeight: FontWeight.w400,
                          fontSize: 48,
                          height: 1.1,
                          color: AppColors.ink,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "欢迎回到慧田良方",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.muted,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 64),

                      // Minimalist Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Username Input (Underline only)
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              validator: _validateUsername,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                              ),
                              decoration: _buildMinimalInputDecoration(
                                hintText: "用户名",
                                icon: Icons.person_outline,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Input
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              validator: _validatePassword,
                              onFieldSubmitted: (_) => _login(),
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                              ),
                              decoration: _buildMinimalInputDecoration(
                                hintText: "密码",
                                icon: Icons.lock_outline,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Role Selection
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              isExpanded: true,
                              validator: _validateRole,
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                              ),
                              dropdownColor: AppColors.canvas,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.muted,
                              ),
                              onChanged: (String? newValue) {
                                setState(() => _selectedRole = newValue);
                              },
                              items: const [
                                DropdownMenuItem(
                                    value: "0",
                                    child: Text("农户")
                                ),
                                DropdownMenuItem(
                                  value: "1",
                                  child: Text("管理员"),
                                )
                              ],
                              decoration: _buildMinimalInputDecoration(
                                hintText: "角色",
                                icon: Icons.switch_account_outlined,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Options
                            Row(
                              children: [
                                _buildCheckbox(
                                  _rememberMe,
                                  (v) => setState(() => _rememberMe = v!),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _rememberMe = !_rememberMe,
                                  ),
                                  child: Text(
                                    "保持登录状态",
                                    style: TextStyle(
                                      color: AppColors.body,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Agreement
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCheckbox(
                                  _isSelected,
                                  (v) => setState(() => _isSelected = v!),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _isSelected = !_isSelected,
                                        ),
                                        child: Text(
                                          "已阅读并同意",
                                          style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _showSnack('跳转《用户协议》'),
                                        child: Text(
                                          "《用户协议》",
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "和",
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _showSnack('跳转《隐私政策》'),
                                        child: Text(
                                          "《隐私政策》",
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 48),

                            // Login Button
                            SizedBox(
                              height: 56,
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoggingIn
                                    ? null
                                    : () {
                                        FocusScope.of(context).unfocus();
                                        _login();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.ink,
                                  foregroundColor: AppColors.canvas,
                                  disabledBackgroundColor: AppColors.hairline,
                                  disabledForegroundColor: AppColors.muted,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      0,
                                    ), // Sharp brutalist corner
                                  ),
                                ),
                                child: _isLoggingIn
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: AppColors.canvas,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "登 录",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                          letterSpacing: 4,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Bottom Action
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildTextButton(
                                  "忘记密码",
                                  () => _showSnack("忘记密码"),
                                ),
                                Container(
                                  height: 12,
                                  width: 1,
                                  color: AppColors.hairline,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                _buildTextButton(
                                  "注册账户",
                                  () => _showSnack("跳转注册"),
                                ),
                              ],
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 1000),
        backgroundColor: AppColors.ink,
      ),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool value, ValueChanged<bool?> onChanged) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.ink,
        checkColor: AppColors.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        // Sharp checkbox
        side: BorderSide(color: AppColors.muted.withOpacity(0.5), width: 1.5),
      ),
    );
  }

  InputDecoration _buildMinimalInputDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Icon(icon, color: AppColors.muted, size: 24),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      hintStyle: TextStyle(
        color: AppColors.muted.withOpacity(0.6),
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),
      filled: false,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.hairline, width: 1),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.hairline, width: 1),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.ink,
          width: 2,
        ), // Underline highlight in ink
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.error, width: 1),
      ),
    );
  }
}
