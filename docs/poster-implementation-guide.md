# 慧田良方 — 海报技术实现详解

> **项目名称**：慧田良方（Wisdom Farm Remedy）
> **项目定位**：基于细粒度图像识别和智能体的农作物病害智能精准问诊系统
> **文档用途**：对照项目海报的每一个板块，详细说明其在代码中的具体实现方式、对应文件和关键代码片段。

---

## 📑 目录

| 章节 | 内容 |
|------|------|
| [01 创意说明](#01-创意说明) | 背景与痛点 → 解决思路 → 开发框架 |
| [02 关键创新点](#02-关键创新点) | CV+智能体协同 → GIS 地理态势 → 位置绑定 |
| [03 系统逻辑架构](#03-系统逻辑架构) | 四层架构 + 数据流闭环 |
| [04 核心功能展示](#04-核心功能展示移动端) | 5 个页面截图的代码实现 |
| [05 GIS 病害态势可视化](#05-gis-病害态势可视化) | 数据流水线 + 四大功能 |
| [06 成果影响](#06-成果影响) | 农户/管理部门/技术可扩展 |
| [07 数据模型](#07-数据模型) | Diagnosis 模型 + Coze JSON |
| [08 技术栈](#08-技术栈) | 7 项核心技术对应 |

---

## 01 创意说明

### 1.1 背景与痛点

> 海报原文："诊断滞后：错过最佳防治时机 | 知识断层：基层农技人员短缺 | 信息孤岛：数据分散、难以统筹 | 响应缓慢：获取建议耗时长、成本高"

| 痛点 | 海报描述 | 代码实现 | 关键文件 |
|------|---------|---------|---------|
| 诊断滞后 | 错过最佳防治时机 | 选图后立即自动上传，识别结果秒级返回 | `upload_widget.dart:313` |
| 知识断层 | 基层农技人员短缺 | Coze 智能体自动生成病因、症状、防治方案 | `disease_analyze_widget.dart:99` |
| 信息孤岛 | 数据分散、难以统筹 | 所有诊断记录通过 `/get_all_dg` 集中存储 | `diagnosis_records_page.dart:48` |
| 响应缓慢 | 获取建议耗时长 | SSE 流式推送（80ms 节流），实时看到 AI 输出 | `disease_analyze_widget.dart:181` |

### 1.2 解决思路

> 海报流程图：**拍照上传 → AI 识别 → 智能问诊 → GIS 态势感知**

代码中是四个独立模块，按数据流串联：

**第一步：拍照上传**

```dart
// upload_widget.dart:300 — ImagePicker 拍照/选图
Future<void> _pickImage(ImageSource source) async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
  if (pickedFile != null) {
    // ... 自动调用 _uploadImage()
  }
}
```

**第二步：AI 识别**

```dart
// upload_widget.dart:332 — multipart 图片上传到后端 CV 模型
final response = await HttpUtil.postFile(
  "/predict",
  [_selectedImage!.path],
  headers: headers,
  fileField: "image",
);
// 返回 top5class（Top-5 类别名）、predicttop5（Top-5 置信度）、heatmap（热力图 base64）
```

**第三步：智能问诊**

```dart
// disease_analyze_widget.dart:99 — Coze SSE 流式对话
final response = await HttpUtil.postStream(
  ApiConfig.cozeUrl,
  {
    'bot_id': ApiConfig.botId,
    'user_id': ApiConfig.userId,
    'stream': true,
    'additional_messages': [
      {'role': 'user', 'content': _diseaseName, 'content_type': 'text'},
    ],
  },
  headers: {'Authorization': ApiConfig.cozeToken},
);
```

**第四步：GIS 态势感知**

```dart
// admin_map_view.dart — flutter_map + GeoJSON 渲染河南省地图
_loadGeoJson();      // 加载市/区县两套 GeoJSON
_fetchDiseaseData(); // 从后端拉取诊断数据，按 adcode 匹配着色
```

### 1.3 开发框架与目标用户

> 海报列出：**PyTorch + Coze + Flutter + Flask**

| 技术 | 代码对应 | 文件 |
|------|---------|------|
| PyTorch | 后端 CV 模型训练（前端通过 `/predict` 接口调用） | 后端服务 |
| Coze | 调用扣子智能体 API 进行语义分析 | `disease_analyze_widget.dart:100` |
| Flutter | 整个 `lib/` 目录，跨平台移动端 | `pubspec.yaml` |
| Flask | 后端 REST API（通过 cpolar 隧道暴露） | 后端服务 |

目标用户"农户 + 农业管理部门"体现为**双角色路由分发**：

```dart
// login_page.dart:144 — 根据 role 跳转不同页面
if (Global.user.role == "1") {
  Navigator.pushNamedAndRemoveUntil(context, "/admin_main", (route) => false);
} else {
  Navigator.pushNamedAndRemoveUntil(context, "/main", (route) => false);
}
```

> 农户进 `/main`（MainPage），管理员进 `/admin_main`（AdminMainPage），两个完全独立的 UI 体系。

---

## 02 关键创新点

### 2.1 CV + 智能体协同诊断

> 海报三步流程：**CV 视觉识别 → 智能体问诊 → 结构化输出**

#### 第一步：CV 识别（前端发请求，后端推理）

```dart
// upload_widget.dart:332
final response = await HttpUtil.postFile(
  "/predict",
  [_selectedImage!.path],
  headers: headers,
  fileField: "image",
);
```

后端返回三个关键字段：

```dart
// upload_widget.dart:340-352
_successValue = response['top5class'][0]?.toString();  // Top-1 病害名
_heatmapData = response['heatmap']?.toString();         // 热力图 base64
_top5Classes = List<String>.from(response["top5class"]); // Top-5 类别名
_predictTop5 = List<double>.from(response["predicttop5"]); // Top-5 置信度
```

热力图（GradCAM 等注意力机制的可视化）以 base64 解码展示：

```dart
// upload_widget.dart:631
Image.memory(base64Decode(_heatmapData!), fit: BoxFit.cover)
```

#### 第二步：Coze 智能体分析

> 海报原文："基于 CV 的精确诊断类别作为关键提示词"

`_diseaseName` 就是 CV 模型的 Top-1 结果，直接作为 Coze 的输入 prompt。Coze 返回的结构化 JSON 包含海报中提到的所有字段：

```json
{
  "病害类型": "苹果黑斑病",
  "致病病原": "链格孢菌 (Alternaria alternata)",
  "危害部位": "叶片、果实",
  "病害症状": {
    "初期": "叶片出现圆形或不规则褐色小斑点",
    "中期": "病斑扩大呈同心轮纹，边缘紫褐色",
    "后期": "病斑联合导致叶片枯焦脱落"
  },
  "发病规律": "高温高湿环境易发病，6-8 月为发病高峰，借风雨传播",
  "防治方法": {
    "农业防治": "合理修剪通风透光，清除病残体减少菌源",
    "化学防治": "发病初期喷洒代森锰锌或吡唑醚菌酯，间隔 7-10 天"
  }
}
```

解析逻辑在 `disease_analyze_widget.dart:206-245`：

```dart
void _parseResult(String rawContent) {
  final start = rawContent.indexOf('{');
  final end = rawContent.lastIndexOf('}');
  final json = jsonDecode(rawContent.substring(start, end + 1)) as Map<String, dynamic>;

  final diseaseType = json['病害类型']?.toString();
  final causeAnalysis = _buildCauseAnalysisFromJson(json);
  final suggestions = _buildSuggestionsFromJson(json);
  // ...
}
```

### 2.2 GIS 病害态势感知地图

> 海报五个子项：双层行政区划渲染 / 数据驱动着色 / 点击区域查看统计 / 宏观→微观 / 科学决策

| 海报功能 | 代码实现 | 文件位置 |
|----------|---------|---------|
| 双层行政区划渲染（市/区县） | 加载两份 GeoJSON，`_showDistrictLayer` 控制图层切换 | `admin_map_view.dart:22-26` |
| 数据驱动着色、高亮预警 | `_regionFillColor()` 根据病害数据强度渐变着色 | `admin_map_view.dart:173-199` |
| 点击区域查看病害统计 | `_getDiseaseSummary()` 汇总该区域病害柱状图 | `admin_map_view.dart:221-236` |
| 宏观态势 → 微观详情 | 缩放阈值 8.1 / 9.6 自动切换图层 | `admin_map_view.dart:26-27` |
| 助力管理部门科学决策 | 地图着色 + 柱状图统计 = 区域病害分布全貌 | 全局实现 |

着色逻辑核心代码：

```dart
// admin_map_view.dart:173-199
Color _regionFillColor({
  required bool hasGeoData,
  required bool hasData,
  required bool isSelected,
  required double severityRatio,
}) {
  // 无病害：绿色；有病害：按强度从浅红到深红渐变
  if (hasGeoData && !hasData) {
    return isSelected
        ? AppColors.success.withValues(alpha: 0.46)
        : AppColors.success.withValues(alpha: 0.30);
  }
  final baseRed = Color.lerp(
    AppColors.error.withValues(alpha: 0.24),
    AppColors.error.withValues(alpha: 0.68),
    severityRatio,
  )!;
  return isSelected
      ? Color.lerp(baseRed, AppColors.error.withValues(alpha: 0.82), 0.35)!
      : baseRed;
}
```

### 2.3 诊断数据与地理位置绑定

> 海报原文："GPS 定位 + 逆地理编码（高德 API）绑定 adcode 行政区划编码"

```dart
// upload_widget.dart:363-401 — _fetchAdcode()
// 1. 获取 GPS 坐标
final position = await Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 10),
  ),
);

// 2. 调用高德逆地理编码 API
final resp = await HttpUtil.get(
  '/v3/geocode/regeo?key=${ApiConfig.amapKey}&location=${position.longitude},${position.latitude}',
  baseUrl: ApiConfig.amapBaseUrl,
);

// 3. 提取 adcode 存入全局状态
Global.amapAdcode = resp['regeocode']['addressComponent']['adcode'].toString();
```

保存诊断记录时绑定：

```dart
// disease_analyze_widget.dart:260-267
final payload = {
  'imgname': Global.uploadImageName,
  'bhname': _diseaseName,
  'bhreason': bhreason,
  'bhadvice': bhAdviceParts.join('\n'),
  'username': Global.user.nickName,
  'location': Global.amapAdcode,   // ← 绑定行政区划码
  'dtime': _nowString(),
};
```

---

## 03 系统逻辑架构

> 海报四层架构：**用户层 → Flutter 前端 → 服务层 → 数据层**

| 架构层 | 海报内容 | 代码目录 |
|--------|---------|---------|
| **用户层** | 农户移动端 + 管理员移动端 | `pages/main_page.dart` + `pages/admin_main_page.dart` |
| **Flutter 前端** | 图像采集 / 识别结果 / AI 分析 / 诊断记录 / 地图大屏 / 个人中心 | `pageViews/` 下各 View 文件 |
| **服务层** | 后端 Flask API / Coze 智能体 / 高德地图 API / CV 视觉模型 | `utils/http_util.dart` + `utils/api_config.dart` |
| **数据层** | 诊断记录数据库 / 河南省 GeoJSON / shared_preferences | `assets/geojson/` + `utils/global.dart` |

> 海报底部的**数据流闭环**：**拍照 → 识别 → 分析 → 存储 → 地图可视化 → 决策支持**

```
拍照 → ImagePicker → 上传 → POST /predict → 识别结果
                            → POST /savepredict → 存入数据库
                                    ↓
                    GPS → 高德 API → adcode → 绑定到诊断记录
                                    ↓
                    GET /get_all_dg → 拉取全部记录
                                    ↓
                    GeoJSON 匹配 adcode → 地图着色 → 决策支持
```

---

## 04 核心功能展示（移动端）

> 海报展示 5 个手机截图，每个对应一个具体页面。

### 截图 1：登录页

> 海报描述："简洁登录，角色选择"

| UI 元素 | 代码位置 |
|---------|---------|
| Logo 图片 | `login_page.dart:207` `Image.asset("assets/img/logo.png")` |
| 衬线体大标题 "Sign in to continue." | `login_page.dart:214` |
| 用户名下划线输入框 | `login_page.dart:244` |
| 密码下划线输入框 | `login_page.dart:260` |
| 角色下拉选择器（农户/管理员） | `login_page.dart:278` |
| 零圆角黑色登录按钮 | `login_page.dart:398` |
| 记住密码勾选 | `login_page.dart:310` |
| 用户协议勾选 | `login_page.dart:334` |
| 自动登录（记住密码时） | `login_page.dart:31` `_loadSavedData()` |

### 截图 2：病害识别页

> 海报描述："上传图片后 Top-5 病害结果 + 热力图"

| UI 元素 | 代码位置 |
|---------|---------|
| 黑色边框上传容器（180px 高） | `upload_widget.dart:479` |
| 拍照/相册选择底部面板 | `upload_widget.dart:139` `_showPickOptions()` |
| 识别结果行 "识别类别 — XX病" | `upload_widget.dart:547` |
| Top-5 概率排行进度条 | `upload_widget.dart:404` |
| 原图与热力图对比展示 | `upload_widget.dart:610` |
| "详细分析报告"按钮 | `upload_widget.dart:679` |

### 截图 3：AI 分析报告页

> 海报描述："流式生成分析，结构化防治建议，重点高亮"

| UI 元素 | 代码位置 |
|---------|---------|
| SSE 流式文本实时推送 | `disease_analyze_widget.dart:99-147` |
| JSON 解析为结构化字段 | `disease_analyze_widget.dart:206-245` |
| 打字机逐字动画展示 | `disease_analyze_widget.dart:353-442` |
| 关键病害信息自动高亮 | `highlight_utils.dart` |
| 防治建议独立卡片展示 | `suggestion_item.dart` |

### 截图 4：诊断记录页

> 海报描述："柱状图分析，历史记录可查"

| UI 元素 | 代码位置 |
|---------|---------|
| fl_chart 柱状图按病害分组统计 | `diagnosis_records_page.dart:341` |
| 记录列表含严重程度徽章（高危/中等/轻微） | `diagnosis_records_page.dart:687-732` |
| 角色权限过滤（农户只看自己的） | `diagnosis_records_page.dart:40-46` |
| 下拉刷新 | `diagnosis_records_page.dart:268` |

### 截图 5：地图态势页

> 海报描述："GIS 区域着色，点击查看统计"

| UI 元素 | 代码位置 |
|---------|---------|
| OpenStreetMap 底图 + flutter_map | `admin_map_view.dart:40` |
| GeoJSON 渲染河南省市/区县多边形 | `admin_map_view.dart:84-107` |
| 数据驱动着色 | `admin_map_view.dart:109-146` |
| 缩放自动切换图层（阈值 8.1 / 9.6） | `admin_map_view.dart:26-27` |
| 点击区域弹出病害统计柱状图 | `admin_map_view.dart:221-236` |

---

## 05 GIS 病害态势可视化

> 海报数据处理流水线：**诊断数据(含 adcode) → adcode 绑定 → GeoJSON 区域映射 → 病害热区生成**

代码中 `_fetchDiseaseData()` 的实现（`admin_map_view.dart:109-146`）：

```dart
Future<void> _fetchDiseaseData() async {
  // 1. 从后端拉取全部诊断记录（含 location 即 adcode）
  final resp = await HttpUtil.get('/get_all_dg', ...);

  // 2. 按 adcode 统计每个区域的病害数量和类型
  for (final item in dataList) {
    final loc = item['location']?.toString().trim();
    final name = item['bhname']?.toString().trim();
    _dataAdcodes.add(loc);
    tempStats.putIfAbsent(loc, () => {});
    tempStats[loc]!.update(name, (c) => c + 1, ifAbsent: () => 1);
  }

  // 3. 由区县级 adcode 推导市级 adcode
  for (final adcode in _dataAdcodes) {
    if (adcode.length == 6 && !adcode.endsWith('00')) {
      _cityCodesWithDistrictData.add('${adcode.substring(0, 4)}00');
    }
  }
}
```

海报底部四个子项的代码对应：

| 功能 | 实现方式 | 文件位置 |
|------|---------|---------|
| 双层级切换（市级/区县级） | `_showDistrictLayer` 根据缩放自动切换 | `admin_map_view.dart:26-27` |
| 区域高亮风险预警 | `_regionFillColor()` 按病害数据强度渐变着色 | `admin_map_view.dart:173` |
| 点击区域展示统计详情 | 点击多边形弹出该区域病害柱状统计图 | `admin_map_view.dart:221-236` |
| 病害趋势科学决策 | 地图着色 + 柱状图 = 区域病害分布全貌 | 全局实现 |

---

## 06 成果影响

> 海报分三栏：对农户 / 对农业管理部门 / 技术可扩展

### 对农户

| 效果 | 代码支撑 |
|------|---------|
| 降低病害识别门槛 | 拍照上传 → 自动识别，无需专业知识（`upload_widget.dart`） |
| 缩短诊断时间 | 上传 + AI 分析全链路 3-5 秒（`disease_analyze_widget.dart` SSE 流式） |
| 减少农药滥用 | AI 给出精准用药建议，不用盲目喷药（`suggestion_item.dart`） |
| 提高种植效益 | 及时发现 + 精准防治 = 降低损失 |

### 对农业管理部门

| 效果 | 代码支撑 |
|------|---------|
| 区域病害可视化 | `admin_map_view.dart` 地图着色 |
| 辅助农业决策 | 柱状图统计各区域高频病害 |
| 病害风险预警 | 地图上预警色区域一眼可见 |
| 降低人工巡检成本 | 农户自主上报替代人工巡检 |

### 技术可扩展

| 效果 | 代码支撑 |
|------|---------|
| 多作物/多省份扩展 | 替换 GeoJSON 文件即可适配其他省份（`assets/geojson/`） |
| 多大模型接入 | `api_config.dart` 中替换 Coze 配置即可对接其他模型 |
| Android/iOS 多端 | Flutter 跨平台，一套代码双端发布 |
| API 易于集成 | `http_util.dart` 封装标准 REST 接口 |

---

## 07 数据模型

### 诊断记录模型

> 海报列出 7 个字段，逐个对应 `models/diagnosis.dart`：

| 海报字段 | 说明 | 代码位置 |
|----------|------|---------|
| `id` | 唯一标识 | `diagnosis.dart:6` `final int id;` |
| `imgname` | 图片文件名 | `diagnosis.dart:7` `final String imgname;` |
| `bhname` | 病害名称（CV 结果） | `diagnosis.dart:8` `final String bhname;` |
| `bhreason` | 致病病原（AI 分析） | `diagnosis.dart:9` `final String bhreason;` |
| `bhadvice` | 防治建议（AI 分析） | `diagnosis.dart:10` `final String bhadvice;` |
| `username` | 用户名 | `diagnosis.dart:11` `final String username;` |
| `location` | 行政区划编码 | `diagnosis.dart:12` `final String? location;` |
| `dtime` | 诊断时间 | `diagnosis.dart:13` `final String dtime;` |

### Coze 智能体输出 JSON

> 海报展示了 JSON 示例，对应 `disease_analyze_widget.dart:211-216` 中的解析：

```dart
final diseaseType = json['病害类型']?.toString();
final causeAnalysis = _buildCauseAnalysisFromJson(json);
final suggestions = _buildSuggestionsFromJson(json);
```

> 海报中 `病害症状` 字段包含"初期/中期/后期"三个子项，在代码中以 Map 类型处理：

```dart
final symptomsJson = json['病害症状'];
if (symptomsJson is Map && symptomsJson.isNotEmpty) {
  symptomCount = symptomsJson.length;
}
```

---

## 08 技术栈

> 海报底部列出 7 项核心技术：

| 海报技术 | 代码对应 | 关键文件 |
|----------|---------|---------|
| CV 细粒度图像识别 | 后端 PyTorch 模型，前端通过 `/predict` 调用 | `upload_widget.dart` |
| 病害知识库智能体问诊 | 对接 Coze API，Coze 智能体内置病害知识库 | `disease_analyze_widget.dart` |
| Flutter 跨平台开发 | 整个 `lib/` 目录 | `pubspec.yaml` |
| fl_chart 数据可视化 | 诊断记录柱状图 + 地图区域统计图 | `diagnosis_records_page.dart` |
| flutter_map 地图渲染 | OpenStreetMap 底图 + GeoJSON 多边形渲染 | `admin_map_view.dart` |
| geolocator 定位服务 | GPS 坐标获取 + 高德逆地理编码 | `upload_widget.dart:378` |
| MySQL 存储 | 后端数据库，通过 REST API 接口间接交互 | 后端服务 |

---

## 总结：海报与代码的映射关系

> 整张海报的设计逻辑是**从问题到方案到架构到效果**的递进结构，代码中恰好也有对应的数据流闭环：

| 海报板块 | 核心对应代码 |
|---------|-------------|
| 01 创意说明 | `login_page.dart` + `main_page.dart` 角色分发 |
| 02 创新点 | `upload_widget.dart` + `disease_analyze_widget.dart` + `admin_map_view.dart` |
| 03 架构 | `routes/` `pageViews/` `pages/` `utils/` `models/` 分层 |
| 04 功能展示 | 5 个核心页面的具体实现 |
| 05 GIS | `admin_map_view.dart` GeoJSON + adcode 匹配 |
| 06 影响 | 各模块的功能闭环 |
| 07 数据模型 | `models/diagnosis.dart` + Coze JSON 解析 |
| 08 技术栈 | `pubspec.yaml` 的 7 个核心依赖 |
