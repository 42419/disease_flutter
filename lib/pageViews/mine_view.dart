import 'package:farm_flutter/models/diagnosis.dart';
import 'package:farm_flutter/utils/api_config.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:farm_flutter/utils/http_util.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/global.dart';

class MineView extends StatefulWidget {
  const MineView({super.key});

  @override
  State<MineView> createState() => _MineViewState();
}

class _MineViewState extends State<MineView> with AutomaticKeepAliveClientMixin {
  int _diagnosisCount = 0;
  bool _statsLoading = true;

  int _uniqueCount = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDiagnosisCount();
  }

  Future<void> _loadDiagnosisCount() async {
    try {
      HttpUtil.init(baseUrl: ApiConfig.baseUrl);
      final resp = await HttpUtil.get(
        '/get_all_dg',
        headers: {'X-API-Token': ApiConfig.apiToken},
      );
      if (resp is Map && resp['data'] is List) {
        final records = (resp['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => Diagnosis.fromJson(e))
            .toList();
        final filtered = Global.user.role == '1'
            ? records
            : records.where((r) => r.username == Global.user.nickName).toList();

        filtered.sort((a, b) => b.dtime.compareTo(a.dtime));

        final countMap = <String, int>{};
        for (final r in filtered) {
          final name = r.bhname.isNotEmpty ? r.bhname : '未知';
          countMap[name] = (countMap[name] ?? 0) + 1;
        }

        if (!mounted) return;
        setState(() {
          _diagnosisCount = filtered.length;
          _uniqueCount = countMap.length;
          _statsLoading = false;
        });
      }
    } catch (e) {
      debugPrint("MineView _loadDiagnosisCount error: $e");
      if (!mounted) return;
      setState(() => _statsLoading = false);
    }
  }

  Widget _summaryItem(
    String value,
    String label,
    Color color, {
    bool isTime = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: isTime ? 13 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: isTime ? 1.3 : 1.0,
            ),
            textAlign: TextAlign.center,
            maxLines: isTime ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(width: 1, height: 40, color: AppColors.divider);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Padding(
        padding: EdgeInsets.all(33),
        child: ListView(
          children: [
            SizedBox(height: 100),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("跳转个人资料"),
                    duration: Duration(milliseconds: 500),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("跳转个人资料"),
                          duration: Duration(milliseconds: 500),
                          backgroundColor: AppColors.info,
                        ),
                      );
                    },
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                      padding: WidgetStateProperty.all(EdgeInsets.zero),
                      minimumSize: WidgetStateProperty.all(Size.zero),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      children: [
                        // SizedBox(width: 36),
                        Text(
                          Global.user.nickName,
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 13),
                        Icon(
                          Icons.arrow_forward_ios_outlined,
                          size: 16,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        Global.user.userAvatarUrl.isNotEmpty == true
                        ? NetworkImage(Global.user.userAvatarUrl)
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: (Global.user.userAvatarUrl.isEmpty)
                        ? Icon(Icons.person, size: 30, color: Colors.grey[600])
                        : null,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              width: double.infinity,
              child: Row(
                children: [
                  _summaryItem(
                    _statsLoading ? '...' : '$_diagnosisCount',
                    '诊断总数',
                    AppColors.info,
                  ),
                  _summaryDivider(),
                  _summaryItem(
                    _statsLoading ? '...' : '$_uniqueCount',
                    '病害种类',
                    AppColors.warning,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLightest.withAlpha(80),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      "诊断记录",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, "/diagnosis_records");
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
      bottomSheet: Container(
        color: AppColors.backgroundLight,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/login",
                  (context) => false,
                );
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool("remember_me", false);
                await prefs.remove("username");
                await prefs.remove("password");
                await prefs.remove("role");
              },
              child: Text("退出登录"),
            ),
          ),
        ),
      ),
    );
  }
}
