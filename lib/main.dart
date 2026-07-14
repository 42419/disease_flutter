import 'package:farm_flutter/routes/route.dart';
import 'package:farm_flutter/config/config.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:flutter/material.dart';

void main() {
  HttpUtil.init(baseUrl: Config.baseUrl);
  runApp(getRootWidget());
}