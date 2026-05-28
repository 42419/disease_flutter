import 'package:farm_flutter/pages/app_init_page.dart';
import 'package:farm_flutter/pages/diagnosis_records_page.dart';
import 'package:farm_flutter/pages/disease_analyze_page.dart';
import 'package:farm_flutter/pages/register_page.dart';
import 'package:flutter/material.dart';

import '../pages/login_page.dart';
import '../pages/main_page.dart';
import '../pages/admin_main_page.dart';

Widget getRootWidget() {
  return MaterialApp(
    initialRoute: "/init",
    routes: _getRoutes(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
    ),
  );
}

Map<String, Widget Function(BuildContext)> _getRoutes() {
  return {
    "/init": (context) => AppInitPage(),
    "/login" : (context) => LoginPage(),
    "/registration": (context) => RegisterPage(),
    "/main" : (context) => MainPage(),
    "/admin_main": (context) => AdminMainPage(),
    "/diagnosis_records": (context) => DiagnosisRecordsPage(),
    "/analyze": (context) => DiseaseAnalyzePage(),
  };
}

