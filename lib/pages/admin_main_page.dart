import 'package:flutter/material.dart';
import 'package:farm_flutter/utils/app_colors.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("管理员主页"),
        centerTitle: true,
      ),
      body: const Center(
        child: Text("欢迎来到管理员控制台"),
      ),
    );
  }
}
