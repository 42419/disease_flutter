import 'package:dio/dio.dart';

class HttpUtil {
  static late Dio _client;

  /// 全局初始化，只在 main.dart 调用一次
  static void init({required String baseUrl}) {
    _client = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: "application/json",
      ),
    );
  }

  /// 登录等需要不同 baseUrl 的场景，临时创建独立实例
  static Dio _buildClient({String? baseUrl, Map<String, String>? headers}) {
    return Dio(
      BaseOptions(
        baseUrl: baseUrl ?? _client.options.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
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
      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception("请求失败: ${response.statusCode}");
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
      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception("请求失败: ${response.statusCode}");
      }
      return response.data;
    } on DioException {
      rethrow;
    } finally {
      client.close();
    }
  }

  static Future<Response<ResponseBody>> postStream(
      String url,
      Map data, {
        Map<String, String>? headers,
        String? baseUrl,
      }) async {
    final client = _buildClient(baseUrl: baseUrl, headers: headers);
    try {
      final response = await client.post<ResponseBody>(
        url,
        data: data,
        options: Options(responseType: ResponseType.stream),
      );
      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception("请求失败: ${response.statusCode}");
      }
      return response;
    } on DioException {
      rethrow;
    } finally {
      client.close();
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
      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception("请求失败: ${response.statusCode}");
      }
      return response.data as Map<String, dynamic>;
    } on DioException {
      rethrow;
    } finally {
      client.close();
    }
  }

  static void close() {
    _client.close(force: true);
  }
}
