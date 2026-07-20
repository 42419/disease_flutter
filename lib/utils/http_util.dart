import 'package:dio/dio.dart';

class HttpUtil {
  static String _baseUrl = '';

  /// 全局初始化，只在 main.dart 调用一次
  static void init({required String baseUrl}) {
    _baseUrl = baseUrl;
  }

  /// 根据 baseUrl 和 headers 构建独立 Dio 实例
  static Dio _buildClient({String? baseUrl, Map<String, String>? headers}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl ?? _baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        contentType: "application/json",
        headers: headers,
      ),
    );
  }

  static Future<dynamic> get(
      String url, {
        Map<String, String>? headers,
        String? baseUrl,
      }) async {
    final client = _buildClient(baseUrl: baseUrl, headers: headers);
    try {
      final response = await client.get(url);
      final statusCode = response.statusCode;
      if (statusCode == null || statusCode < 200 || statusCode >= 300) {
        throw Exception("请求失败: $statusCode");
      }
      return response.data;
    } on DioException {
      rethrow;  // 保留原始异常，上层自行处理
    } finally {
      client.close();
    }
  }

  static Future<dynamic> post(
      String url,
      dynamic data, {
        Map<String, String>? headers,
        String? baseUrl,
      }) async {
    final client = _buildClient(baseUrl: baseUrl, headers: headers);
    try {
      final response = await client.post(url, data: data);
      final statusCode = response.statusCode;
      if (statusCode == null || statusCode < 200 || statusCode >= 300) {
        throw Exception("请求失败: $statusCode");
      }
      return response.data;
    } on DioException {
      rethrow;
    } finally {
      client.close();
    }
  }

  /// 流式请求，返回 (response, dioClient)。
  /// 调用方消费完流后**必须**调用 dioClient.close() 释放连接。
  static Future<(Response<ResponseBody> response, Dio dioClient)> postStream(
      String url,
      Map data, {
        Map<String, String>? headers,
        String? baseUrl,
        CancelToken? cancelToken,
      }) async {
    final client = _buildClient(baseUrl: baseUrl, headers: headers);
    try {
      final response = await client.post<ResponseBody>(
        url,
        data: data,
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );
      final statusCode = response.statusCode;
      if (statusCode == null || statusCode < 200 || statusCode >= 300) {
        client.close(force: true);
        throw Exception("请求失败: $statusCode");
      }
      return (response, client);
    } on DioException {
      client.close(force: true);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> postFile(
      String url,
      List<String> filePaths, {
        Map<String, dynamic>? data,
        Map<String, String>? headers,
        String fileField = 'file',
        String? baseUrl,
      }) async {
    final client = _buildClient(baseUrl: baseUrl, headers: headers);
    try {
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

      final response = await client.post(url, data: formData);
      final statusCode = response.statusCode;
      if (statusCode == null || statusCode < 200 || statusCode >= 300) {
        throw Exception("请求失败: $statusCode");
      }
      return response.data as Map<String, dynamic>;
    } on DioException {
      rethrow;
    } finally {
      client.close();
    }
  }

  static void close() {
    // No longer needed - Dio clients are per-request and auto-recycled
  }
}
