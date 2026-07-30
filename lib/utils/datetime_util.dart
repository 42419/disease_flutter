/// 统一解析诊断记录时间字符串（ISO8601 / RFC1123 等）。
class DateTimeUtil {
  DateTimeUtil._();

  static const _months = {
    'Jan': 1,
    'Feb': 2,
    'Mar': 3,
    'Apr': 4,
    'May': 5,
    'Jun': 6,
    'Jul': 7,
    'Aug': 8,
    'Sep': 9,
    'Oct': 10,
    'Nov': 11,
    'Dec': 12,
  };

  static final _rfc1123 = RegExp(
    r'\w+,\s+(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})',
  );

  /// 尝试解析；失败返回 null。
  static DateTime? tryParse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    try {
      return DateTime.parse(text).toLocal();
    } catch (_) {
      // try RFC1123 below
    }

    final match = _rfc1123.firstMatch(text);
    if (match != null) {
      return DateTime.utc(
        int.tryParse(match.group(3)!) ?? 2000,
        _months[match.group(2)!] ?? 1,
        int.tryParse(match.group(1)!) ?? 1,
        int.tryParse(match.group(4)!) ?? 0,
        int.tryParse(match.group(5)!) ?? 0,
        int.tryParse(match.group(6)!) ?? 0,
      ).toLocal();
    }
    return null;
  }

  /// 解析失败时返回 [fallback]（默认本地 epoch）。
  static DateTime parseFlexible(String raw, {DateTime? fallback}) {
    return tryParse(raw) ?? fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// 格式化为 `yyyy年MM月dd日 HH:mm:ss`；无法解析时返回原文。
  static String formatChinese(String raw) {
    final parsed = tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.year.toString().padLeft(4, '0')}年'
        '${parsed.month.toString().padLeft(2, '0')}月'
        '${parsed.day.toString().padLeft(2, '0')}日 '
        '${parsed.hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')}:'
        '${parsed.second.toString().padLeft(2, '0')}';
  }
}
