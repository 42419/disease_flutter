import 'dart:io';

import 'package:flutter/foundation.dart';

class UploadProvider extends ChangeNotifier {
  File? _selectedImage;
  bool _isUploading = false;
  String? _result;
  String? _heatmapData;
  List<String>? _top5Classes;
  List<double>? _predictTop5;
  String _uploadImageName = "";
  String _amapAdcode = "";

  File? get selectedImage => _selectedImage;
  bool get isUploading => _isUploading;
  String? get result => _result;
  String? get heatmapData => _heatmapData;
  List<String>? get top5Classes => _top5Classes;
  List<double>? get predictTop5 => _predictTop5;
  String get uploadImageName => _uploadImageName;
  String get amapAdcode => _amapAdcode;

  void setImage(File file, String name) {
    _selectedImage = file;
    _result = null;
    _heatmapData = null;
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
    _heatmapData = heatmapData;
    _top5Classes = top5Classes;
    _predictTop5 = predictTop5;
    notifyListeners();
  }

  void setError(String message) {
    _isUploading = false;
    _result = message;
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
    _heatmapData = null;
    _top5Classes = null;
    _predictTop5 = null;
    _uploadImageName = "";
    _amapAdcode = "";
    notifyListeners();
  }
}
