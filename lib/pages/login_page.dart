import 'package:dio/dio.dart';
import 'package:farm_flutter/config/config.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:farm_flutter/utils/response_util.dart';
import 'package:farm_flutter/providers/user_provider.dart';
import 'package:farm_flutter/services/auth_storage.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedRole = "0";
  final _formKey = GlobalKey<FormState>();
  bool _isSelected = false;
  bool _rememberMe = false;
  bool _isLoggingIn = false;
  final AuthStorage _authStorage = const AuthStorage();

  // 弹性弹出动效相关
  OverlayEntry? _roleMenuOverlay;
  late AnimationController _menuAnimController;
  late Animation<double> _menuScaleAnim;
  late Animation<double> _menuFadeAnim;
  late Animation<double> _overlayFadeAnim;

  // 角色选项（顺序即弹出选择器中的顺序）
  static const List<String> _roleKeys = ["0", "1"];
  static const Map<String, String> _roleLabels = {
    "0": "农户",
    "1": "管理员",
  };
  final GlobalKey _roleFieldKey = GlobalKey();
  bool _isRoleMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    // 初始化弹性动画：更快更脆
    _menuAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    // 弹簧缩放：快速弹出，轻微微弹
    _menuScaleAnim = CurvedAnimation(
      parent: _menuAnimController,
      curve: Curves.easeOutCubic,
    );
    // 菜单淡入（前半段就完成）
    _menuFadeAnim = CurvedAnimation(
      parent: _menuAnimController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    // 蒙层淡入（更早完成）
    _overlayFadeAnim = CurvedAnimation(
      parent: _menuAnimController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
  }

  Future<void> _loadSavedData() async {
    final credentials = await _authStorage.readCredentials();
    if (!mounted) return;
    setState(() {
      _rememberMe = credentials.rememberMe;
      if (_rememberMe) {
        _usernameController.text = credentials.username;
        _passwordController.text = credentials.password;
        _selectedRole = credentials.role;
        _isSelected = true;
      }
    });
  }

  @override
  void dispose() {
    _menuAnimController.dispose();
    _roleMenuOverlay?.remove();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
      final rawResponse = await HttpUtil.post(
        "/login",
        {
          "username": _usernameController.text,
          "pwd": _passwordController.text,
          "role": _selectedRole,
        },
        headers: {"X-API-Token": Config.apiToken},
      );
      if (mounted) Navigator.pop(context);

      final response = ResponseUtil.asMap(rawResponse);
      if (response == null || !ResponseUtil.isLoginSuccess(response)) {
        if (!mounted) return;
        setState(() => _isLoggingIn = false);
        final msg = response?['msg']?.toString() ?? '响应格式异常';
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("登录失败，$msg"),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // 优先使用服务端返回的角色，避免客户端自选绕过权限
      final resolvedRole = ResponseUtil.resolveRole(response, _selectedRole);
      final resolvedName = response['username']?.toString() ?? _usernameController.text;

      if (!mounted) return;
      context.read<UserProvider>().login(resolvedName, resolvedRole);
      HttpUtil.init(baseUrl: Config.baseUrl);

      await _authStorage.saveCredentials(
        rememberMe: _rememberMe,
        username: _usernameController.text,
        password: _passwordController.text,
        role: resolvedRole,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("登录成功, 欢迎 $resolvedName"),
          backgroundColor: AppColors.success,
          duration: const Duration(milliseconds: 500),
        ),
      );

      final isAdmin = resolvedRole == '1';
      Navigator.pushNamedAndRemoveUntil(
        context,
        isAdmin ? "/admin_main" : "/main",
            (route) => false,
      );
    } on DioException catch (e) {
      debugPrint("DioException: ${e.type}, ${e.message}, ${e.error}");
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => _isLoggingIn = false);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("网络连接失败，请检查网络和服务器"),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      debugPrint("登录异常: $e");
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => _isLoggingIn = false);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("登录异常: $e"), backgroundColor: AppColors.error),
      );
    }
  }

  // 弹性丝滑弹出菜单（参考小米笔记的「更多」动效）
  Future<void> _showRoleMenu(FormFieldState<String> field) async {
    FocusScope.of(context).unfocus();
    // 如果已有菜单在显示，先关闭
    if (_roleMenuOverlay != null) {
      await _closeRoleMenu(field: field);
      return;
    }

    final RenderBox? button =
    _roleFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (button == null) return;

    final Offset buttonPos = button.localToGlobal(Offset.zero);
    final Size buttonSize = button.size;
    final screenSize = MediaQuery.of(context).size;

    // 菜单宽度
    const double menuWidth = 200;
    const double menuItemHeight = 64;
    final double menuHeight = menuItemHeight * _roleKeys.length + 24;

    // 菜单右边缘对齐字段右边缘
    double menuLeft = buttonPos.dx + buttonSize.width - menuWidth;
    // 菜单顶部在字段下方
    double menuTop = buttonPos.dy + buttonSize.height + 6;
    // 边界修正
    if (menuLeft < 8) menuLeft = 8;
    if (menuLeft + menuWidth > screenSize.width - 8) {
      menuLeft = screenSize.width - menuWidth - 8;
    }
    if (menuTop + menuHeight > screenSize.height - 8) {
      menuTop = buttonPos.dy - menuHeight - 6; // 上方弹出
    }

    setState(() => _isRoleMenuOpen = true);

    _roleMenuOverlay = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // 半透明蒙层（淡入）
            FadeTransition(
              opacity: _overlayFadeAnim,
              child: GestureDetector(
                onTap: () => _closeRoleMenu(field: field),
                behavior: HitTestBehavior.translucent,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.15),
                  width: screenSize.width,
                  height: screenSize.height,
                ),
              ),
            ),
            // 菜单主体（缩放 + 淡入，从右上角弹出）
            Positioned(
              left: menuLeft,
              top: menuTop,
              child: FadeTransition(
                opacity: _menuFadeAnim,
                child: ScaleTransition(
                  alignment: Alignment.topRight, // 从右上角展开
                  scale: _menuScaleAnim,
                  child: Material(
                    color: Colors.white,
                    elevation: 12,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: menuWidth,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < _roleKeys.length; i++)
                            InkWell(
                              onTap: () => _closeRoleMenu(
                                field: field,
                                result: _roleKeys[i],
                              ),
                              child: _buildRoleMenuItem(
                                _roleKeys[i],
                                isLast: i == _roleKeys.length - 1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_roleMenuOverlay!);
    // 正向播放动画
    _menuAnimController.forward(from: 0);
  }

  Future<void> _closeRoleMenu({
    required FormFieldState<String> field,
    String? result,
  }) async {
    // 反向播放关闭动画
    await _menuAnimController.reverse();
    _roleMenuOverlay?.remove();
    _roleMenuOverlay = null;
    if (mounted) setState(() => _isRoleMenuOpen = false);

    if (result != null && mounted) {
      setState(() => _selectedRole = result);
      field.didChange(result);
    }
  }

  Widget _buildRoleMenuItem(String key, {required bool isLast}) {
    final bool selected = key == _selectedRole;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: isLast
          ? null
          : BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _roleLabels[key]!,
            style: TextStyle(
              fontSize: 16,
              color: selected ? AppColors.primary : AppColors.ink,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (selected)
            Icon(Icons.check_rounded, color: AppColors.primary, size: 20),
        ],
      ),
    );
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
                      const SizedBox(height: 44),

                      // Logo
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(
                          "assets/img/logo.png",
                          width: 84,
                          height: 84,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 品牌名
                      Text(
                        "禾康智诊",
                        style: TextStyle(
                          fontFamily: "serif",
                          fontWeight: FontWeight.w600,
                          fontSize: 36,
                          height: 1.1,
                          color: AppColors.ink,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 推广语
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 2,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "让东北黑土地遇见智慧",
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 62),

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

                            // Role Selection（贴合字段弹出的选择卡片）
                            FormField<String>(
                              initialValue: _selectedRole,
                              validator: _validateRole,
                              builder: (field) {
                                return InkWell(
                                  key: _roleFieldKey,
                                  borderRadius: BorderRadius.circular(4),
                                  onTap: () => _showRoleMenu(field),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    color: _isRoleMenuOpen
                                        ? AppColors.hairline.withValues(alpha: 0.25)
                                        : Colors.transparent,
                                    child: InputDecorator(
                                      decoration: _buildMinimalInputDecoration(
                                        hintText: "角色",
                                        icon: Icons.switch_account_outlined,
                                      ).copyWith(
                                        errorText: field.errorText,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _roleLabels[_selectedRole] ?? "请选择角色",
                                              style: TextStyle(
                                                color: _selectedRole == null
                                                    ? AppColors.muted.withValues(alpha: 0.6)
                                                    : AppColors.ink,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.unfold_more_rounded,
                                            color: AppColors.muted,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
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
        side: BorderSide(
          color: AppColors.muted.withValues(alpha: 0.5),
          width: 1.5,
        ),
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
        color: AppColors.muted.withValues(alpha: 0.6),
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
