import 'dart:async';

/// 通用的"按固定间隔轮询、且只在数据过期时才真正触发"的控制器。
///
/// 从 [DiagnosisRecordsProvider] 里拆出来：原先 Timer 的启动/停止、
/// App 前后台切换联动、过期判断这几段逻辑和"记录列表/排序/统计"数据
/// 本身混在一个 Provider 里，职责偏重。拆成独立的 [PollingController]
/// 之后，Provider 只需要在 [onDue] 回调里发起一次真正的数据请求，
/// 计时器生命周期完全交给本类管理，也方便脱离 Provider 单独复用/测试。
class PollingController {
  PollingController({
    required this.interval,
    required this.staleThreshold,
    required this.onDue,
  });

  /// 轮询间隔。
  final Duration interval;

  /// 数据过期阈值：距上次成功拉取超过这个时长视为过期。
  final Duration staleThreshold;

  /// 轮询到期、且数据已过期时触发的回调，调用方在这里发起真正的请求。
  final void Function() onDue;

  Timer? _timer;
  DateTime? _lastFetchTime;

  /// 数据是否已过期。
  bool get isStale =>
      _lastFetchTime == null ||
      DateTime.now().difference(_lastFetchTime!) > staleThreshold;

  /// 标记一次成功的数据拉取，重置过期计时（拉取成功后调用）。
  void markFetched() {
    _lastFetchTime = DateTime.now();
  }

  /// 启动定时轮询。重复调用是安全的，会先取消旧的 Timer。
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      if (isStale) onDue();
    });
  }

  /// 停止定时轮询（例如 App 切到后台时调用）。
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// 立即检查一次（例如 App 恢复前台时调用），仅在数据过期时触发 [onDue]。
  void refreshIfStale() {
    if (isStale) onDue();
  }

  /// 停止轮询并清空过期计时（例如退出登录、清空数据时调用）。
  void reset() {
    stop();
    _lastFetchTime = null;
  }

  void dispose() {
    stop();
  }
}
