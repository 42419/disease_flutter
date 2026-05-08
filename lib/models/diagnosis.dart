class Diagnosis {
  final int id;
  final String imgname;
  final String bhname;
  final String bhreason;
  final String bhadvice;
  final String username;
  final String? location;
  final String dtime;

  Diagnosis({
    required this.id,
    required this.imgname,
    required this.bhname,
    required this.bhreason,
    required this.bhadvice,
    required this.username,
    this.location,
    required this.dtime,
  });

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      id: json['id'] ?? 0,
      imgname: json['imgname']?.toString() ?? '',
      bhname: json['bhname']?.toString() ?? '',
      bhreason: json['bhreason']?.toString() ?? '',
      bhadvice: json['bhadvice']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      location: json['location']?.toString(),
      dtime: json['dtime']?.toString() ?? '',
    );
  }

  String get formattedTime {
    DateTime? parsed;
    try {
      parsed = DateTime.parse(dtime);
    } catch (_) {
      // Try parsing RFC 1123 format like "Fri, 08 May 2026 15:47:30 GMT"
      final months = {'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12};
      final regex = RegExp(r'\w+,\s+(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})');
      final match = regex.firstMatch(dtime);
      if (match != null) {
        final day = int.tryParse(match.group(1)!) ?? 1;
        final month = months[match.group(2)!] ?? 1;
        final year = int.tryParse(match.group(3)!) ?? 2000;
        final hour = int.tryParse(match.group(4)!) ?? 0;
        final min = int.tryParse(match.group(5)!) ?? 0;
        final sec = int.tryParse(match.group(6)!) ?? 0;
        // The date is typically in GMT, convert if you need local time.
        // For simplicity, we create it in local or keep as is.
        parsed = DateTime(year, month, day, hour, min, sec);
      }
    }

    if (parsed != null) {
      return '${parsed.year.toString().padLeft(4, '0')}年${parsed.month.toString().padLeft(2, '0')}月${parsed.day.toString().padLeft(2, '0')}日 '
          '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}:${parsed.second.toString().padLeft(2, '0')}';
    } else {
      return dtime;
    }
  }
}
