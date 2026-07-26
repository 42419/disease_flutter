import 'package:farm_flutter/providers/user_provider.dart';
import 'package:farm_flutter/services/auth_storage.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
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

  // 弹出菜单动效相关（参考 HyperOS3 / iOS 弹出式按钮的"锚点展开"手法）：
  // 展开走物理弹簧曲线，收起走一段更快的普通缓动，控制器本身不设固定时长。
  OverlayEntry? _roleMenuOverlay;
  late AnimationController _menuAnimController;

  // 角色选项（顺序即弹出选择器中的顺序）
  static const List<String> _roleKeys = ["0", "1"];
  static const Map<String, String> _roleLabels = {
    "0": "农户",
    "1": "管理员",
  };
  final GlobalKey _roleFieldKey = GlobalKey();
  bool _isRoleMenuOpen = false;

  // 展开动效的物理弹簧参数：阻尼比 ζ = damping / (2·√(stiffness·mass)) ≈ 0.75，
  // 只留一丝回弹的"软着陆"感，不做夸张的弹跳（HyperOS3/iOS 系统菜单都是克制的
  // 微弹，不是橡皮糖那种大幅度弹簧）。
  static const SpringDescription _menuOpenSpring = SpringDescription(
    mass: 1,
    stiffness: 480,
    damping: 34,
  );
  // 收起统一走一小段快速缓动，不复用展开的弹簧曲线——系统菜单的收起动画
  // 几乎都是"唰"一下比展开快，不会反向播放一遍弹簧。
  static const Duration _menuCloseDuration = Duration(milliseconds: 140);

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    // 展开时用 animateWith(SpringSimulation) 驱动，不依赖这里的 duration；
    // 收起时会显式传 duration，这里给个兜底值即可。
    _menuAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
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

    // 登录请求 + 响应解析统一由 UserProvider.loginWithCredentials 完成
    // （与自动登录 app_init_page.dart 共用同一份实现，避免重复代码）。
    final result = await context.read<UserProvider>().loginWithCredentials(
      username: _usernameController.text,
      password: _passwordController.text,
      role: _selectedRole ?? '0',
    );

    if (!mounted) return;
    Navigator.pop(context);
    setState(() => _isLoggingIn = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("登录失败，${result.message}"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final resolvedRole = result.role!;
    final resolvedName = result.nickName!;

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
  }

  // 弹出菜单展开逻辑：动效参考 HyperOS3/Miuix 的 popupClipReveal（锚点 clip
  // 裁剪展开 + 物理弹簧）以及 iOS 弹出式/下拉式按钮的克制回弹，具体实现见
  // 下方 AnimatedBuilder 里的注释、_menuOpenSpring 常量、_RevealClipper。
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
    // 菜单是否要向上弹出（下方空间不够时），展开动画要跟着从对应的角展开，
    // 而不是永远固定右上角——不然从字段上方弹出时会显得方向拧巴。
    bool expandFromTop = true;
    if (menuTop + menuHeight > screenSize.height - 8) {
      menuTop = buttonPos.dy - menuHeight - 6; // 上方弹出
      expandFromTop = false;
    }

    setState(() => _isRoleMenuOpen = true);

    _roleMenuOverlay = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _menuAnimController,
          builder: (context, _) {
            // 弹簧仿真在回弹阶段会短暂越过 1.0 再落回来，这是有意保留的物理
            // 特性；但用来算透明度/裁剪范围时必须夹到 [0,1]，否则会触发
            // Opacity 断言或裁剪越界。
            final raw = _menuAnimController.value;
            final t = raw.clamp(0.0, 1.0);
            // 蒙层比菜单本体更快淡入完成（前 55% 区间），参考系统菜单"背景先
            // 暗下来、菜单紧跟着展开"的先后顺序。
            final overlayOpacity = (t / 0.55).clamp(0.0, 1.0);
            final menuOpacity = (t / 0.5).clamp(0.0, 1.0);
            // 整体只做一个非常轻的缩放回弹（0.97 ↔ 1.0 附近），幅度小到不会
            // 让文字看起来模糊变形，纯粹是给"落地"那一下加一点物理感；真正
            // 承担"从小到大展开"视觉效果的是下面的 clip 裁剪，而不是缩放。
            final settleScale = 0.97 + 0.03 * raw.clamp(0.0, 1.2);

            return Stack(
              children: [
                // 半透明蒙层（淡入）
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => _closeRoleMenu(field: field),
                    behavior: HitTestBehavior.translucent,
                    child: Opacity(
                      opacity: overlayOpacity,
                      child: Container(color: Colors.black.withValues(alpha: 0.16)),
                    ),
                  ),
                ),
                // 菜单主体：从触发字段的角上用 clip 裁剪"展开"，而不是整体缩放
                // 文字——参考 HyperOS3/Miuix 的 popupClipReveal 和 iOS 弹出式
                // 按钮从锚点长出菜单的手法。
                Positioned(
                  left: menuLeft,
                  top: menuTop,
                  child: Opacity(
                    opacity: menuOpacity,
                    child: Transform.scale(
                      alignment: expandFromTop
                          ? Alignment.topRight
                          : Alignment.bottomRight,
                      scale: settleScale,
                      child: ClipPath(
                        clipper: _RevealClipper(
                          progress: raw,
                          radius: 20,
                          fromTop: expandFromTop,
                        ),
                        child: SizedBox(
                          width: menuWidth,
                          child: Material(
                            color: Colors.white,
                            elevation: 16,
                            shadowColor: Colors.black.withValues(alpha: 0.22),
                            shape: const ContinuousRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int i = 0; i < _roleKeys.length; i++)
                                    _buildRoleMenuItem(
                                      _roleKeys[i],
                                      // 每一项在整体淡入的基础上再错开一点点，
                                      // 呼应 Miuix 级联列表逐项展开的观感，
                                      // 幅度很克制，避免变成"打字机"效果。
                                      itemProgress: ((t - i * 0.06) / 0.4).clamp(0.0, 1.0),
                                      onTap: () => _closeRoleMenu(
                                        field: field,
                                        result: _roleKeys[i],
                                      ),
                                    ),
                                ],
                              ),
                            ),
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
      },
    );

    Overlay.of(context).insert(_roleMenuOverlay!);
    // 用物理弹簧仿真驱动展开：不是固定时长的缓动曲线，而是真的按质量/刚度/
    // 阻尼算出来的运动轨迹，停止时机由弹簧自己收敛决定。
    _menuAnimController
      ..stop()
      ..value = 0
      ..animateWith(SpringSimulation(_menuOpenSpring, 0, 1, 0));
  }

  Future<void> _closeRoleMenu({
    required FormFieldState<String> field,
    String? result,
  }) async {
    // 收起统一走一小段快速缓动，不复用展开的弹簧——系统菜单收起基本都是
    // "唰"一下比展开快，不会把弹簧动画倒放一遍。
    await _menuAnimController.animateTo(
      0,
      duration: _menuCloseDuration,
      curve: Curves.easeIn,
    );
    _roleMenuOverlay?.remove();
    _roleMenuOverlay = null;
    if (mounted) setState(() => _isRoleMenuOpen = false);

    if (result != null && mounted) {
      setState(() => _selectedRole = result);
      field.didChange(result);
    }
  }

  Widget _buildRoleMenuItem(
    String key, {
    required double itemProgress,
    required VoidCallback onTap,
  }) {
    final bool selected = key == _selectedRole;
    return Opacity(
      opacity: itemProgress,
      child: Transform.translate(
        offset: Offset(0, (1 - itemProgress) * 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Material(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              ),
            ),
          ),
        ),
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
                                          AnimatedRotation(
                                            turns: _isRoleMenuOpen ? 0.5 : 0,
                                            duration: const Duration(milliseconds: 200),
                                            curve: Curves.easeOutCubic,
                                            child: Icon(
                                              Icons.unfold_more_rounded,
                                              color: AppColors.muted,
                                              size: 20,
                                            ),
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

/// 让菜单从触发字段的一角（右上角展开时用 topRight，向上弹出时用
/// bottomRight）"生长"出来的裁剪器：随 [progress] 从 0 到 1，裁剪矩形从锚点
/// 处的一个点逐渐扩大到整个菜单尺寸。
///
/// 和直接用 [ScaleTransition] 整体缩放菜单相比，这种写法始终按 1:1 尺寸布局、
/// 渲染文字，只是逐步"揭开"更多区域——不会出现缩放过程中文字被压扁、模糊的
/// 观感，这也是 HyperOS3/Miuix 的 `popupClipReveal` 和 iOS 系统菜单展开动画
/// 采用的思路。
class _RevealClipper extends CustomClipper<Path> {
  final double progress;
  final double radius;
  final bool fromTop;

  const _RevealClipper({
    required this.progress,
    required this.radius,
    required this.fromTop,
  });

  @override
  Path getClip(Size size) {
    // 弹簧仿真回弹阶段可能短暂越过 1.0，这里夹到合理范围，裁剪矩形最大也
    // 就是菜单自身尺寸，不会真的"溢出"到外面去。
    final t = progress.clamp(0.0, 1.0);
    final width = size.width * t;
    final height = size.height * t;
    final left = size.width - width; // 右边缘固定，向左生长

    final rect = fromTop
        ? Rect.fromLTWH(left, 0, width, height) // 从右上角展开
        : Rect.fromLTWH(left, size.height - height, width, height); // 从右下角展开

    return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  }

  @override
  bool shouldReclip(covariant _RevealClipper oldClipper) {
    return oldClipper.progress != progress ||
        oldClipper.fromTop != fromTop ||
        oldClipper.radius != radius;
  }
}
