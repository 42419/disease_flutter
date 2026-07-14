import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // 识别接口
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  static String get apiToken => dotenv.env['API_TOKEN'] ?? '';

  // coze智能体接口
  static String get cozeUrl => dotenv.env['COZE_URL'] ?? '';
  static String get botId => dotenv.env['BOT_ID'] ?? '';
  static String get userId => dotenv.env['USER_ID'] ?? '';
  static String get cozeToken => dotenv.env['COZE_TOKEN'] ?? '';

  // 高德地图Web API
  static String get amapBaseUrl =>
      dotenv.env['AMAP_BASE_URL'] ?? 'https://restapi.amap.com';
  static String get amapKey => dotenv.env['AMAP_KEY'] ?? '';
}