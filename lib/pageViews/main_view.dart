import 'package:farm_flutter/pageViews/widgets/mainView/farm_news.dart';
import 'package:farm_flutter/pageViews/widgets/mainView/function_cards.dart';
import 'package:farm_flutter/pageViews/widgets/mainView/upload_widget.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  bool _hasImageSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          '病理分析',
          style: TextStyle(
            fontSize: 23,
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        titleSpacing: 20,
        centerTitle: false,
        backgroundColor: AppColors.backgroundLight,
        // scrolledUnderElevation: 0,
        surfaceTintColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                children: [
                  UploadWidget(
                    onImageSelected: () {
                      setState(() {
                        _hasImageSelected = true;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  if (!_hasImageSelected) ...[
                    FunctionCards(),
                    const SizedBox(height: 30),
                    FarmNews(),
                  ] else ...[

                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
