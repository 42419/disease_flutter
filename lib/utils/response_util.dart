/// 将 HTTP 响应体安全转换为 Map，并提供角色解析辅助。
class ResponseUtil {
  ResponseUtil._();

  /// 仅接受 Map；其它类型返回 null。
  static Map<String, dynamic>? asMap(dynamic response) {
    if (response is Map<String, dynamic>) return response;
    if (response is Map) {
      return response.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  /// 优先使用服务端返回的 role（"0"/"1"），否则回退到客户端选择。
  static String resolveRole(dynamic response, String? clientRole) {
    final map = asMap(response);
    final serverRole = map?['role']?.toString();
    if (serverRole == '0' || serverRole == '1') {
      return serverRole!;
    }
    if (clientRole == '0' || clientRole == '1') {
      return clientRole!;
    }
    return '0';
  }

  static bool isLoginSuccess(Map<String, dynamic> map) {
    return map['msg']?.toString() == 'success';
  }
}
