import 'package:farm_flutter/pages/app_init_page.dart';
import 'package:farm_flutter/pages/diagnosis_records_page.dart';
import 'package:farm_flutter/pages/disease_analyze_page.dart';
import 'package:farm_flutter/pages/register_page.dart';
import 'package:farm_flutter/providers/user_provider.dart';
import 'package:farm_flutter/providers/upload_provider.dart';
import 'package:farm_flutter/providers/diagnosis_records_provider.dart';
import 'package:farm_flutter/providers/disease_analyze_provider.dart';
import 'package:farm_flutter/providers/main_navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/login_page.dart';
import '../pages/main_page.dart';
import '../pages/admin_main_page.dart';

Widget getRootWidget() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => UploadProvider()),
      ChangeNotifierProvider(create: (_) => DiagnosisRecordsProvider()),
      ChangeNotifierProvider(create: (_) => DiseaseAnalyzeProvider()),
      ChangeNotifierProvider(create: (_) => MainNavigationProvider()),
    ],
    child: MaterialApp(
      initialRoute: "/admin_main",
      routes: _getRoutes(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
    ),
  );
}

Map<String, Widget Function(BuildContext)> _getRoutes() {
  return {
    "/init": (context) => const AppInitPage(),
    "/login" : (context) => const LoginPage(),
    "/registration": (context) => const RegisterPage(),
    "/main" : (context) => const MainPage(),
    "/admin_main": (context) => const AdminMainPage(),
    "/diagnosis_records": (context) => const DiagnosisRecordsPage(),
    "/analyze": (context) => const DiseaseAnalyzePage(),
  };
}
