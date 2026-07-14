import 'package:latlong2/latlong.dart';

/// 省份地图配置，每个省份独立定义 GeoJSON 路径、中心坐标、缩放参数
class ProvinceConfig {
  final String name;
  final String cityGeoJsonPath;
  final String districtGeoJsonPath;
  final LatLng center;
  final double initialZoom;
  final double districtLabelZoom;
  final double districtDetailZoom;
  final double minZoom;
  final double maxZoom;

  const ProvinceConfig({
    required this.name,
    required this.cityGeoJsonPath,
    required this.districtGeoJsonPath,
    required this.center,
    this.initialZoom = 6.8,
    this.districtLabelZoom = 8.1,
    this.districtDetailZoom = 9.6,
    this.minZoom = 5.0,
    this.maxZoom = 10.2,
  });
}

/// 预定义省份配置
class Provinces {
  static const henan = ProvinceConfig(
    name: '河南省',
    cityGeoJsonPath: 'assets/geojson/河南省_市.geojson',
    districtGeoJsonPath: 'assets/geojson/河南省_县区.geojson',
    center: LatLng(34.0, 113.0),
  );

  static const liaoning = ProvinceConfig(
    name: '辽宁省',
    cityGeoJsonPath: 'assets/geojson/辽宁省_市.geojson',
    districtGeoJsonPath: 'assets/geojson/辽宁省_县区.geojson',
    center: LatLng(41.3, 123.0),
    initialZoom: 7.0,
  );

  /// 所有可用省份（方便后续扩展）
  static const all = [henan, liaoning];
}
