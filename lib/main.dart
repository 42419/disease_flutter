import 'dart:io';

import 'package:farm_flutter/routes/route.dart';
import 'package:farm_flutter/config/config.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpUtil.init(baseUrl: Config.baseUrl);
  await _enableHighRefreshRate();
  runApp(getRootWidget());
}

/// 主动向系统申请设备支持的最高刷新率（如 90/120Hz）。
///
/// Android 默认不会自动把 App 切到高刷新率模式，很多国产 ROM 还会在系统层
/// 再叠加一套"高刷新率应用"白名单：只有主动发起过请求的 App，才会被系统归入
/// "跟随应用内设置"下的高刷档位，否则一律按最低档（通常 60Hz）渲染。
///
/// [flutter_displaymode] 只支持 Android（iOS 的 ProMotion 由系统自动管理，
/// 不需要、也不支持这个 API），所以这里加了平台判断；同时用 try-catch 兜底，
/// 避免个别设备/模拟器不支持这套 Display Mode API 时影响应用正常启动——
/// 申请失败最多是退回默认刷新率，不应该阻塞启动流程。
Future<void> _enableHighRefreshRate() async {
  if (!Platform.isAndroid) return;
  try {
    await FlutterDisplayMode.setHighRefreshRate();
  } catch (e) {
    debugPrint('设置高刷新率失败，将使用系统默认刷新率: $e');
  }
}
