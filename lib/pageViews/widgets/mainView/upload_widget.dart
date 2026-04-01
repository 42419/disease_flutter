import 'dart:convert';
import 'dart:io';

import 'package:farm_flutter/utils/api_config.dart';
import 'package:flutter/material.dart';
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

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部指示器
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 标题
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  "选择图片",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              Divider(color: AppColors.divider, height: 1),

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
                color: AppColors.divider,
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
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "取消",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // 图标容器
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.white, size: 26),
            ),
            SizedBox(width: 16),

            // 文字部分
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 箭头图标
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 24,
            ),
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

    try {
      HttpUtil.baseUrl = ApiConfig.apiUrl;

      final headers = {"X-API-Token": ApiConfig.apiToken};

      final response = await HttpUtil.postFile(
        "/predict",
        [_selectedImage!.path],
        headers: headers,
        fileField: "image",
      );
      print(response);

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
          print(e);
        });
      }
    }
  }

  Widget _getCardTitle(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        SizedBox(width: 15),
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildProbabilityItem(int index, String name, double percent) {
    final percentage = (percent * 100).toStringAsFixed(2);
    final progressWidth = percentage * 220;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: index == 0 ? AppColors.primary : AppColors.plantSubHealthy,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "${index + 1}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              name,
              style: TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 130,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.primaryLightest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: percent,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: index == 0
                      ? AppColors.primary
                      : AppColors.plantSubHealthy,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 60,
            child: Text(
              "$percentage %",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
          // 上传区域 - 完整圆角，完整边框
          GestureDetector(
            onTap: _isUploading ? null : _showPickOptions,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.uploadAreaBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                border: Border.all(color: AppColors.uploadAreaBorder, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: _selectedImage != null
                    ? Image.file(_selectedImage!, fit: BoxFit.contain)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 50,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "拍照上传",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // 类别选择框 - 悬浮在右下角外侧，与上传框底部对齐
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              // margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(
                  color: AppColors.uploadAreaBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUploading) ...[
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      "识别中...",
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ] else ...[
                    Text.rich(
                      TextSpan(
                        text: "类别：",
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: _result ?? "请上传图片",
                            style: _result != null
                                ? TextStyle(
                                    fontSize: 17,
                                    color: AppColors.danger,
                                  )
                                : TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textSecondary,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_selectedImage != null) ...[
            SizedBox(height: 30),
            Container(
              height: 200,
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _getCardTitle("智能诊断分析"),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      if (_selectedImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ),
                        ),
                      if (_selectedImage != null &&
                          _heatmapData != null &&
                          _heatmapData!.isNotEmpty)
                        Expanded(child: Icon(Icons.arrow_forward_ios)),
                      if (_heatmapData != null && _heatmapData!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(_heatmapData!),
                            fit: BoxFit.cover,
                            width: 120,
                            height: 120,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Container(
              height: 340,
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _getCardTitle("诊断结果"),
                  Padding(
                    padding: EdgeInsets.only(left: 22, top: 5),
                    child: Text(
                      "病害概率 TOP5",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(height: 15),
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
          ],
        ],
      ),
    );
  }
}
