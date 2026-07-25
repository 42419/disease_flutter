import 'dart:io';

import 'package:farm_flutter/config/config.dart';
import 'package:farm_flutter/models/prediction_result.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

/// 图片上传 & 病害识别的状态与业务逻辑。
///
/// 之前这部分逻辑（选图、定位解析、上传请求）直接写在 `UploadWidget`
/// （StatefulWidget）里，State 类同时承担 UI 构建和网络/定位业务逻辑，是典型
/// 的"上帝 Widget"。现在统一收敛到这个 Provider，Widget 只负责 UI 展示和用户
/// 交互，通过调用 [pickAndUpload] 触发完整流程。
///
/// 地区解析在自动定位失败时需要弹出一个"手动选择地区"的底部弹窗——这一步天然
/// 依赖 BuildContext/Navigator，无法也不应该塞进 Provider。因此这里通过
/// [ManualRegionResolver] 回调把这一小段 UI 逻辑留在调用方（Widget），业务主流程
/// 仍然完全在 Provider 内部完成。
typedef ManualRegionResolver = Future<String?> Function();

class UploadProvider extends ChangeNotifier {
  File? _selectedImage;
  bool _isUploading = false;
  String? _result;
  String? _errorMessage;
  String? _heatmapData;
  List<String>? _top5Classes;
  List<double>? _predictTop5;
  String _uploadImageName = "";
  String _amapAdcode = "";

  final ImagePicker _picker = ImagePicker();

  /// 用于丢弃过期请求的结果（例如用户在上一张图片还在上传时又选了新图）。
  int _uploadGeneration = 0;

  File? get selectedImage => _selectedImage;
  bool get isUploading => _isUploading;
  String? get result => _result;
  String? get errorMessage => _errorMessage;
  String? get heatmapData => _heatmapData;
  List<String>? get top5Classes => _top5Classes;
  List<double>? get predictTop5 => _predictTop5;
  String get uploadImageName => _uploadImageName;
  String get amapAdcode => _amapAdcode;

  void setImage(File file, String name) {
    _selectedImage = file;
    _result = null;
    _errorMessage = null;
    _heatmapData = null;
    _top5Classes = null;
    _predictTop5 = null;
    _uploadImageName = name;
    notifyListeners();
  }

  void setUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }

  void setResult({
    required String? result,
    String? heatmapData,
    List<String>? top5Classes,
    List<double>? predictTop5,
  }) {
    _isUploading = false;
    _result = result;
    _errorMessage = null;
    _heatmapData = heatmapData;
    _top5Classes = top5Classes;
    _predictTop5 = predictTop5;
    notifyListeners();
  }

  void setError(String message) {
    _isUploading = false;
    _errorMessage = message;
    notifyListeners();
  }

  void setAdcode(String adcode) {
    _amapAdcode = adcode;
    notifyListeners();
  }

  void reset() {
    _selectedImage = null;
    _isUploading = false;
    _result = null;
    _errorMessage = null;
    _heatmapData = null;
    _top5Classes = null;
    _predictTop5 = null;
    _uploadImageName = "";
    _amapAdcode = "";
    notifyListeners();
  }

  /// 选择图片（拍照/相册）并自动触发识别上传的完整流程。
  ///
  /// [resolveManualRegion] 在自动定位/逆地理编码失败时被调用，由调用方负责弹出
  /// 手动选择地区的 UI 并返回选中的 adcode（用户取消则返回 null）。
  Future<void> pickAndUpload(
    ImageSource source, {
    required ManualRegionResolver resolveManualRegion,
  }) async {
    if (_isUploading) {
      setUploading(false);
    }

    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile == null) return;

      debugPrint('图片选择成功: ${pickedFile.path}');
      setImage(File(pickedFile.path), pickedFile.name);
      await _uploadImage(resolveManualRegion: resolveManualRegion);
    } catch (e) {
      debugPrint('图片选择异常: $e');
      setError('选择图片失败: $e');
    }
  }

  Future<void> _uploadImage({
    required ManualRegionResolver resolveManualRegion,
  }) async {
    if (_isUploading) return;
    final imagePath = _selectedImage?.path;
    if (imagePath == null) return;

    final generation = ++_uploadGeneration;
    setUploading(true);

    try {
      String? adcode;
      try {
        adcode = await _resolveAdcode(resolveManualRegion);
      } catch (e) {
        debugPrint('定位解析异常: $e');
      }
      if (generation != _uploadGeneration) return;
      setAdcode(adcode ?? '');

      // 默认后端的 X-API-Token 由 HttpUtil 统一自动注入，无需在这里手传。
      final response = await HttpUtil.postFile(
        "/predict",
        [imagePath],
        fileField: "image",
      );

      if (generation != _uploadGeneration) return;

      final result = PredictionResult.fromResponse(response);
      setResult(
        result: result.result,
        heatmapData: result.heatmapData,
        top5Classes: result.top5Classes,
        predictTop5: result.predictTop5,
      );
    } catch (e) {
      if (generation != _uploadGeneration) return;
      setError("上传失败: $e");
    }
  }

  Future<String?> _resolveAdcode(ManualRegionResolver resolveManualRegion) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('定位权限不可用，进入手动地区选择');
        return resolveManualRegion();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final resp = await HttpUtil.get(
        '/v3/geocode/regeo?key=${Config.amapKey}&location=${position.longitude},${position.latitude}',
        baseUrl: Config.amapBaseUrl,
      );

      if (resp is Map) {
        final regeocode = resp['regeocode'];
        final addressComponent = regeocode is Map
            ? regeocode['addressComponent']
            : null;
        final adcode = addressComponent is Map
            ? addressComponent['adcode']?.toString()
            : null;
        if (adcode != null && adcode.isNotEmpty && adcode != '[]') {
          return adcode;
        }
      }

      debugPrint('逆地理编码未返回有效 adcode: $resp');
    } catch (e) {
      debugPrint('GPS 定位/逆地理编码异常: $e');
    }

    return resolveManualRegion();
  }
}
