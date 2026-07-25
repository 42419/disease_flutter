import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:farm_flutter/config/config.dart';

/// 全局 HTTP 客户端工具类。
///
/// 与早期版本（每次请求都 `new` 一个 Dio 实例，用完即 `close()`）不同，现在按
/// baseUrl 维度缓存并复用 Dio 实例：
///   1. 同一 baseUrl 只创建一次底层 HttpClient/连接池，避免每次请求都重新握手；
///   2. 请求默认后端（[Config.baseUrl]）时自动附加 `X-API-Token`，调用方无需每次
///      手动传递；如需覆盖/追加，仍可通过各方法的 [headers] 参数传入；
///   3. 统一拦截：调试模式下打印请求/响应/错误日志、GET 请求在瞬时网络错误下的
///      自动重试、401 响应的全局钩子（[onUnauthorized]），不用每个调用点各写一份。
class HttpUtil {
  HttpUtil._();

  static String _defaultBaseUrl = '';

  /// 按 baseUrl 缓存的 Dio 实例，实现连接复用。
  static final Map<String, Dio> _clients = {};

  /// 收到 401 响应时触发的全局钩子，默认不做任何处理。
  /// 如果之后要做"登录态失效自动登出"，在 main.dart 里赋值即可，HttpUtil 本身
  /// 不关心也不处理登录/鉴权业务。
  static void Function()? onUnauthorized;

  /// 全局初始化，设置未显式传入 baseUrl 时使用的默认值。
  /// 重复调用是安全的：同一个 baseUrl 只会创建一次底层 Dio 实例（[_clientFor]）。
  static void init({required String baseUrl}) {
    _defaultBaseUrl = baseUrl;
  }

  static Dio _clientFor(String baseUrl) {
    return _clients.putIfAbsent(baseUrl, () => _createClient(baseUrl));
  }

  static Dio _createClient(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        contentType: "application/json",
        // 仅默认后端自动注入鉴权 Token；调用方可在单次请求 headers 中覆盖/追加，
        // 第三方接口（如 Coze、高德）各自在调用处显式传自己的 headers。
        headers: baseUrl == Config.baseUrl
            ? {"X-API-Token": Config.apiToken}
            : null,
      ),
    );

    dio.interceptors.addAll([
      _buildLoggingInterceptor(),
      _buildRetryInterceptor(dio),
    ]);

    return dio;
  }

  static Interceptor _buildLoggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode) {
          debugPrint('[HTTP] → ${options.method} ${options.baseUrl}${options.path}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint(
            '[HTTP] ← ${response.statusCode} '
            '${response.requestOptions.method} ${response.requestOptions.path}',
          );
        }
        handler.next(response);
      },
      onError: (error, handler) {
        final statusCode = error.response?.statusCode;
        if (kDebugMode) {
          debugPrint(
            '[HTTP] ✗ ${error.requestOptions.method} ${error.requestOptions.path} '
            '(${error.type}${statusCode != null ? ', $statusCode' : ''}): ${error.message}',
          );
        }
        if (statusCode == 401) {
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    );
  }

  /// 针对 GET 请求的轻量重试：只在连接类瞬时错误（连接超时/连接失败/接收超时）
  /// 时重试，不重试 POST 等非幂等请求，避免重复提交；最多重试 2 次，间隔递增。
  static Interceptor _buildRetryInterceptor(Dio dio) {
    const maxRetries = 2;
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final options = error.requestOptions;
        final isRetryableMethod = options.method.toUpperCase() == 'GET';
        final isTransientError = error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.receiveTimeout;
        final retryCount = (options.extra['retryCount'] as int?) ?? 0;

        if (isRetryableMethod && isTransientError && retryCount < maxRetries) {
          options.extra['retryCount'] = retryCount + 1;
          await Future<void>.delayed(Duration(milliseconds: 400 * (retryCount + 1)));
          try {
            final response = await dio.fetch(options);
            handler.resolve(response);
            return;
          } catch (_) {
            // 重试仍失败，落回原始错误流程，交给上层业务处理。
          }
        }
        handler.next(error);
      },
    );
  }

  static Future<dynamic> get(
    String url, {
    Map<String, String>? headers,
    String? baseUrl,
  }) async {
    final client = _clientFor(baseUrl ?? _defaultBaseUrl);
    final response = await client.get(url, options: Options(headers: headers));
    return response.data;
  }

  static Future<dynamic> post(
    String url,
    dynamic data, {
    Map<String, String>? headers,
    String? baseUrl,
  }) async {
    final client = _clientFor(baseUrl ?? _defaultBaseUrl);
    final response = await client.post(
      url,
      data: data,
      options: Options(headers: headers),
    );
    return response.data;
  }

  /// 流式请求，返回 (response, dioClient)。
  ///
  /// dioClient 现在是按 baseUrl 缓存复用的共享实例，**调用方不应再手动
  /// `close()` 它**（否则会连带关闭其它请求共用的连接）。如需中途中断，请使用
  /// [cancelToken]。
  ///
  /// SSE 场景默认使用更长的 [receiveTimeout]（5 分钟），避免长回复被默认的
  /// 20s 超时截断；该 receiveTimeout 只作用于本次请求，不影响共享客户端其它
  /// 请求的默认超时配置。
  static Future<(Response<ResponseBody> response, Dio dioClient)> postStream(
    String url,
    Map data, {
    Map<String, String>? headers,
    String? baseUrl,
    CancelToken? cancelToken,
    Duration receiveTimeout = const Duration(minutes: 5),
  }) async {
    final client = _clientFor(baseUrl ?? _defaultBaseUrl);
    final response = await client.post<ResponseBody>(
      url,
      data: data,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
        receiveTimeout: receiveTimeout,
      ),
      cancelToken: cancelToken,
    );
    return (response, client);
  }

  static Future<Map<String, dynamic>> postFile(
    String url,
    List<String> filePaths, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    String fileField = 'file',
    String? baseUrl,
  }) async {
    final client = _clientFor(baseUrl ?? _defaultBaseUrl);
    final formData = FormData();

    for (int i = 0; i < filePaths.length; i++) {
      formData.files.add(
        MapEntry(
          '$fileField${i > 0 ? i : ''}',
          await MultipartFile.fromFile(filePaths[i]),
        ),
      );
    }

    if (data != null) {
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
    }

    final response = await client.post(
      url,
      data: formData,
      options: Options(headers: headers),
    );
    return response.data as Map<String, dynamic>;
  }

  /// 关闭并清空所有缓存的 Dio 实例。
  ///
  /// 正常运行期间不需要调用——实例会一直被复用；仅用于单元测试之间重置状态，
  /// 或者应用完全退出时的资源释放。取代旧版本里那个从未被调用、什么也不做的
  /// `close()` 死代码。
  static void closeAll() {
    for (final client in _clients.values) {
      client.close(force: true);
    }
    _clients.clear();
  }
}
