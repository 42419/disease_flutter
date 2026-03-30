import 'dart:convert';
import 'dart:io';

class HttpUtil {
  static String baseUrl = "";

  static final HttpClient _client = HttpClient()
    ..connectionTimeout = Duration(seconds: 10)
    ..idleTimeout = Duration(seconds: 10);

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
      final request = await _client.getUrl(Uri.parse(_buildUrl(url)));
      headers?.forEach((key, value) => request.headers.set(key, value));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException("请求失败, ${response.statusCode}");
      }
      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = jsonDecode(responseBody);
      return data;
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
      final request = await _client.postUrl(Uri.parse(_buildUrl(url)));
      headers?.forEach((key, value) => request.headers.set(key, value));
      final body = utf8.encode(jsonEncode(data));
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.add(body);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode > 300) {
        throw HttpException("请求失败, ${response.statusCode}");
      }
      final responseBody = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> result = jsonDecode(responseBody);
      return result;
    } catch (e) {
      throw Exception("POST 请求失败, $e");
    }
  }
}
