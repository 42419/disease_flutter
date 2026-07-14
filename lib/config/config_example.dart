import 'package:farm_flutter/config/province_config.dart';

class Config {
  // ==================== 当前显示省份 ====================
  // 修改此值即可切换地图显示的省份，可选值见 Provinces 类
  static const ProvinceConfig currentProvince = Provinces.liaoning;
  // =====================================================

  // 识别接口
  static const String apiUrl = "http://example.com";
  static const String apiToken = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
  // coze智能体接口
  static const String cozeUrl = "https://api.coze.cn/v3/chat?";
  static const String botId = "xxxxxxxxxxxxxxxxxx";
  static const String userId = "xxxxxx";
  static const String cozeToken = "Bearer pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
  // 高德地图Web API
  static const String amapKey = "xxxxxxxxxxxxxxxxxxxxx";
  static const String amapIpConfigUrl = "https://restapi.amap.com/v3/ip/config";
}
