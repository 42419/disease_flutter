import 'package:farm_flutter/models/prediction_result.dart';
import 'package:farm_flutter/providers/upload_provider.dart';
import 'package:farm_flutter/services/region_option_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:provider/provider.dart';

class UploadWidget extends StatefulWidget {
  const UploadWidget({super.key});

  @override
  State<UploadWidget> createState() => _UploadWidgetState();
}

class _UploadWidgetState extends State<UploadWidget> {
  void _showCategoryDetails(BuildContext context, String result) {
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
                  result,
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
                          Clipboard.setData(ClipboardData(text: result));
                          Navigator.pop(dialogContext);
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

  void _showPickOptions(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
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
                  Navigator.pop(sheetContext);
                  _pickAndUpload(parentContext, ImageSource.camera);
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
                  Navigator.pop(sheetContext);
                  _pickAndUpload(parentContext, ImageSource.gallery);
                },
              ),

              // 取消按钮
              Padding(
                padding: EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
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

  /// 选图 + 上传识别的业务逻辑都在 [UploadProvider] 里，这里只负责：
  /// 触发流程，并把"自动定位失败时如何弹出手动选地区 UI"这一小段界面逻辑
  /// 通过 [resolveManualRegion] 回调交给 Provider。
  Future<void> _pickAndUpload(BuildContext context, ImageSource source) async {
    final uploadProvider = context.read<UploadProvider>();
    await uploadProvider.pickAndUpload(
      source,
      resolveManualRegion: () {
        if (!context.mounted) return Future.value(null);
        return _pickRegionAdcode(context);
      },
    );
  }

  Future<String?> _pickRegionAdcode(BuildContext context) async {
    if (!context.mounted) return null;

    List<RegionOption> regions;
    try {
      regions = await const RegionOptionLoader().loadCurrentProvinceRegions();
    } catch (e) {
      debugPrint('加载手动地区列表失败: $e');
      return null;
    }

    if (!context.mounted || regions.isEmpty) return null;

    final selected = await showModalBottomSheet<RegionOption>(
      context: context,
      backgroundColor: AppColors.canvas,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    '选择诊断地区',
                    style: TextStyle(
                      fontFamily: "serif",
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppColors.hairline),
                Expanded(
                  child: ListView.separated(
                    itemCount: regions.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.hairline),
                    itemBuilder: (_, index) {
                      final region = regions[index];
                      return ListTile(
                        title: Text(
                          region.name,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          '${region.level.isEmpty ? '区域' : region.level} · ${region.adcode}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => Navigator.pop(sheetContext, region),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('暂不选择'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return selected?.adcode;
  }

  Widget _buildProbabilityItem(int index, String name, double percent) {
    final percentage = (percent * 100).toStringAsFixed(1);
    final widthFactor = percent.clamp(0.0, 1.0).toDouble();
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
                widthFactor: widthFactor,
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
    final uploadProvider = context.watch<UploadProvider>();
    final heatmapBytes = PredictionResult(
      result: uploadProvider.result ?? '',
      heatmapData: uploadProvider.heatmapData,
      top5Classes: const [],
      predictTop5: const [],
    ).tryDecodeHeatmap();
    final top5Classes = uploadProvider.top5Classes;
    final predictTop5 = uploadProvider.predictTop5;
    final probabilityCount = top5Classes == null || predictTop5 == null
        ? 0
        : PredictionResult(
            result: uploadProvider.result ?? '',
            heatmapData: null,
            top5Classes: top5Classes,
            predictTop5: predictTop5,
          ).displayCount;

    return Padding(
      padding: EdgeInsets.only(left: 0, right: 0, top: 0),
      child: Column(
        children: [
          // 上传区域 - editorial style
          GestureDetector(
            onTap: uploadProvider.isUploading ? null : () => _showPickOptions(context),
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: AppColors.ink, width: 1.5),
              ),
              child: uploadProvider.selectedImage != null
                  ? Image.file(uploadProvider.selectedImage!, fit: BoxFit.contain)
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
          if (uploadProvider.isUploading || uploadProvider.result != null || uploadProvider.errorMessage != null)
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
                  if (uploadProvider.isUploading) ...[
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
                  ] else if (uploadProvider.errorMessage != null) ...[
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: "识别失败   ",
                          style: TextStyle(
                            fontFamily: "serif",
                            fontSize: 16,
                            color: AppColors.danger,
                          ),
                          children: [
                            TextSpan(
                              text: uploadProvider.errorMessage!,
                              style: TextStyle(
                                fontFamily: "serif",
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                              text: uploadProvider.result ?? "未知",
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
                      onTap: uploadProvider.result != null
                          ? () => _showCategoryDetails(context, uploadProvider.result!)
                          : null,
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
          if (uploadProvider.selectedImage != null) ...[
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
                      if (uploadProvider.selectedImage != null)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: Image.file(
                              uploadProvider.selectedImage!,
                              fit: BoxFit.cover,
                              height: 140,
                            ),
                          ),
                        ),
                      if (uploadProvider.selectedImage != null &&
                          uploadProvider.heatmapData != null &&
                          uploadProvider.heatmapData!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.muted,
                          ),
                        ),
                      if (uploadProvider.heatmapData != null &&
                          uploadProvider.heatmapData!.isNotEmpty)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.hairline),
                            ),
                            child: heatmapBytes == null
                                ? const SizedBox(
                                    height: 140,
                                    child: Center(
                                      child: Text(
                                        '热力图数据异常',
                                        style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  )
                                : Image.memory(
                                    heatmapBytes,
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
                  if (top5Classes != null &&
                      predictTop5 != null &&
                      probabilityCount > 0)
                    Column(
                      children: List.generate(probabilityCount, (index) {
                        return _buildProbabilityItem(
                          index,
                          top5Classes[index],
                          predictTop5[index],
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
                onPressed: uploadProvider.result == null || uploadProvider.result!.trim().isEmpty
                    ? null
                    : () {
                        Navigator.pushNamed(
                          context,
                          "/analyze",
                          arguments: uploadProvider.result!.trim(),
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
