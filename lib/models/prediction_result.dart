import 'dart:convert';
import 'dart:typed_data';

class PredictionResult {
  final String result;
  final String? heatmapData;
  final List<String> top5Classes;
  final List<double> predictTop5;

  const PredictionResult({
    required this.result,
    required this.heatmapData,
    required this.top5Classes,
    required this.predictTop5,
  });

  factory PredictionResult.fromResponse(Map<String, dynamic> response) {
    final classesRaw = response['top5class'];
    final scoresRaw = response['predicttop5'];

    if (classesRaw is! List || classesRaw.isEmpty) {
      throw const FormatException('识别结果格式异常：top5class 为空或不存在');
    }
    if (scoresRaw is! List) {
      throw const FormatException('识别结果格式异常：predicttop5 不存在');
    }

    final classes = classesRaw.map((e) => e.toString()).toList();
    final scores = scoresRaw
        .map((e) {
          if (e is num) return e.toDouble();
          return double.tryParse(e.toString());
        })
        .whereType<double>()
        .toList();

    if (scores.isEmpty) {
      throw const FormatException('识别结果格式异常：predicttop5 为空或无法解析');
    }

    return PredictionResult(
      result: classes.first,
      heatmapData: response['heatmap']?.toString(),
      top5Classes: classes,
      predictTop5: scores,
    );
  }

  int get displayCount {
    final count = top5Classes.length < predictTop5.length
        ? top5Classes.length
        : predictTop5.length;
    return count < 5 ? count : 5;
  }

  Uint8List? tryDecodeHeatmap() {
    final data = heatmapData;
    if (data == null || data.isEmpty) return null;
    try {
      return base64Decode(data);
    } on FormatException {
      return null;
    }
  }
}
