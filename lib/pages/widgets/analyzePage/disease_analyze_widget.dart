import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:farm_flutter/pages/widgets/analyzePage/components/analyze_loading_widget.dart';
import 'package:farm_flutter/pages/widgets/analyzePage/components/analyze_result_widget.dart';
import 'package:farm_flutter/utils/api_config.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:flutter/material.dart';

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
  static const int _streamUiThrottleMs = 80;
  static const int _streamYieldEveryLines = 80;

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  String? _diseaseType;
  String? _causeAnalysis;
  List<String>? _suggestions;

  bool _showInput = false;
  late String _diseaseName;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _internalScrollController = ScrollController();

  ScrollController get _effectiveScrollController => widget.scrollController ?? _internalScrollController;

  final ValueNotifier<String> _streamingTextNotifier = ValueNotifier('');
  final ValueNotifier<String> _displayedAnalysisNotifier = ValueNotifier('');
  final ValueNotifier<List<String>> _displayedSuggestionsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isTypingNotifier = ValueNotifier(false);

  Timer? _typewriterTimer;
  int _lastStreamUiUpdateMs = 0;
  bool _outerScrollScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDiseaseName.isEmpty || widget.initialDiseaseName == 'null') {
      _showInput = true;
    } else {
      _diseaseName = widget.initialDiseaseName;
      _startAnalysis();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _internalScrollController.dispose();
    _typewriterTimer?.cancel();
    _streamingTextNotifier.dispose();
    _displayedAnalysisNotifier.dispose();
    _displayedSuggestionsNotifier.dispose();
    _isTypingNotifier.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _diseaseType = null;
      _causeAnalysis = null;
      _suggestions = null;
    });
    _streamingTextNotifier.value = '';
    _displayedAnalysisNotifier.value = '';
    _displayedSuggestionsNotifier.value = [];
    _isTypingNotifier.value = false;
    _lastStreamUiUpdateMs = 0;

    try {
      final response = await HttpUtil.postStream(
        ApiConfig.cozeUrl,
        {
          'bot_id': ApiConfig.botId,
          'user_id': ApiConfig.userId,
          'stream': true,
          'additional_messages': [
            {
              'role': 'user',
              'content': _diseaseName,
              'content_type': 'text',
            },
          ],
        },
        headers: {
          'Authorization': ApiConfig.cozeToken,
        },
      );

      final stream = response.data!.stream;
      final deltaBuffer = StringBuffer();
      String? completedContent;
      String lineBuffer = '';
      String currentEvent = '';
      int processedLines = 0;

      await for (final chunk in stream) {
        lineBuffer += utf8.decode(chunk, allowMalformed: true);
        while (lineBuffer.contains('\n')) {
          final idx = lineBuffer.indexOf('\n');
          final line = lineBuffer.substring(0, idx).trim();
          lineBuffer = lineBuffer.substring(idx + 1);

          if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            final dataStr = line.substring(5).trim();
            if (dataStr == '[DONE]') continue;
            try {
              final json = jsonDecode(dataStr) as Map<String, dynamic>;
              if (json['type'] == 'answer') {
                final content = json['content']?.toString() ?? '';
                if (currentEvent == 'conversation.message.delta') {
                  deltaBuffer.write(content);
                  _pushStreamingText(deltaBuffer.toString());
                } else if (currentEvent == 'conversation.message.completed') {
                  completedContent = content;
                }
              }
            } catch (_) {}
          }

          processedLines++;
          if (processedLines % _streamYieldEveryLines == 0) {
            await Future<void>.delayed(Duration.zero);
          }
        }
      }

      _pushStreamingText(deltaBuffer.toString(), force: true);

      final fullContent = completedContent ?? deltaBuffer.toString();
      if (fullContent.isNotEmpty) {
        _parseResult(fullContent);
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '未收到有效内容，请检查 API 配置或网络连接';
        });
      }
    } on DioException catch (e) {
      debugPrint('[DIO ERROR] ${e.type} | ${e.message} | ${e.response?.data}');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '请求失败：${e.message ?? e.toString()}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _pushStreamingText(String text, {bool force = false}) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force && nowMs - _lastStreamUiUpdateMs < _streamUiThrottleMs) {
      return;
    }
    _lastStreamUiUpdateMs = nowMs;
    if (_streamingTextNotifier.value != text) {
      _streamingTextNotifier.value = text;
    }
    _scheduleOuterScrollToBottom();
  }

  void _scheduleOuterScrollToBottom() {
    if (_outerScrollScheduled) return;
    _outerScrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _outerScrollScheduled = false;
      if (!mounted || !_effectiveScrollController.hasClients) return;
      try {
        final position = _effectiveScrollController.position;
        _effectiveScrollController.jumpTo(position.maxScrollExtent);
      } catch (_) {}
    });
  }

  void _parseResult(String rawContent) {
    try {
      final start = rawContent.indexOf('{');
      final end = rawContent.lastIndexOf('}');
      if (start < 0 || end <= start) throw const FormatException('no json');
      final json =
          jsonDecode(rawContent.substring(start, end + 1))
              as Map<String, dynamic>;

      final diseaseType = json['病害类型']?.toString();
      final causeAnalysis = json['病因分析']?.toString();
      final suggRaw = json['防治建议'];
      final suggestions =
          suggRaw is List ? List<String>.from(suggRaw) : null;

      setState(() {
        _diseaseType = diseaseType;
        _causeAnalysis = causeAnalysis;
        _suggestions = suggestions;
        _isLoading = false;
      });
      _isTypingNotifier.value = true;
      _displayedAnalysisNotifier.value = '';
      _displayedSuggestionsNotifier.value = [];

      _startTypewriterEffect();
    } catch (_) {
      setState(() {
        _causeAnalysis = rawContent;
        _isLoading = false;
      });
    }
  }

  void _startTypewriterEffect() {
    _typewriterTimer?.cancel();

    if (_causeAnalysis == null &&
        (_suggestions == null || _suggestions!.isEmpty)) {
      _isTypingNotifier.value = false;
      return;
    }

    if (_causeAnalysis != null && _causeAnalysis!.isNotEmpty) {
      final chars = _causeAnalysis!.split('');
      int index = 0;
      final buffer = StringBuffer();

      _typewriterTimer =
          Timer.periodic(const Duration(milliseconds: 30), (timer) {
            if (!mounted) {
              timer.cancel();
              return;
            }
            for (int i = 0; i < 2 && index < chars.length; i++) {
              buffer.write(chars[index++]);
            }
            _displayedAnalysisNotifier.value = buffer.toString();

            if (index >= chars.length) {
              timer.cancel();
              _typewriterTimer = Timer(
                const Duration(milliseconds: 300),
                () => _startSuggestionTypewriter(),
              );
            }
          });
    } else {
      _startSuggestionTypewriter();
    }
  }

  void _startSuggestionTypewriter() {
    _typewriterTimer?.cancel();

    if (_suggestions == null || _suggestions!.isEmpty) {
      _isTypingNotifier.value = false;
      return;
    }

    int sugIndex = 0;

    void showNextSuggestion() {
      if (!mounted || sugIndex >= _suggestions!.length) {
        _isTypingNotifier.value = false;
        return;
      }

      _typewriterTimer = Timer(
        const Duration(milliseconds: 200),
        () {
          if (!mounted) return;

          final chars = _suggestions![sugIndex].split('');
          int index = 0;
          final buffer = StringBuffer();

          _typewriterTimer =
              Timer.periodic(const Duration(milliseconds: 30), (timer) {
                if (!mounted) {
                  timer.cancel();
                  return;
                }
                for (int i = 0; i < 2 && index < chars.length; i++) {
                  buffer.write(chars[index++]);
                }
                final list = List<String>.filled(_suggestions!.length, '');
                for (int j = 0; j < sugIndex; j++) {
                  list[j] = _suggestions![j];
                }
                list[sugIndex] = buffer.toString();
                _displayedSuggestionsNotifier.value = list;

                if (index >= chars.length) {
                  timer.cancel();
                  sugIndex++;
                  showNextSuggestion();
                }
              });
        },
      );
    }

    showNextSuggestion();
  }

  void _submitInput() {
    final name = _inputController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _diseaseName = name;
      _showInput = false;
    });
    _startAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    if (_showInput) return _buildInputWidget();

    if (_hasError) {
      return Center(
        child: Padding(
          // padding: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(0),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '重试',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildMainCard()],
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
                children: [
                  const Text(
                    '输入病害名称',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
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
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '例如：苹果黑斑病',
              hintStyle: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 15,
              ),
              filled: true,
              fillColor: AppColors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
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
            height: 50,
            child: ElevatedButton(
              onPressed: _submitInput,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                '开始分析',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '基于多维数据的智能推断',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
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
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _isLoading
                  ? KeyedSubtree(
                      key: const ValueKey('loading'),
                      child: AnalyzeLoadingWidget(
                        streamingTextNotifier: _streamingTextNotifier,
                        scrollController: _effectiveScrollController,
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey('result'),
                      child: AnalyzeResultWidget(
                        diseaseType: _diseaseType,
                        causeAnalysis: _causeAnalysis,
                        displayedAnalysisNotifier: _displayedAnalysisNotifier,
                        isTypingNotifier: _isTypingNotifier,
                        displayedSuggestionsNotifier:
                            _displayedSuggestionsNotifier,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

