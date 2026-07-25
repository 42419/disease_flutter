import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:farm_flutter/models/user.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:farm_flutter/utils/response_util.dart';

/// 登录请求的结果。
///
/// 把"调用 /login 接口 + 解析响应"这段逻辑收拢到 [UserProvider] 里，是因为
/// `login_page.dart`（用户手动登录）和 `app_init_page.dart`（记住密码后的自动
/// 登录）之前各自复制了一份几乎一样的请求/解析代码，属于典型的重复业务逻辑
/// 塞在页面 State 里的"上帝 Widget"问题。收拢后两处页面都只需要处理 UI 交互，
/// 登录网络请求只有一份实现。
class LoginResult {
  final bool success;
  final String? nickName;
  final String? role;
  final String message;

  const LoginResult.success({required String nickName, required String role})
      : success = true,
        nickName = nickName,
        role = role,
        message = '';

  const LoginResult.failure(this.message)
      : success = false,
        nickName = null,
        role = null;
}

class UserProvider extends ChangeNotifier {
  final User _user = User();

  String get nickName => _user.nickName;
  String get role => _user.role;
  String get userAvatarUrl => _user.userAvatarUrl;
  bool get isAdmin => _user.role == '1';

  void login(String nickName, String role) {
    _user.nickName = nickName;
    _user.role = role;
    notifyListeners();
  }

  void clear() {
    _user.nickName = "";
    _user.role = "0";
    _user.userAvatarUrl = "assets/img/avatar.jpg";
    notifyListeners();
  }

  /// 调用 `/login` 接口完成登录；成功时会同步更新当前用户状态（等价于调用
  /// [login]），调用方不需要再手动调一次。
  ///
  /// 后端登录鉴权本身的正确性/安全性不在这次改动范围内，这里只是把散落在两个
  /// 页面里的请求与响应解析代码合并成一份。
  Future<LoginResult> loginWithCredentials({
    required String username,
    required String password,
    required String role,
  }) async {
    try {
      // 默认后端的 X-API-Token 由 HttpUtil 统一自动注入，无需在这里手传。
      final rawResponse = await HttpUtil.post('/login', {
        'username': username,
        'pwd': password,
        'role': role,
      });

      final response = ResponseUtil.asMap(rawResponse);
      if (response == null || !ResponseUtil.isLoginSuccess(response)) {
        return LoginResult.failure(response?['msg']?.toString() ?? '响应格式异常');
      }

      // 优先使用服务端返回的角色，避免客户端自选绕过权限。
      final resolvedRole = ResponseUtil.resolveRole(response, role);
      final resolvedName = response['username']?.toString() ?? username;

      login(resolvedName, resolvedRole);
      return LoginResult.success(nickName: resolvedName, role: resolvedRole);
    } on DioException catch (e) {
      debugPrint('登录请求 DioException: ${e.type}, ${e.message}, ${e.error}');
      return const LoginResult.failure('网络连接失败，请检查网络和服务器');
    } catch (e) {
      debugPrint('登录异常: $e');
      return LoginResult.failure('登录异常: $e');
    }
  }
}
