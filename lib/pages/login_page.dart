import 'package:farm_flutter/utils/http_util.dart';
import 'package:farm_flutter/utils/global.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSelected = false;

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

  void _login() async {
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

    showDialog(
      context: context,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      //TODO: 后续需要修改response内容
      final response = await HttpUtil.post(
        "http://192.168.0.178:8080/api/login",
        {
          "username": _usernameController.text,
          "password": _passwordController.text,
        },
      );
      if (mounted) Navigator.pop(context);
      if (response["success"] == true) {
        //TODO: 后续需要修改“data["nickname"]”
        Global.currentUserNickname = response["nickname"];
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("登录成功, 欢迎 ${response['nickname']}"),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              //TODO: 后续需要修改content内容
              content: Text(response['message']),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("网络连接失败，请检查网络和服务器"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                SizedBox(height: 40),
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
                      TextFormField(
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
                          hintStyle: TextStyle(color: AppColors.textTertiary),
                          labelStyle: TextStyle(color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.inputBorder,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.inputBorderFocused,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.error, width: 1),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.error, width: 2),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                            ),
                          ),
                        ),
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
                          labelStyle: TextStyle(color: AppColors.textSecondary),
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
                            borderSide: BorderSide(color: AppColors.error, width: 1),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.error, width: 2),
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
                            value: _isSelected,
                            onChanged: (newValue) {
                              setState(() {
                                _isSelected = newValue ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                            checkColor: AppColors.white,
                            fillColor: WidgetStateProperty.resolveWith(
                              (states) {
                                if (states.contains(WidgetState.selected)) {
                                  return AppColors.primary;
                                }
                                return AppColors.inputBorder;
                              },
                            ),
                          ),
                          Text(
                            "勾选即代表您已同意",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("跳转《用户协议》"),
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
                              "《用户协议》",
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                          Text(
                            "和",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("跳转《隐私政策》"),
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
                          onPressed: _login,
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
                          color: AppColors.primaryLight,
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
                          color: AppColors.info,
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
    );
  }
}
