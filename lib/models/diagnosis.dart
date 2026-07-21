import 'package:farm_flutter/utils/datetime_util.dart';

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
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      imgname: json['imgname']?.toString() ?? '',
      bhname: json['bhname']?.toString() ?? '',
      bhreason: json['bhreason']?.toString() ?? '',
      bhadvice: json['bhadvice']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      location: json['location']?.toString(),
      dtime: json['dtime']?.toString() ?? '',
    );
  }

  String get formattedTime => DateTimeUtil.formatChinese(dtime);
}
