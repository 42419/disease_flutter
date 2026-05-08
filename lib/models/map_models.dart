import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GeoRegion {
  final String id;
  final String name;
  final String level;
  final String? parentAdcode;
  final LatLng center;
  final List<GeoPolygonData> polygons;

  const GeoRegion({
    required this.id,
    required this.name,
    required this.level,
    required this.parentAdcode,
    required this.center,
    required this.polygons,
  });
}

class GeoPolygonData {
  final List<LatLng> outer;
  final List<List<LatLng>> holes;

  const GeoPolygonData({required this.outer, required this.holes});
}

class GeoDataBundle {
  final List<GeoRegion> regions;
  final LatLngBounds? bounds;

  const GeoDataBundle({required this.regions, required this.bounds});
}
