import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:farm_flutter/config/config.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:flutter/foundation.dart';

class DiseaseAnalyzeProvider extends ChangeNotifier {
  static const int _streamUiThrottleMs = 80;
  static const int _streamYieldEveryLines = 80;

  bool _disposed = false;
  CancelToken? _cancelToken;

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  String? _diseaseType;
  String? _causeAnalysis;
  int _symptomCount = 0;
  List<String>? _suggestions;

  bool _showInput = false;
  String _diseaseName = '';

  // 用于保存诊断记录的上下文信息
  String _uploadImageName = '';
  String _nickName = '';
  String _amapAdcode = '';

  final ValueNotifier<String> streamingTextNotifier = ValueNotifier('');
  final ValueNotifier<String> displayedAnalysisNotifier = ValueNotifier('');
  final ValueNotifier<List<String>> displayedSuggestionsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isTypingNotifier = ValueNotifier(false);

  Timer? _typewriterTimer;
  int _lastStreamUiUpdateMs = 0;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  String? get diseaseType => _diseaseType;
  String? get causeAnalysis => _causeAnalysis;
  int get symptomCount => _symptomCount;
  List<String>? get suggestions => _suggestions;
  bool get showInput => _showInput;
  String get diseaseName => _diseaseName;

  void init(
    String initialDiseaseName, {
    required String uploadImageName,
    required String nickName,
    required String amapAdcode,
  }) {
    _uploadImageName = uploadImageName;
    _nickName = nickName;
    _amapAdcode = amapAdcode;

    if (initialDiseaseName.isEmpty || initialDiseaseName == 'null') {
      _showInput = true;
      notifyListeners();
    } else {
      _diseaseName = initialDiseaseName;
      startAnalysis();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelToken?.cancel('disposed');
    _typewriterTimer?.cancel();
    streamingTextNotifier.dispose();
    displayedAnalysisNotifier.dispose();
    displayedSuggestionsNotifier.dispose();
    isTypingNotifier.dispose();
    super.dispose();
  }

  Future<void> startAnalysis() async {
    if (_disposed) return;
    _cancelToken?.cancel('restart');
    _cancelToken = CancelToken();
    _typewriterTimer?.cancel();

    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    _diseaseType = null;
    _causeAnalysis = null;
    _suggestions = null;
    notifyListeners();

    streamingTextNotifier.value = '';
    displayedAnalysisNotifier.value = '';
    displayedSuggestionsNotifier.value = [];
    isTypingNotifier.value = false;
    _lastStreamUiUpdateMs = 0;

    Dio? client;
    try {
      final (response, dioClient) = await HttpUtil.postStream(
        Config.cozeUrl,
        {
          'bot_id': Config.botId,
          'user_id': Config.userId,
          'stream': true,
          'additional_messages': [
            {'role': 'user', 'content': _diseaseName, 'content_type': 'text'},
          ],
        },
        headers: {'Authorization': Config.cozeToken},
        cancelToken: _cancelToken,
      );
      client = dioClient;

      if (_disposed) {
        client.close();
        return;
      }

      final stream = response.data!.stream;
      final deltaBuffer = StringBuffer();
      String currentEvent = '';
      int processedLines = 0;

      // Use utf8.decoder transform to correctly handle multi-byte characters
      // crossing chunk boundaries (e.g. Chinese characters split across SSE chunks).
      await for (final line in stream.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter())) {
        if (_disposed) return;
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed.startsWith('event:')) {
          currentEvent = trimmed.substring(6).trim();
        } else if (trimmed.startsWith('data:')) {
          final dataStr = trimmed.substring(5).trim();
          if (dataStr == '[DONE]') continue;
          try {
            final json = jsonDecode(dataStr) as Map<String, dynamic>;
            if (json['type'] == 'answer') {
              final content = json['content']?.toString() ?? '';
              if (currentEvent == 'conversation.message.delta') {
                deltaBuffer.write(content);
                _pushStreamingText(deltaBuffer.toString());
              }
            }
          } catch (_) {}
        }

        processedLines++;
        if (processedLines % _streamYieldEveryLines == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      if (_disposed) return;

      _pushStreamingText(deltaBuffer.toString(), force: true);

      final fullContent = deltaBuffer.toString();
      if (fullContent.isNotEmpty) {
        _parseResult(fullContent);
      } else {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '未收到有效内容，请检查 API 配置或网络连接';
        notifyListeners();
      }
    } on DioException catch (e) {
      if (_disposed) return;
      if (_cancelToken?.isCancelled == true) return;
      debugPrint('[DIO ERROR] ${e.type} | ${e.message} | ${e.response?.data}');
      _isLoading = false;
      _hasError = true;
      _errorMessage = '请求失败：${e.message ?? e.toString()}';
      notifyListeners();
    } catch (e) {
      if (_disposed) return;
      _isLoading = false;
      _hasError = true;
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      client?.close();
    }
  }

  void _pushStreamingText(String text, {bool force = false}) {
    if (_disposed) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!force && nowMs - _lastStreamUiUpdateMs < _streamUiThrottleMs) {
      return;
    }
    _lastStreamUiUpdateMs = nowMs;
    if (streamingTextNotifier.value != text) {
      streamingTextNotifier.value = text;
    }
  }

  void _parseResult(String rawContent) {
    if (_disposed) return;
    try {
      final start = rawContent.indexOf('{');
      final end = rawContent.lastIndexOf('}');
      if (start < 0 || end <= start) throw const FormatException('no json');
      final json =
          jsonDecode(rawContent.substring(start, end + 1))
              as Map<String, dynamic>;

      final diseaseType = json['病害类型']?.toString();
      final causeAnalysis = _buildCauseAnalysisFromJson(json);
      final suggestions = _buildSuggestionsFromJson(json);

      int symptomCount = 0;
      final symptomsJson = json['病害症状'];
      if (symptomsJson is Map && symptomsJson.isNotEmpty) {
        symptomCount = symptomsJson.length;
      }

      _diseaseType = diseaseType;
      _causeAnalysis = causeAnalysis;
      _symptomCount = symptomCount;
      _suggestions = suggestions;
      _isLoading = false;
      notifyListeners();

      isTypingNotifier.value = true;
      displayedAnalysisNotifier.value = '';
      displayedSuggestionsNotifier.value = [];

      _startTypewriterEffect();

      _savePredictionResult(json);
    } catch (_) {
      _causeAnalysis = rawContent;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _savePredictionResult(Map<String, dynamic> json) async {
    if (_disposed) return;
    try {
      final bhreason = (json['致病病原']?.toString().trim()) ?? '';

      final bhAdviceParts = <String>[];
      final methods = json['防治方法'];
      if (methods is Map) {
        methods.forEach((k, v) {
          final val = v?.toString().trim();
          if (val != null && val.isNotEmpty) bhAdviceParts.add('$k：$val');
        });
      }

      final payload = {
        'imgname': _uploadImageName,
        'bhname': _diseaseName,
        'bhreason': bhreason,
        'bhadvice': bhAdviceParts.join('\n'),
        'username': _nickName,
        'location': _amapAdcode,
        'dtime': _nowString(),
      };

      HttpUtil.init(baseUrl: Config.baseUrl);
      await HttpUtil.post(
        '/savepredict',
        payload,
        headers: {'X-API-Token': Config.apiToken},
      );
    } catch (e) {
      debugPrint('savepredict failed: $e');
    }
  }

  String _nowString() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')} '
        '${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}:${n.second.toString().padLeft(2, '0')}';
  }

  String? _buildCauseAnalysisFromJson(Map<String, dynamic> json) {
    final sections = <String>[];

    void addLine(String label, dynamic value) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        sections.add('$label：$text');
      }
    }

    addLine('致病病原', json['致病病原']);
    addLine('危害部位', json['危害部位']);

    final symptoms = json['病害症状'];
    if (symptoms is Map) {
      final symptomLines = <String>[];
      symptoms.forEach((key, value) {
        final label = key.toString().trim();
        final text = value?.toString().trim();
        if (label.isNotEmpty && text != null && text.isNotEmpty) {
          symptomLines.add('$label：$text');
        }
      });
      if (symptomLines.isNotEmpty) {
        sections.add('病害症状');
        sections.addAll(symptomLines);
      }
    }

    addLine('发病规律', json['发病规律']);

    if (sections.isEmpty) return null;
    return sections.join('\n');
  }

  List<String>? _buildSuggestionsFromJson(Map<String, dynamic> json) {
    final methods = json['防治方法'];
    if (methods is! Map) return null;

    final suggestions = <String>[];
    methods.forEach((key, value) {
      final label = key.toString().trim();
      final text = _sanitizeSuggestionText(value?.toString());
      if (label.isNotEmpty && text != null && text.isNotEmpty) {
        suggestions.add('$label：$text');
      }
    });

    return suggestions.isEmpty ? null : suggestions;
  }

  String? _sanitizeSuggestionText(String? text) {
    if (text == null) return null;

    var sanitized = text.trim();
    if (sanitized.startsWith('[') || sanitized.startsWith('［')) {
      sanitized = sanitized.substring(1).trimLeft();
    }
    if (sanitized.endsWith(']') || sanitized.endsWith('］')) {
      sanitized = sanitized.substring(0, sanitized.length - 1).trimRight();
    }
    return sanitized;
  }

  void _startTypewriterEffect() {
    _typewriterTimer?.cancel();

    if (_disposed) return;

    if (_causeAnalysis == null &&
        (_suggestions == null || _suggestions!.isEmpty)) {
      isTypingNotifier.value = false;
      return;
    }

    if (_causeAnalysis != null && _causeAnalysis!.isNotEmpty) {
      final chars = _causeAnalysis!.split('');
      int index = 0;
      final buffer = StringBuffer();

      _typewriterTimer = Timer.periodic(const Duration(milliseconds: 30), (
        timer,
      ) {
        if (_disposed) {
          timer.cancel();
          return;
        }
        for (int i = 0; i < 2 && index < chars.length; i++) {
          buffer.write(chars[index++]);
        }
        displayedAnalysisNotifier.value = buffer.toString();

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

    if (_disposed) return;

    if (_suggestions == null || _suggestions!.isEmpty) {
      isTypingNotifier.value = false;
      return;
    }

    int sugIndex = 0;

    void showNextSuggestion() {
      if (_disposed) return;
      if (sugIndex >= _suggestions!.length) {
        isTypingNotifier.value = false;
        return;
      }

      _typewriterTimer = Timer(const Duration(milliseconds: 200), () {
        if (_disposed) return;
        final chars = _suggestions![sugIndex].split('');
        int index = 0;
        final buffer = StringBuffer();

        _typewriterTimer = Timer.periodic(const Duration(milliseconds: 30), (
          timer,
        ) {
          if (_disposed) {
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
          displayedSuggestionsNotifier.value = list;

          if (index >= chars.length) {
            timer.cancel();
            sugIndex++;
            showNextSuggestion();
          }
        });
      });
    }

    showNextSuggestion();
  }

  void submitInput(String name) {
    if (name.isEmpty) return;
    _diseaseName = name;
    _showInput = false;
    notifyListeners();
    startAnalysis();
  }
}
