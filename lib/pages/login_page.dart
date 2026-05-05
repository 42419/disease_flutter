import 'package:dio/dio.dart';
import 'package:farm_flutter/utils/api_config.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:farm_flutter/utils/global.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole = "1";
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

    if (_rememberMe &&
        _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).unfocus();
        _login();
      });
    }
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
        headers: {"X-API-Token": ApiConfig.apiToken},
      );
      print("LOGIN_TEST: $response");
      if (mounted) Navigator.pop(context);
      if (response["msg"] == "success") {
        Global.user.nickName = response["username"] ?? _usernameController.text;
        Global.user.role = _selectedRole ?? "1";
        HttpUtil.init(baseUrl: ApiConfig.baseUrl);

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
          Navigator.pushNamedAndRemoveUntil(context, "/admin_main", (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, "/main", (route) => false);
        }
      } else {
        if (!mounted) return;
        setState(() => _isLoggingIn = false);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("登录异常: $e"), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, top: 150),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/img/logo.png", width: 110),
                  SizedBox(height: 20),
                  Text(
                    "慧田良方",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 11,
                              child: TextFormField(
                                maxLines: 1,
                                textInputAction: TextInputAction.next,
                                validator: _validateUsername,
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  hintText: "请输入用户名",
                                  labelText: "用户名",
                                  prefixIcon: Icon(
                                    Icons.account_circle_outlined,
                                    color: AppColors.iconDefault,
                                  ),
                                  hintStyle: TextStyle(
                                    color: AppColors.textTertiary,
                                  ),
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
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.inputBorderFocused,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              flex: 9,
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: _selectedRole,
                                validator: _validateRole,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedRole = newValue;
                                  });
                                },
                                items: [
                                  DropdownMenuItem(
                                    value: "1",
                                    child: Text("管理员"),
                                  ),
                                  DropdownMenuItem(
                                    value: "0",
                                    child: Text("农户"),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  labelText: "角色",
                                  prefixIcon: Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: AppColors.iconDefault,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.inputBackground,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 16,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.inputBorder,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.inputBorderFocused,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.error,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          maxLines: 1,
                          obscureText: true,
                          validator: _validatePassword,
                          controller: _passwordController,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
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
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.inputBorderFocused,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.error,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.error,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              visualDensity: VisualDensity(
                                horizontal: -4,
                                vertical: -3,
                              ),
                              onChanged: (newValue) {
                                setState(() {
                                  _rememberMe = newValue ?? false;
                                });
                              },
                              activeColor: AppColors.primary,
                              checkColor: AppColors.white,
                              fillColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppColors.primary;
                                }
                                return AppColors.inputBorder;
                              }),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rememberMe = !_rememberMe;
                                });
                              },
                              child: Text(
                                "自动登录",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _isSelected,
                              visualDensity: VisualDensity(
                                horizontal: -4,
                                vertical: -3,
                              ),
                              onChanged: (newValue) {
                                setState(() {
                                  _isSelected = newValue ?? false;
                                });
                              },
                              activeColor: AppColors.primary,
                              checkColor: AppColors.white,
                              fillColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppColors.primary;
                                }
                                return AppColors.inputBorder;
                              }),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSelected = !_isSelected;
                                });
                              },
                              child: Text(
                                "勾选即代表您已同意",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("跳转《用户协议》"),
                                    duration: Duration(milliseconds: 500),
                                    backgroundColor: AppColors.info,
                                  ),
                                );
                              },
                              child: Text(
                                "《用户协议》",
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                            Text(
                              "和",
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("跳转《隐私政策》"),
                                    duration: Duration(milliseconds: 500),
                                    backgroundColor: AppColors.info,
                                  ),
                                );
                              },
                              child: Text(
                                "《隐私政策》",
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        SizedBox(
                          height: 60,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoggingIn
                                ? null
                                : () {
                                    _login();
                                    FocusScope.of(context).unfocus();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.buttonText,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "登录",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          endIndent: 10,
                          thickness: 1,
                          color: AppColors.divider,
                        ),
                      ),
                      Text(
                        "其他登录方式",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Expanded(
                        child: Divider(
                          indent: 10,
                          thickness: 1,
                          color: AppColors.divider,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("微信登录"),
                              duration: Duration(milliseconds: 500),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: AppColors.primaryLightest,
                          radius: 28,
                          child: Icon(
                            Icons.wechat_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                      SizedBox(width: 70),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("手机号登录"),
                              duration: Duration(milliseconds: 500),
                              backgroundColor: AppColors.info,
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: AppColors.primaryLightest,
                          radius: 28,
                          child: Icon(
                            Icons.phone_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),
                  Container(
                    margin: EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "还没有账号? ",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("跳转注册"),
                                duration: Duration(milliseconds: 500),
                                backgroundColor: AppColors.info,
                              ),
                            );
                          },
                          style: ButtonStyle(
                            overlayColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                            padding: WidgetStateProperty.all(EdgeInsets.zero),
                            minimumSize: WidgetStateProperty.all(Size.zero),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            "立即注册",
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
