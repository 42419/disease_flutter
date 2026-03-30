import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:farm_flutter/utils/app_colors.dart';

class UploadWidget extends StatefulWidget {
  const UploadWidget({super.key});

  @override
  State<UploadWidget> createState() => _UploadWidgetState();
}

class _UploadWidgetState extends State<UploadWidget> {
  File? _selectedImage;
  bool _isUploading = false;
  String? _result;

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
                color: Colors.black.withOpacity(0.08),
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
                  color: AppColors.textTertiary.withOpacity(0.3),
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
              
              Divider(
                color: AppColors.divider,
                height: 1,
              ),
              
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
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: AppColors.white,
                size: 26,
              ),
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
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("请先选择一张图片"),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(_selectedImage!.path),
      });
      final response = await dio.post(
        "http://192.168.0.178:8080/api/upload",
        data: formData,
      );

      if (mounted) {
        setState(() {
          _isUploading = false;
          _result = response.data.toString();
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      // padding: EdgeInsets.only(left: 20, right: 20, top: 20),
      padding: EdgeInsets.only(left: 0, right: 0, top: 0),
      child: SizedBox(
        height: 240,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 上传区域 - 完整圆角，完整边框
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: _isUploading ? null : _showPickOptions,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.uploadAreaBackground,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12)),
                    border: Border.all(color: AppColors.uploadAreaBorder, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12)),
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
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
            ),
            // 类别选择框 - 悬浮在右下角外侧，与上传框有轻微重叠
            Positioned(
              right: 0,
              bottom: -2,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                  border: Border.all(color: AppColors.uploadAreaBorder, width: 1.5),
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
                    Text(
                      "类别：${_result ?? "请上传图片"}",
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
