import 'package:dio/dio.dart';

class HttpUtil {
  static String baseUrl = "";

  static final Dio _client = Dio(
    BaseOptions(
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );

  static String _buildUrl(String url) {
    if (url.startsWith("http://") || url.startsWith("https://")) {
      return url;
    }
    if (baseUrl.endsWith("/") && url.endsWith("/")) {
      return baseUrl + url.substring(1);
    }
    if (!baseUrl.endsWith("/") && !url.endsWith("/")) {
      return "$baseUrl/$url";
    }
    return baseUrl + url;
  }

  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client.get(
        _buildUrl(url),
        options: Options(headers: headers),
      );
      if (response.statusCode != 200) {
        throw Exception("请求失败, ${response.statusCode}");
      }
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception("GET 请求失败, $e");
    }
  }

  static Future<Map<String, dynamic>> post(
    String url,
    Map data, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client.post(
        _buildUrl(url),
        data: data,
        options: Options(headers: headers, contentType: "application/json"),
      );
      if (response.statusCode! < 200 || response.statusCode! > 300) {
        throw Exception("请求失败, ${response.statusCode}");
      }
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception("POST 请求失败, $e");
    }
  }

  static Future<Map<String, dynamic>> postFile(
    String url,
    List<String> filePaths, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  }) async {
    try {
      final formData = FormData();

      // 添加文件
      for (int i = 0; i < filePaths.length; i++) {
        formData.files.add(
          MapEntry(
            'file${i > 0 ? i : ''}',
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
        _buildUrl(url),
        data: formData,
        options: Options(headers: headers),
      );
      if (response.statusCode! < 200 || response.statusCode! > 300) {
        throw Exception("请求失败, ${response.statusCode}");
      }
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception("文件上传失败, $e");
    }
  }

  static void close() {
    _client.close();
  }
}
