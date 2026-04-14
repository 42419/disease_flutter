import 'package:dio/dio.dart';

class HttpUtil {
  static String _baseUrl = "";

  static final Dio _client = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );

  static void init({required String baseUrl}) {
    _baseUrl = baseUrl;
  }

  static String buildUrl(String url) {
    if (url.startsWith("http://") || url.startsWith("https://")) {
      return url;
    }
    if (_baseUrl.isEmpty) {
      throw Exception("请先调用HttpUtil.init()设置baseUrl");
    }
    if (_baseUrl.endsWith("/") && url.startsWith("/")) {
      return _baseUrl + url.substring(1);
    }
    if (!_baseUrl.endsWith("/") && !url.startsWith("/")) {
      return "$_baseUrl/$url";
    }
    return _baseUrl + url;
  }

  static Future<dynamic> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client.get(
        buildUrl(url),
        options: Options(headers: headers),
      );
      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception("请求失败: ${response.statusCode}");
      }
      return response.data;
    } catch (e) {
      throw Exception("GET 请求失败: $e");
    }
  }

  static Future<dynamic> post(
    String url,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client.post(
        buildUrl(url),
        data: data,
        options: Options(headers: headers, contentType: "application/json"),
      );
      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception("请求失败: ${response.statusCode}");
      }
      return response.data;
    } catch (e) {
      throw Exception("POST 请求失败: $e");
    }
  }

  static Future<Response<ResponseBody>> postStream(
    String url,
    Map data, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client.post<ResponseBody>(
        buildUrl(url),
        data: data,
        options: Options(
          headers: headers,
          contentType: "application/json",
          responseType: ResponseType.stream,
        ),
      );
      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception("请求失败: ${response.statusCode}");
      }
      return response;
    } catch (e) {
      if (e is DioException) rethrow; // 抛出异常让外层处理
      throw Exception("POST Stream 请求失败: $e");
    }
  }

  static Future<Map<String, dynamic>> postFile(
    String url,
    List<String> filePaths, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
    String fileField = 'file',
  }) async {
    try {
      final formData = FormData();

      // 添加文件
      for (int i = 0; i < filePaths.length; i++) {
        formData.files.add(
          MapEntry(
            '$fileField${i > 0 ? i : ''}',
            await MultipartFile.fromFile(filePaths[i]),
          ),
        );
      }

      // 添加其他表单数据
      if (data != null) {
        data.forEach((key, value) {
          formData.fields.add(MapEntry(key, value.toString()));
        });
      }

      final response = await _client.post(
        buildUrl(url),
        data: formData,
        options: Options(headers: headers),
      );

      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception("请求失败: ${response.statusCode}");
      }

      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception("文件上传失败: $e");
    }
  }

  static void close() {
    _client.close(force: true);
  }
}
