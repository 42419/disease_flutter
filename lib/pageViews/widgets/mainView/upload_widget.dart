import 'dart:convert';
import 'dart:io';

import 'package:farm_flutter/config/config.dart';
import 'package:farm_flutter/utils/global.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/http_util.dart';

class UploadWidget extends StatefulWidget {
  final VoidCallback? onImageSelected;

  const UploadWidget({super.key, this.onImageSelected});

  @override
  State<UploadWidget> createState() => _UploadWidgetState();
}

class _UploadWidgetState extends State<UploadWidget> {
  File? _selectedImage;
  bool _isUploading = false;
  String? _result;
  String? _heatmapData;
  List<String>? _top5Classes;
  List<double>? _predictTop5;

  void _showCategoryDetails() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "类别详情",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.uploadAreaBorder,
                    width: 1,
                  ),
                ),
                child: SelectableText(
                  _result ?? "请上传图片",
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.uploadAreaBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "关闭",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          final text = _result ?? "请上传图片";
                          Clipboard.setData(ClipboardData(text: text));
                          Navigator.pop(dialogContext);
                          // 使用主 context 显示 SnackBar，确保其显示在最上层
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("已复制到剪贴板"),
                              duration: Duration(seconds: 2),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "复制",
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部指示器
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 6),
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 标题
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  "选择图片",
                  style: TextStyle(
                    fontFamily: "serif",
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              Divider(color: AppColors.hairline, height: 1),

              // 拍照上传选项
              _buildOptionItem(
                icon: Icons.camera_alt_rounded,
                title: "拍照上传",
                subtitle: "使用相机拍摄照片",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              // 分割线
              Divider(
                color: AppColors.hairline,
                height: 1,
                indent: 20,
                endIndent: 20,
              ),

              // 从相册选择选项
              _buildOptionItem(
                icon: Icons.photo_library_rounded,
                title: "从相册选择",
                subtitle: "从图库中选择已有照片",
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),

              // 取消按钮
              Padding(
                padding: EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "取消",
                    style: TextStyle(
                      fontFamily: "serif",
                      color: AppColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // 图标容器
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Icon(icon, color: AppColors.ink, size: 22),
            ),
            SizedBox(width: 14),

            // 文字部分
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: "serif",
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: "serif",
                      fontSize: 12,
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // 箭头图标
            Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _result = null;
        _heatmapData = null;
      });
      Global.uploadImageName = pickedFile.name;
      // 通知父组件图片已选择
      widget.onImageSelected?.call();
      // 选图后自动上传
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    // 上传图片的同时获取adcode
    _fetchAdcode();

    try {
      HttpUtil.init(baseUrl: Config.baseUrl);

      final headers = {"X-API-Token": Config.apiToken};

      final response = await HttpUtil.postFile(
        "/predict",
        [_selectedImage!.path],
        headers: headers,
        fileField: "image",
      );

      if (mounted) {
        String? successValue;
        successValue = response['top5class'][0]?.toString();
        setState(() {
          _isUploading = false;
          _result = successValue ?? response.toString();
          _heatmapData = response['heatmap']?.toString();
          if (response["top5class"] != null &&
              response["predicttop5"] != null) {
            _top5Classes = List<String>.from(response["top5class"]);
            _predictTop5 = List<double>.from(response["predicttop5"]);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _result = "上传失败: $e";
        });
      }
    }
  }

  Future<void> _fetchAdcode() async {
    // 测试模式：硬编码为辽宁省锦州市太和区
    Global.amapAdcode = '210711';
    debugPrint('test：adcode 已硬编码为 210711 (辽宁省锦州市太和区)');
  }

  Widget _buildProbabilityItem(int index, String name, double percent) {
    final percentage = (percent * 100).toStringAsFixed(1);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              "0${index + 1}",
              style: TextStyle(
                fontFamily: "serif",
                color: index == 0 ? AppColors.ink : AppColors.muted,
                fontSize: 16,
                fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: name,
              triggerMode: TooltipTriggerMode.longPress,
              showDuration: Duration(seconds: 3),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(4),
              ),
              textStyle: TextStyle(
                color: AppColors.canvas,
                fontSize: 14,
                height: 1.4,
              ),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
                  color: AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Container(
              height: 3,
              color: AppColors.hairline,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 3,
                  color: index == 0 ? AppColors.ink : AppColors.muted,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          SizedBox(
            width: 60,
            child: Text(
              "$percentage%",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: "serif",
                fontSize: 16,
                color: index == 0 ? AppColors.ink : AppColors.muted,
                fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // padding: EdgeInsets.only(left: 20, right: 20, top: 20),
      padding: EdgeInsets.only(left: 0, right: 0, top: 0),
      child: Column(
        children: [
          // 上传区域 - editorial style
          GestureDetector(
            onTap: _isUploading ? null : _showPickOptions,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: AppColors.ink, width: 1.5),
              ),
              child: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.contain)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: AppColors.ink,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "拍照 / 上传",
                          style: TextStyle(
                            fontFamily: "serif",
                            color: AppColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // 类别选择框 - inline editorial style
          if (_isUploading || _result != null)
            Container(
              margin: EdgeInsets.only(top: 24),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.hairline),
                  bottom: BorderSide(color: AppColors.hairline),
                ),
              ),
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isUploading) ...[
                    Text(
                      "识别中...",
                      style: TextStyle(
                        fontFamily: "serif",
                        fontSize: 18,
                        color: AppColors.muted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ink,
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: "识别类别   ",
                          style: TextStyle(
                            fontFamily: "serif",
                            fontSize: 16,
                            color: AppColors.muted,
                          ),
                          children: [
                            TextSpan(
                              text: _result ?? "未知",
                              style: TextStyle(
                                fontFamily: "serif",
                                fontSize: 20,
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: _result != null ? _showCategoryDetails : null,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (_selectedImage != null) ...[
            SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.hairline)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "诊断热力图",
                    style: TextStyle(
                      fontFamily: "serif",
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      if (_selectedImage != null)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              height: 140,
                            ),
                          ),
                        ),
                      if (_selectedImage != null &&
                          _heatmapData != null &&
                          _heatmapData!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.muted,
                          ),
                        ),
                      if (_heatmapData != null && _heatmapData!.isNotEmpty)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Image.memory(
                              base64Decode(_heatmapData!),
                              fit: BoxFit.cover,
                              height: 140,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 48),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "病害概率排行",
                    style: TextStyle(
                      fontFamily: "serif",
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 24),
                  if (_top5Classes != null && _predictTop5 != null)
                    Column(
                      children: List.generate(_top5Classes!.length, (index) {
                        return _buildProbabilityItem(
                          index,
                          _top5Classes![index],
                          _predictTop5![index],
                        );
                      }),
                    ),
                ],
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.canvas,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 0,
                ),
                onPressed: _result == null || _result!.trim().isEmpty
                    ? null
                    : () {
                        Navigator.pushNamed(
                          context,
                          "/analyze",
                          arguments: _result!.trim(),
                        );
                      },
                child: Text(
                  "详细分析报告",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
