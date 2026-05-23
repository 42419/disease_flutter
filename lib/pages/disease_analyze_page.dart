import 'package:farm_flutter/pages/widgets/analyzePage/disease_analyze_widget.dart';
import 'package:farm_flutter/pages/widgets/ai_analysis_card.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';

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
    final args = ModalRoute.of(context)?.settings.arguments?.toString() ?? '';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.ink,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '智能病因分析',
          style: TextStyle(
            fontFamily: "serif",
            fontSize: 22,
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: const PreferredSize(
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
