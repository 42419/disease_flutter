import 'package:farm_flutter/pages/widgets/analyzePage/components/analyze_loading_widget.dart';
import 'package:farm_flutter/pages/widgets/analyzePage/components/analyze_result_widget.dart';
import 'package:farm_flutter/providers/disease_analyze_provider.dart';
import 'package:farm_flutter/providers/user_provider.dart';
import 'package:farm_flutter/providers/upload_provider.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DiseaseAnalyzeWidget extends StatefulWidget {
  final String initialDiseaseName;
  final ScrollController? scrollController;

  const DiseaseAnalyzeWidget({
    super.key,
    this.initialDiseaseName = '',
    this.scrollController,
  });

  @override
  State<DiseaseAnalyzeWidget> createState() => _DiseaseAnalyzeWidgetState();
}

class _DiseaseAnalyzeWidgetState extends State<DiseaseAnalyzeWidget> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _internalScrollController = ScrollController();

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _internalScrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<UserProvider>();
      final upload = context.read<UploadProvider>();
      final provider = context.read<DiseaseAnalyzeProvider>();
      if (widget.initialDiseaseName.isEmpty ||
          widget.initialDiseaseName == 'null') {
        provider.init(
          '',
          uploadImageName: upload.uploadImageName,
          nickName: user.nickName,
          amapAdcode: upload.amapAdcode,
        );
      } else {
        provider.init(
          widget.initialDiseaseName,
          uploadImageName: upload.uploadImageName,
          nickName: user.nickName,
          amapAdcode: upload.amapAdcode,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _internalScrollController.dispose();
    super.dispose();
  }

  void _submitInput() {
    final name = _inputController.text.trim();
    if (name.isEmpty) return;
    context.read<DiseaseAnalyzeProvider>().submitInput(name);
  }

  @override
  Widget build(BuildContext context) {
    final analyzeProvider = context.watch<DiseaseAnalyzeProvider>();

    if (analyzeProvider.showInput) return _buildInputWidget();

    if (analyzeProvider.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.danger,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                '分析失败',
                style: TextStyle(
                  fontFamily: "serif",
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                analyzeProvider.errorMessage ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => analyzeProvider.startAnalysis(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  foregroundColor: AppColors.canvas,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text(
                  '重试',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildMainCard(analyzeProvider)],
    );
  }

  Widget _buildInputWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '输入病害名称',
                    style: TextStyle(
                      fontFamily: "serif",
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '识别结果为空，请手动输入以模拟',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _inputController,
            autofocus: true,
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '例如：苹果黑斑病',
              hintStyle: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 15,
              ),
              filled: true,
              fillColor: AppColors.surfaceSoft,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: const BorderSide(color: AppColors.hairline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: const BorderSide(color: AppColors.hairline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2),
                borderSide: const BorderSide(
                  color: AppColors.inputBorderFocused,
                  width: 1.5,
                ),
              ),
            ),
            onSubmitted: (_) => _submitInput(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitInput,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.canvas,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text(
                '开始分析',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              '病因分析',
              style: TextStyle(
                fontFamily: "serif",
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '基于多维数据的智能推断',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainCard(DiseaseAnalyzeProvider analyzeProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: analyzeProvider.isLoading
                  ? KeyedSubtree(
                      key: const ValueKey('loading'),
                      child: AnalyzeLoadingWidget(
                        streamingTextNotifier: analyzeProvider.streamingTextNotifier,
                        scrollController: _effectiveScrollController,
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('result'),
                      child: AnalyzeResultWidget(
                        diseaseType: analyzeProvider.diseaseType,
                        causeAnalysis: analyzeProvider.causeAnalysis,
                        symptomCount: analyzeProvider.symptomCount,
                        displayedAnalysisNotifier: analyzeProvider.displayedAnalysisNotifier,
                        isTypingNotifier: analyzeProvider.isTypingNotifier,
                        displayedSuggestionsNotifier: analyzeProvider.displayedSuggestionsNotifier,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
