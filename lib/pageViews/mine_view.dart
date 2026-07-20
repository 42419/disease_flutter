import 'package:farm_flutter/providers/diagnosis_records_provider.dart';
import 'package:farm_flutter/providers/user_provider.dart';
import 'package:farm_flutter/providers/main_navigation_provider.dart';
import 'package:farm_flutter/services/auth_storage.dart';
import 'package:farm_flutter/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MineView extends StatefulWidget {
  const MineView({super.key});

  @override
  State<MineView> createState() => _MineViewState();
}

class _MineViewState extends State<MineView> with AutomaticKeepAliveClientMixin {
  final AuthStorage _authStorage = const AuthStorage();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchIfNeeded();
    });
  }

  void _fetchIfNeeded() {
    final recordsProvider = context.read<DiagnosisRecordsProvider>();
    final user = context.read<UserProvider>();
    if (recordsProvider.records.isEmpty && recordsProvider.isLoading) {
      recordsProvider.fetchRecords(role: user.role, nickName: user.nickName);
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
              fontFamily: "serif",
              fontSize: isTime ? 16 : 32,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              height: isTime ? 1.3 : 1.0,
            ),
            textAlign: TextAlign.center,
            maxLines: isTime ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: TextStyle(
              color: AppColors.muted, 
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(width: 1, height: 48, color: AppColors.hairline);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<UserProvider>();
    final recordsProvider = context.watch<DiagnosisRecordsProvider>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          '个人中心',
          style: TextStyle(
            fontFamily: "serif",
            fontSize: 28,
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 32,
        centerTitle: false,
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.hairline,
            height: 1.0,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. 第一版块：个人资料简介
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.canvas,
            ),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("跳转个人资料"),
                    duration: Duration(milliseconds: 500),
                    backgroundColor: AppColors.ink,
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.nickName,
                          style: TextStyle(
                            fontSize: 28,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.isAdmin ? '管理员' : '农户',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.hairline),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "编辑资料",
                            style: TextStyle(fontSize: 12, color: AppColors.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage:
                          user.userAvatarUrl.isNotEmpty
                          ? AssetImage(user.userAvatarUrl)
                          : null,
                      backgroundColor: AppColors.surfaceCard,
                      child: (user.userAvatarUrl.isEmpty)
                          ? Icon(Icons.person, size: 36, color: AppColors.muted)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 2. 第二版块：数据概览区（使用柔和底色区隔）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              border: Border(
                top: BorderSide(color: AppColors.ink, width: 1.5),
                bottom: BorderSide(color: AppColors.hairline),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "数据概览",
                  style: TextStyle(
                    fontFamily: "serif",
                    fontSize: 20,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "您参与的所有病害分析与历史记录概况。",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _summaryItem(
                      recordsProvider.isLoading ? '...' : '${recordsProvider.records.length}',
                      '诊断总记录数',
                      AppColors.ink,
                    ),
                    _summaryDivider(),
                    _summaryItem(
                      recordsProvider.isLoading ? '...' : '${recordsProvider.stats.length}',
                      '已识别病害种类',
                      AppColors.ink,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 3. 第三版块：系统与偏好
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "系统设置",
                  style: TextStyle(
                    fontFamily: "serif",
                    fontSize: 20,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppColors.hairline),
                      bottom: BorderSide(color: AppColors.hairline),
                    ),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                        title: Text(
                          "诊断历史存档",
                          style: TextStyle(
                            fontFamily: "serif",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: AppColors.ink,
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, "/diagnosis_records");
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.canvas,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: () async {
                      await _authStorage.clearCredentials();
                      if (!mounted) return;
                      context.read<UserProvider>().clear();
                      context.read<MainNavigationProvider>().setCurrentIndex(0);
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        "/login",
                        (context) => false,
                      );
                    },
                    child: Text(
                      "退出当前账号",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
