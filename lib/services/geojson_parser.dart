import 'dart:convert';

import 'package:farm_flutter/models/map_models.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// GeoJSON 解析器：将 assets 中的 GeoJSON 文件解析为 [GeoRegion] 集合。
class GeoJsonParser {
  const GeoJsonParser();

  /// 从 asset 路径加载并解析 GeoJSON，返回 [GeoDataBundle]。
  Future<GeoDataBundle> loadFromAsset(String assetPath) async {
    final rawJson = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final features = decoded['features'];
    if (features is! List) {
      throw FormatException('$assetPath 的 GeoJSON features 格式无效');
    }

    final regions = <GeoRegion>[];
    final allPoints = <LatLng>[];

    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;

      final properties = feature['properties'] as Map<String, dynamic>? ?? {};
      final geometry = feature['geometry'] as Map<String, dynamic>? ?? {};
      final parsedPolygons = _parseGeometry(geometry);
      if (parsedPolygons.isEmpty) continue;

      for (final polygon in parsedPolygons) {
        allPoints.addAll(polygon.outer);
      }

      final adcode = properties['adcode']?.toString();
      final name = properties['name']?.toString() ?? '未命名区域';
      final parent = properties['parent'] as Map<String, dynamic>?;
      final parentAdcode = parent?['adcode']?.toString();
      final centroid =
          _readPoint(properties['centroid']) ??
          _readPoint(properties['center']) ??
          _calculateCentroid(parsedPolygons.first.outer);

      regions.add(
        GeoRegion(
          id: adcode ?? name,
          name: name,
          level: properties['level']?.toString() ?? '',
          parentAdcode: parentAdcode,
          center: centroid,
          polygons: parsedPolygons,
        ),
      );
    }

    return GeoDataBundle(
      regions: regions,
      bounds: allPoints.isEmpty ? null : LatLngBounds.fromPoints(allPoints),
    );
  }

  List<GeoPolygonData> _parseGeometry(Map<String, dynamic> geometry) {
    final type = geometry['type']?.toString();
    final coordinates = geometry['coordinates'];
    if (type == null || coordinates is! List) return const [];

    final polygons = <GeoPolygonData>[];

    if (type == 'Polygon') {
      final polygon = _parseSinglePolygon(coordinates);
      if (polygon != null) polygons.add(polygon);
    } else if (type == 'MultiPolygon') {
      for (final polygonCoordinates in coordinates) {
        if (polygonCoordinates is! List) continue;
        final polygon = _parseSinglePolygon(polygonCoordinates);
        if (polygon != null) polygons.add(polygon);
      }
    }

    return polygons;
  }

  GeoPolygonData? _parseSinglePolygon(List<dynamic> coordinates) {
    if (coordinates.isEmpty) return null;

    final rings = <List<LatLng>>[];
    for (final ringCoordinates in coordinates) {
      if (ringCoordinates is! List) continue;
      final ring = <LatLng>[];
      for (final point in ringCoordinates) {
        if (point is! List || point.length < 2) continue;
        final lng = (point[0] as num?)?.toDouble();
        final lat = (point[1] as num?)?.toDouble();
        if (lng == null || lat == null) continue;
        ring.add(LatLng(lat, lng));
      }
      if (ring.length >= 3) {
        rings.add(ring);
      }
    }

    if (rings.isEmpty) return null;

    return GeoPolygonData(
      outer: rings.first,
      holes: rings.length > 1 ? rings.sublist(1) : const [],
    );
  }

  LatLng? _readPoint(dynamic rawPoint) {
    if (rawPoint is! List || rawPoint.length < 2) return null;
    final lng = (rawPoint[0] as num?)?.toDouble();
    final lat = (rawPoint[1] as num?)?.toDouble();
    if (lng == null || lat == null) return null;
    return LatLng(lat, lng);
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    var latSum = 0.0;
    var lngSum = 0.0;
    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }
}
