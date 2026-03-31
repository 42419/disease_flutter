import 'dart:ui' show ImageFilter;
import 'package:farm_flutter/pageViews/widgets/farm_news.dart';
import 'package:farm_flutter/pageViews/widgets/function_cards.dart';
import 'package:farm_flutter/pageViews/widgets/upload_widget.dart';
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
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(height: 70 + MediaQuery.of(context).padding.top),
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
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ===== AppBar =====
          SizedBox(
            height: 70 + MediaQuery.of(context).padding.top,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 底层：轻微模糊（最下方，模糊度最低）
                _buildBlurLayer(
                  sigma: 2,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.transparent, Colors.white],
                    stops: [0.0, 0.35],
                  ),
                ),
                // 中下层：中等模糊
                _buildBlurLayer(
                  sigma: 6,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.transparent, Colors.white],
                    stops: [0.2, 0.6],
                  ),
                ),
                // 中上层：较强模糊
                _buildBlurLayer(
                  sigma: 12,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.transparent, Colors.white],
                    stops: [0.4, 0.8],
                  ),
                ),
                // 顶层：强模糊（最上方，模糊度最高）
                _buildBlurLayer(
                  sigma: 20,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.transparent, Colors.white],
                    stops: [0.6, 1.0],
                  ),
                ),

                // // 底部细线，增加层次感
                // Positioned(
                //   bottom: 0,
                //   left: 0,
                //   right: 0,
                //   child: Container(
                //     height: 0.5,
                //     color: Colors.black.withOpacity(0.08),
                //   ),
                // ),
                Positioned(
                  left: 20,
                  bottom: 16,
                  child: Text(
                    "病理分析",
                    style: TextStyle(
                      fontSize: 23,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建单层模糊效果
  ///
  /// [sigma] 模糊半径
  /// [gradient] 控制该层模糊的可见区域（白色可见，透明不可见）
  Widget _buildBlurLayer({
    required double sigma,
    required LinearGradient gradient,
  }) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          blendMode: BlendMode.srcOver,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
