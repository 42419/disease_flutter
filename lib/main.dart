import 'package:farm_flutter/routes/route.dart';
import 'package:farm_flutter/config/config.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  HttpUtil.init(baseUrl: Config.baseUrl);
  runApp(getRootWidget());
}