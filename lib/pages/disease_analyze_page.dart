import 'package:farm_flutter/pages/widgets/analyzePage/disease_analyze_widget.dart';
import 'package:farm_flutter/pages/widgets/ai_analysis_card.dart';
import 'package:farm_flutter/providers/disease_analyze_provider.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farm_flutter/providers/theme_mode_provider.dart';

class DiseaseAnalyzePage extends StatefulWidget {
  const DiseaseAnalyzePage({super.key});

  @override
  State<DiseaseAnalyzePage> createState() => _DiseaseAnalyzePageState();
}

class _DiseaseAnalyzePageState extends State<DiseaseAnalyzePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeModeController>(); // 深色模式切换时用于触发本页面重建
    var args = ModalRoute.of(context)?.settings.arguments?.toString() ?? '';
    if (args == 'null') args = '';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.ink,
          ),
          onPressed: () {
            // 离开分析页时取消进行中的 SSE 请求和打字机动画
            if (context.mounted) {
              context.read<DiseaseAnalyzeProvider>().cancelPendingRequest();
            }
            Navigator.pop(context);
          },
        ),
        title: Text(
          '智能病因分析',
          style: TextStyle(
            fontFamily: "serif",
            fontSize: 22,
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, color: AppColors.hairline),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (args.isNotEmpty) AiAnalysisCard(diseaseName: args),
            if (args.isNotEmpty) const SizedBox(height: 24),
            DiseaseAnalyzeWidget(
              initialDiseaseName: args,
              scrollController: _scrollController,
            ),
          ],
        ),
      ),
    );
  }
}
