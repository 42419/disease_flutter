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

  // 弹出菜单动效相关：直接照搬 compose-miuix-ui/miuix 仓库里 ListPopup 的真实
  // 实现（miuix-ui/.../basic/ListPopup.kt 的 ListPopupDefaults +
  // miuix-ui/.../layout/ListPopupLayout.kt 的 LaunchedEffect），不是自己拍脑袋
  // 调的参数。三条轨道各自独立播放，语义上对应源码里的三个 Animatable：
  //   fraction —— 驱动缩放 + 纵向 clip 揭示，物理弹簧
  //   alpha    —— 菜单内容整体透明度，200ms/150ms 缓动
  //   dim      —— 背景蒙层透明度，300ms/150ms 缓动
  OverlayEntry? _roleMenuOverlay;
  late AnimationController _fractionCtrl;
  late AnimationController _alphaCtrl;
  late AnimationController _dimCtrl;

  // 角色选项（顺序即弹出选择器中的顺序）
  static const List<String> _roleKeys = ["0", "1"];
  static const Map<String, String> _roleLabels = {
    "0": "农户",
    "1": "管理员",
  };
  final GlobalKey _roleFieldKey = GlobalKey();
  bool _isRoleMenuOpen = false;

  // 对应源码 ListPopupDefaults.FractionAnimationSpec =
  // spring(dampingRatio = 0.82f, stiffness = 362.5f)。
  // Flutter 的 SpringDescription 用 (mass, stiffness, damping) 描述物理弹簧，
  // 换算关系：damping = dampingRatio · 2 · √(stiffness · mass)
  //          = 0.82 · 2 · √362.5 ≈ 31.22
  static const SpringDescription _fractionSpring = SpringDescription(
    mass: 1,
    stiffness: 362.5,
    damping: 31.22,
  );
  // 对应源码 AlphaEnterAnimationSpec / AlphaExitAnimationSpec：
  // tween(200) / tween(150)，Compose 里 tween 不传 easing 时默认就是
  // FastOutSlowInEasing——和 Flutter 的 Curves.fastOutSlowIn 是同一条
  // 三次贝塞尔曲线 (0.4, 0.0, 0.2, 1.0)，不是近似，是完全一致。
  static const Duration _alphaEnterDuration = Duration(milliseconds: 200);
  static const Duration _alphaExitDuration = Duration(milliseconds: 150);
  // 对应源码 DimEnterAnimationSpec / DimExitAnimationSpec：
  // tween(300, SinOutEasing) / tween(150, SinOutEasing)。
  // SinOutEasing 的定义就是 sin(fraction·π/2)，和 Flutter 内置的
  // Curves.easeOutSine 逐字节对得上，同样不是近似。
  static const Duration _dimEnterDuration = Duration(milliseconds: 300);
  static const Duration _dimExitDuration = Duration(milliseconds: 150);

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _fractionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320), // animateWith 不看这个值
    );
    _alphaCtrl = AnimationController(vsync: this, duration: _alphaEnterDuration);
    _dimCtrl = AnimationController(vsync: this, duration: _dimEnterDuration);
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
    _fractionCtrl.dispose();
    _alphaCtrl.dispose();
    _dimCtrl.dispose();
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

  // 弹出菜单展开逻辑：直接照搬 compose-miuix-ui/miuix 的 ListPopup 真实实现，
  // 而不是自己设计的近似效果。具体对照关系见下面各处注释。
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
    // 菜单是否要向上弹出（下方空间不够时）。对应源码 PopupLayoutPosition 里
    // showBelow / showAbove 两种情形，clip 揭示的方向要跟着切换，不然从字段
    // 上方弹出时会显得方向拧巴。
    bool expandFromTop = true; // true ≈ 源码的 showBelow，false ≈ showAbove
    if (menuTop + menuHeight > screenSize.height - 8) {
      menuTop = buttonPos.dy - menuHeight - 6; // 上方弹出
      expandFromTop = false;
    }

    setState(() => _isRoleMenuOpen = true);

    _roleMenuOverlay = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: Listenable.merge([_fractionCtrl, _alphaCtrl, _dimCtrl]),
          builder: (context, _) {
            // fraction 是弹簧仿真的原始值，回弹阶段会短暂越过 1.0——这是源码
            // 里就有意保留的物理特性（源码注释：coerceIn(0f, 1f) 只在算 clip
            // 时夹，缩放的 fraction 不夹），所以这里也只在算 clip 时夹到
            // [0,1]，缩放继续用未夹住的原始值，弹跳感才出得来。
            final fraction = _fractionCtrl.value;
            final clipFraction = fraction.clamp(0.0, 1.0);
            // 对应源码 ListPopupContent 里的
            // `val scale = 0.15f + 0.85f * fraction`。
            final scale = 0.15 + 0.85 * fraction;
            final alpha = _alphaCtrl.value.clamp(0.0, 1.0);
            final dimAlpha = _dimCtrl.value.clamp(0.0, 1.0);

            return Stack(
              children: [
                // 背景蒙层：对应 dimProgress，300ms 进 / 150ms 出，SinOutEasing。
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => _closeRoleMenu(field: field),
                    behavior: HitTestBehavior.translucent,
                    child: Opacity(
                      opacity: dimAlpha,
                      child: Container(color: Colors.black.withValues(alpha: 0.16)),
                    ),
                  ),
                ),
                // 菜单主体：整体缩放（scale，0.15→1.0，回弹靠这个体现）叠加
                // 纵向 clip 揭示（_RevealClipper，只裁高度不裁宽度——对应源码
                // popupClipReveal 只按 size.height 算 visibleHeight，宽度始终
                // 是满的），两者叠加才是源码里"从锚点长出来"的真实效果。
                Positioned(
                  left: menuLeft,
                  top: menuTop,
                  child: Opacity(
                    opacity: alpha,
                    child: Transform.scale(
                      alignment: expandFromTop
                          ? Alignment.topRight
                          : Alignment.bottomRight,
                      scale: scale,
                      child: ClipPath(
                        clipper: _RevealClipper(
                          progress: clipFraction,
                          radius: 16, // 对应源码 ListPopupContent 的 cornerRadius = 16.dp
                          fromTop: expandFromTop,
                        ),
                        child: SizedBox(
                          width: menuWidth,
                          child: Material(
                            color: Colors.white,
                            elevation: 16,
                            shadowColor: Colors.black.withValues(alpha: 0.22),
                            // Flutter 没有真正的 squircle（源码用
                            // addSquircleRect 画的连续曲率角），
                            // ContinuousRectangleBorder 是内置形状里最接近的
                            // 近似，这里如实标注不是逐像素还原。
                            shape: const ContinuousRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(16)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int i = 0; i < _roleKeys.length; i++)
                                    _buildRoleMenuItem(
                                      _roleKeys[i],
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
    // 对应源码 LaunchedEffect(show) 里 show=true 分支：三条轨道并行播放，
    // 互不等待。
    _fractionCtrl
      ..stop()
      ..value = 0
      ..animateWith(SpringSimulation(_fractionSpring, 0, 1, 0));
    _alphaCtrl
      ..value = 0
      ..animateTo(1, duration: _alphaEnterDuration, curve: Curves.fastOutSlowIn);
    _dimCtrl
      ..value = 0
      ..animateTo(1, duration: _dimEnterDuration, curve: Curves.easeOutSine);
  }

  Future<void> _closeRoleMenu({
    required FormFieldState<String> field,
    String? result,
  }) async {
    // 对应源码 LaunchedEffect(show) 里 show=false 分支：fraction 弹簧和 dim
    // 都是 launch 出去、不等它们播完；真正决定"什么时候可以摘掉 overlay"的
    // 只有 alpha 淡出（150ms）——源码原注释是"Alpha controls the master
    // timing: once content fades out, unmount immediately"。所以这里只
    // await alpha，其它两条各播各的，最后强制归零，跟源码的收尾方式一致。
    final fractionVelocity = _fractionCtrl.isAnimating ? _fractionCtrl.velocity : 0.0;
    _fractionCtrl.animateWith(
      SpringSimulation(_fractionSpring, _fractionCtrl.value, 0, fractionVelocity),
    );
    _dimCtrl.animateTo(0, duration: _dimExitDuration, curve: Curves.easeOutSine);
    await _alphaCtrl.animateTo(0, duration: _alphaExitDuration, curve: Curves.fastOutSlowIn);

    // 强制把三条轨道都归零，避免下次展开时残留上一次没播完的状态
    // （源码里同样有这一步：fractionProgress.snapTo(0f) 等）。
    _fractionCtrl.stop();
    _fractionCtrl.value = 0;
    _alphaCtrl.value = 0;
    _dimCtrl.value = 0;

    _roleMenuOverlay?.remove();
    _roleMenuOverlay = null;
    if (mounted) setState(() => _isRoleMenuOpen = false);

    if (result != null && mounted) {
      setState(() => _selectedRole = result);
      field.didChange(result);
    }
  }

  Widget _buildRoleMenuItem(String key, {required VoidCallback onTap}) {
    // 源码里 ListPopupColumn 本身不对单个列表项做错峰/入场动画，条目是随着
    // 外层整体的 scale+clip+alpha 一起出现的，这里就不再画蛇添足加逐项动画。
    final bool selected = key == _selectedRole;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
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

/// 纵向 clip 揭示裁剪器，逐字节对照 compose-miuix-ui/miuix 仓库
/// `miuix-ui/src/commonMain/kotlin/top/yukonga/miuix/kmp/basic/ListPopup.kt`
/// 里的 `Modifier.popupClipReveal` 移植：随 [progress] 从 0 到 1，一条与菜单
/// 等宽的横向色带从靠近触发字段的那条边（[fromTop] 为 true 时是顶边，为
/// false 时是底边）逐渐向另一侧长高，宽度全程保持满宽——**只裁高度，不裁
/// 宽度**，这一点和常见的"从角上对角线生长"的裁剪写法不一样，是刻意照抄
/// 源码的效果，不是随手实现的近似版本。
///
/// 源码原文（简化）：
/// ```kotlin
/// val visibleHeight = height * progress
/// val clipStart = if (showBelow) 0f else height * (1f - progress)
/// ```
/// 真正的"从小到大"视觉效果主要靠外层 [Transform.scale]（0.15→1.0）叠加
/// 这里的纵向揭示共同完成，二者缺一都不是源码的真实效果。
class _RevealClipper extends CustomClipper<Path> {
  final double progress; // 调用方已经 clamp 到 [0,1]
  final double radius;
  final bool fromTop;

  const _RevealClipper({
    required this.progress,
    required this.radius,
    required this.fromTop,
  });

  @override
  Path getClip(Size size) {
    final visibleHeight = size.height * progress;
    final clipStart = fromTop ? 0.0 : size.height - visibleHeight;
    final rect = Rect.fromLTWH(0, clipStart, size.width, visibleHeight);
    return Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  }

  @override
  bool shouldReclip(covariant _RevealClipper oldClipper) {
    return oldClipper.progress != progress ||
        oldClipper.fromTop != fromTop ||
        oldClipper.radius != radius;
  }
}
