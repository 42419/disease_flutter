import 'package:flutter/material.dart';

class DiseaseAnalyzePage extends StatefulWidget {
  const DiseaseAnalyzePage({super.key});

  @override
  State<DiseaseAnalyzePage> createState() => _DiseaseAnalyzePageState();
}

class _DiseaseAnalyzePageState extends State<DiseaseAnalyzePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("病理分析"),
    );
  }
}
