import 'package:farm_flutter/pages/disease_analyze_page.dart';
import 'package:flutter/material.dart';

import '../pages/login_page.dart';
import '../pages/main_page.dart';

Widget getRootWidget() {
  return MaterialApp(
    // initialRoute: "/login",
    initialRoute: "/",
    routes: _getRoutes(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
    ),
  );
}

Map<String, Widget Function(BuildContext)> _getRoutes() {
  return {
    "/login" : (context) => LoginPage(),
    "/" : (context) => MainPage(),
    "/analyze": (context) => DiseaseAnalyzePage(),
  };
}

