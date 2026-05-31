# 🚫 项目铁律（所有AI修改代码前必读）

> **违反以下规则的代码会被拒绝合并或回滚。请在修改任何文件前完整阅读本文档。**

---

## 📋 目录

1. [存储路径](#1--存储路径只用公共目录)
2. [主题颜色](#2--主题颜色必须接入-skintheme)
3. [签名配置](#3--签名配置固定使用-github-secrets)
4. [添加智能体](#4--添加新智能体-agent)
5. [Widget基类](#5--flutter-widget-基类规范)
6. [对话框/弹窗颜色](#6--对话框弹窗颜色必须跟随主题)
7. [路由导航](#7--路由导航)
8. [ProGuard规则](#8--proguard-规则)
9. [CI/CD构建](#9--cicd-构建规则)
10. [依赖管理](#10--依赖管理)
11. [Android权限](#11--android-权限管理)
12. [安全存储](#12--安全存储api-key-用-secure-storage)
13. [代码生成](#13--代码生成freezed--json_serializable)
14. [Skill/技能系统](#14--添加写作技能-skill)
15. [记忆系统](#15--记忆系统)
16. [常见踩坑汇总](#16--常见踩坑汇总)
17. [提交前检查清单](#17--提交前检查清单)

---

## 1. 📂 存储路径：只用公共目录

**❌ 禁止使用：**
```dart
import 'package:path_provider/path_provider.dart';
getExternalStorageDirectory()       // 会拿到 Android/data/{包名}/
getApplicationDocumentsDirectory()  // 会拿到 /data/data/{包名}/
getDatabasesPath()                  // 会拿到 /data/data/{包名}/databases/
```

**✅ 必须使用：**
```dart
import 'package:novel_ide/data/datasources/public_storage_helper.dart';

// 所有存储路径统一管理：
PublicStorageHelper.publicRoot   // /storage/emulated/0/NovelIDE/
PublicStorageHelper.projectsDir  // /storage/emulated/0/NovelIDE/作品区/
PublicStorageHelper.materialsDir // /storage/emulated/0/NovelIDE/资料区/
PublicStorageHelper.memoryDir    // /storage/emulated/0/NovelIDE/记忆包/
PublicStorageHelper.skillDir     // /storage/emulated/0/NovelIDE/Skill/
PublicStorageHelper.agentDir     // /storage/emulated/0/NovelIDE/Agent/
PublicStorageHelper.backupDir    // /storage/emulated/0/NovelIDE/备份/
PublicStorageHelper.configFile   // /storage/emulated/0/NovelIDE/app_config.json
```

**原因：** 应用专属目录（`Android/data/{包名}/`）卸载会丢失用户数据。公共目录 `/storage/emulated/0/NovelIDE/` 卸载后数据保留。

**注意：** `path_provider` 包保留在 `pubspec.yaml` 中（Hive 等底层依赖需要），但**业务代码禁止直接调用**，必须通过 `PublicStorageHelper`。

---

## 2. 🎨 主题颜色：必须接入 SkinTheme

**❌ 禁止：**
```dart
// 在 Widget/页面中硬编码颜色
const bgColor = Color(0xFF000000);
static const primaryColor = Color(0xFF10A37F);
final cardBg = Color(0xFF1A1A1A);
```

**✅ 必须：**
```dart
import 'package:novel_ide/core/theme/skin_provider.dart';

// 方式一：在 build() 中读取（适合 ConsumerStatefulWidget / ConsumerWidget）
final skin = ref.watch(skinThemeProvider);
final bgColor = skin.background;        // 背景色
final cardBg = skin.surface;            // 卡片表面
final cardBg2 = skin.cardBg;            // 次级卡片
final primaryColor = skin.primary;      // 主题强调色
final textPrimary = skin.textPrimary;   // 主文字
final textSecondary = skin.textSecondary; // 次文字
final isDark = skin.brightness == Brightness.dark;

// 方式二：通过 Theme.of(context) 读取 Material 颜色
final colorScheme = Theme.of(context).colorScheme;
colorScheme.primary      // 主色
colorScheme.surface      // 表面
colorScheme.onSurface    // 表面上的文字
```

**SkinTheme 可用字段：**

| 字段 | 含义 | 示例（黑色主题） | 示例（白色主题） |
|------|------|-----------------|-----------------|
| `background` | 页面背景 | `#000000` | `#F5F5F7` |
| `surface` | 卡片/面板背景 | `#1A1A1A` | `#FFFFFF` |
| `cardBg` | 次级卡片背景 | `#1F1F1F` | `#FFFFFF` |
| `primary` | 主题强调色 | `#10A37F` | `#6B4EFF` |
| `textPrimary` | 主文字 | `#FFFFFF` | `#1A1A2E` |
| `textSecondary` | 次文字/描述 | `#888888` | `#8E8E93` |
| `brightness` | 亮暗判断 | `Brightness.dark` | `Brightness.light` |

**8种主题皮肤：** 白色、黑色、蓝色护眼、黄色暖光、绿色清新、粉色、日系木色、红色热情（定义在 `core/theme/app_themes.dart`）

**可硬编码颜色的例外：**
- ✅ 章节状态徽章（草稿/润色/已完成等语义色）：`Color(0xFFFFC107)` 黄色=草稿 等
- ✅ 错误/警告/成功色：`Colors.red`、`Colors.green` 等语义色
- ✅ 纯装饰性小元素（拖拽指示条等）可保留暗色系常量
- ❌ **所有页面背景、卡片背景、文字颜色、强调色必须用主题**

**⚠️ 关键提醒：如果子方法需要访问颜色，用实例变量（`late Color _xxx`）在 `build()` 中赋值，不要用 `static const`。**

---

## 3. ✍️ 签名配置：固定使用 GitHub Secrets

**签名由 CI 自动注入，不要本地硬编码：**

```yaml
# .github/workflows/build.yml 中读取：
secrets.KEYSTORE_BASE64    # keystore 文件的 base64 编码
secrets.KEYSTORE_PASSWORD  # keystore 密码
secrets.KEY_ALIAS          # 密钥别名
secrets.KEY_PASSWORD       # 密钥密码
```

**`android/app/build.gradle` 的签名逻辑：**
```groovy
// 有 key.properties → 用正式签名（CI 环境）
// 没有 key.properties → 用 debug 签名（本地开发）
if (keystoreProperties['storePassword'] != null) {
    signingConfig = signingConfigs.release
} else {
    signingConfig = signingConfigs.debug
}
```

**❌ 不要在 build.gradle 中硬编码签名路径或密码。**
**❌ 不要把 keystore 文件提交到仓库。**

**签名不匹配问题：** GitHub Actions 构建的 APK 用的是 secrets 中的 keystore，和本地开发签名不同。用户需要**卸载旧版再安装**才能更新。

---

## 4. 📦 添加新智能体（Agent）

**文件：** `lib/presentation/state/app_providers.dart` → `tomatoAgentsProvider` 列表

```dart
TomatoAgent(
  id: 'your_agent_id',       // 唯一ID，下划线命名
  name: '显示名称',
  icon: '🎯',                // emoji 图标
  description: '一句话功能描述',
  systemPrompt: '''完整系统提示词''',
  parameterPrompts: ['参数提示1', '参数提示2'],
),
```

**如果需要在AI工具菜单（🧠按钮）中显示：**
还需修改 `main_shell.dart` 的 `_showAiToolsMenu()` 方法，添加 `_buildAiToolMenuItem` 入口。

**如果智能体需要独立运行页面：**
参考 `agent_marketplace_page.dart` 中的 `AgentRunPage` 类，通过参数化 `TomatoAgent` 对象启动。

---

## 5. 🏗️ Flutter Widget 基类规范

| 场景 | 继承 | 说明 |
|------|------|------|
| 有状态页面，需要读 Riverpod | `ConsumerStatefulWidget` | **不要用** `StatefulWidget` |
| 无状态组件，需要读 Riverpod | `ConsumerWidget` | **不要用** `StatelessWidget` |
| 纯 UI 组件，不读状态 | `StatelessWidget` / `StatefulWidget` | 可以用原生 |

```dart
// ✅ 正确
class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});
  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

// ❌ 错误 - 无法使用 ref.watch / ref.read
class MyPage extends StatefulWidget { ... }
```

---

## 6. 🔲 对话框/弹窗颜色必须跟随主题

**❌ 禁止：**
```dart
showDialog(
  builder: (ctx) => AlertDialog(
    backgroundColor: const Color(0xFF1A1A1A),  // 硬编码黑色
    title: Text('标题', style: TextStyle(color: Colors.white)), // 硬编码白色
```

**✅ 必须：**
```dart
final skin = ref.read(skinThemeProvider);  // 或从 build 的 skin 变量传递
showDialog(
  builder: (ctx) => AlertDialog(
    backgroundColor: skin.surface,
    title: Text('标题', style: TextStyle(color: skin.textPrimary)),
```

**同理适用于：** `showModalBottomSheet`、`SnackBar`、`TopNotification`、自定义弹窗。

**💡 提示：** 如果弹窗在方法中（如 `_showDeleteNovelConfirm`），颜色变量从 `build()` 传递给方法参数，或者在方法内重新 `ref.read(skinThemeProvider)` 获取。

---

## 7. 🧭 路由导航

**命名路由（简单跳转）：**
```dart
Navigator.pushNamed(context, AppRouter.editor, arguments: {'novelId': id, 'chapterId': cid});
```

**直接导航（需要传复杂参数）：**
```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => ExportPage(novelId: novel.id, novelTitle: novel.title),
));
```

**路由定义在：** `lib/core/router.dart`

**可用路由名：**
- `/` → MainShell（首页）
- `/editor` → EditorPage（参数：novelId, chapterId）
- `/rich-editor` → RichEditorPage
- `/agents` → AgentMarketplacePage
- `/global-search` → GlobalSearchPage
- `/outline` → OutlinePage
- `/proofread` → ProofreadPage
- `/full-text-review` → FullTextReviewPage
- `/export` → ExportPage
- `/materials` → MaterialsTreePage
- `/stats` → StatsPage
- `/profile` → ProfilePage

**新增页面时：** 必须在 `router.dart` 中添加路由定义。

---

## 8. 🛡️ ProGuard 规则

**文件：** `android/app/proguard-rules.pro`

**添加新依赖（尤其是原生插件）时：**
必须检查是否需要在 `proguard-rules.pro` 中添加 keep 规则，否则 Release 包可能崩溃或白屏。

```proguard
# 示例：添加新插件的 keep 规则
-keep class com.example.new_plugin.** { *; }
```

**已配置的插件规则（不需要重复添加）：**
Flutter、Hive、Riverpod、permission_handler、file_picker、share_plus、path_provider、flutter_secure_storage、sqflite、shared_preferences、url_launcher、speech_to_text、local_notifications、WebView、Dio

---

## 9. 🔧 CI/CD 构建规则

**文件：** `.github/workflows/build.yml`

**关键配置：**
- Flutter 版本：**3.32.0**（固定，不要随意升级）
- 构建命令：`flutter build apk --release`
- 自动发布：push 到 master 时自动创建 Release 并上传 APK

**❌ 不要：**
- 随意修改 Flutter 版本号
- 在构建步骤中添加需要交互的命令
- 手动删除 Release 中的旧 APK（会和并发构建冲突）

**常见构建失败原因：**
1. 缺少 `import`（如 `debugPrint` 需要 `import 'package:flutter/foundation.dart'`）
2. ProGuard 规则缺失（新增原生插件未添加 keep 规则）
3. Auto Release 并发冲突（两个 push 几乎同时触发，非代码问题）

---

## 10. 📦 依赖管理

**文件：** `pubspec.yaml`

**当前环境：**
- Dart SDK: `>=3.8.0 <4.0.0`
- Flutter: `3.32.0`

**添加新依赖前：**
1. 确认该依赖是否已有替代（如网络用 Dio，不要加 http）
2. 检查版本兼容性
3. 添加后必须在 `proguard-rules.pro` 中添加对应原生 keep 规则（如有原生代码）

**核心依赖速查：**

| 用途 | 包名 |
|------|------|
| 状态管理 | `flutter_riverpod` |
| 数据库 | `sqflite` |
| 键值存储 | `hive` + `hive_flutter` |
| 安全存储 | `flutter_secure_storage` |
| 网络请求 | `dio` |
| 文件选择 | `file_picker` |
| 权限管理 | `permission_handler` |
| 语音识别 | `speech_to_text` |
| 通知 | `flutter_local_notifications` |
| 图表 | `fl_chart` |
| 代码生成 | `freezed` + `json_serializable` + `build_runner` |

---

## 11. 📱 Android 权限管理

**文件：** `android/app/src/main/AndroidManifest.xml`

**已声明的权限（不要重复添加）：**
- INTERNET、ACCESS_NETWORK_STATE、ACCESS_WIFI_STATE
- RECORD_AUDIO（语音输入）
- POST_NOTIFICATIONS（通知）
- READ/WRITE_EXTERNAL_STORAGE（存储）
- MANAGE_EXTERNAL_STORAGE（Android 11+ 全文件管理）
- READ_MEDIA_IMAGES/VIDEO/AUDIO（Android 13+）
- FOREGROUND_SERVICE（前台服务）
- WAKE_LOCK、REQUEST_IGNORE_BATTERY_OPTIMIZATIONS（后台运行）
- VIBRATE、MODIFY_AUDIO_SETTINGS
- BLUETOOTH / BLUETOOTH_CONNECT（蓝牙耳机）

**添加新权限时：** 必须同步在 `main.dart` 的权限请求逻辑中添加运行时请求（如需要）。

---

## 12. 🔐 安全存储（API Key 用 Secure Storage）

**API Key 存储方式：** `flutter_secure_storage`
```dart
import 'package:novel_ide/data/datasources/secure_storage_datasource.dart';
final secureStorage = SecureStorageDataSource();
await secureStorage.saveApiKey(configId, apiKey);
final key = await secureStorage.readApiKey(configId);
```

**❌ 不要用 `SharedPreferences` 存储 API Key。**
**❌ 不要把 API Key 写死在代码里。**

**配置持久化：** `lib/data/services/config_service.dart`（使用 Hive）

---

## 13. 🔄 代码生成（freezed / json_serializable）

**运行命令：**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**何时需要运行：**
- 修改了带有 `@freezed`、`@JsonSerializable` 注解的 model 类
- CI 中已自动运行（`build.yml` 中有 `build_runner build` 步骤）

**❌ 不要手动编辑 `*.g.dart` 或 `*.freezed.dart` 文件。**

---

## 14. 📚 添加写作技能（Skill）

**Skill 文件存储位置：** `/storage/emulated/0/NovelIDE/Skill/`

**Skill 数据模型：** `lib/data/models/writing_skill_model.dart`

**Skill 仓库：** `lib/data/repositories/skill_repository.dart`

**Skill 匹配引擎：** `lib/data/services/skill_matcher.dart`（根据用户输入自动匹配相关 Skill）

---

## 15. 🧠 记忆系统

**两种记忆：**

| 类型 | 类 | 用途 | 存储路径 |
|------|-----|------|---------|
| 小说记忆 | `NovelMemory` | 每部小说的状态（角色、大纲、进度） | `/storage/emulated/0/NovelIDE/记忆包/{novelId}/` |
| 用户记忆 | `UserMemory` | 跨小说的用户偏好 | `/storage/emulated/0/NovelIDE/记忆包/user_memory.txt` |

```dart
// 获取记忆注入AI上下文
final novelMemory = await NovelMemory.getForAiContext(novelId, novelTitle);
final userMemory = await UserMemory.getForAiContext();
```

---

## 16. 💥 常见踩坑汇总

| 问题 | 原因 | 解决 |
|------|------|------|
| 切主题后页面颜色不变 | 硬编码 `Color(0xFF...)` | 用 `skinThemeProvider` |
| 安装提示签名不匹配 | GitHub CI 签名 ≠ 本地签名 | 卸载旧版重装 |
| 构建失败：`debugPrint` 缺 import | 需要 `import 'package:flutter/foundation.dart'` | 加 import |
| Release 包白屏/崩溃 | ProGuard 规则缺失 | 在 `proguard-rules.pro` 加 keep 规则 |
| 卸载重装数据丢失 | 存储在应用专属目录 | 用 `PublicStorageHelper` |
| 添加新依赖后构建失败 | 没加 ProGuard 规则 | 同上 |
| 两个 push 导致 Auto Release 404 | 并发冲突 | 非代码问题，忽略 |
| Widget 中无法使用 `ref` | 继承了 `StatefulWidget` 而非 `ConsumerStatefulWidget` | 换基类 |
| `const TextStyle(color: xxx)` 编译错误 | xxx 是运行时变量不是 const | 去掉 `const` |

---

## 17. ✅ 提交前检查清单

在推代码之前，逐项确认：

- [ ] **没有** 使用 `getExternalStorageDirectory()` 或 `getApplicationDocumentsDirectory()`
- [ ] **没有** 在 Widget 中硬编码 `Color(0xFF...)` 作为页面/卡片/文字主色
- [ ] **所有** 新 Widget 继承自 `ConsumerStatefulWidget` / `ConsumerWidget`（如需读 Riverpod）
- [ ] **所有** 弹窗/对话框/BottomSheet 的颜色跟随主题
- [ ] 新页面已在 `router.dart` 中添加路由
- [ ] 新智能体已添加到 `tomatoAgentsProvider`
- [ ] 新原生插件已在 `proguard-rules.pro` 添加 keep 规则
- [ ] 存储路径通过 `PublicStorageHelper` 访问
- [ ] API Key 通过 `SecureStorageDataSource` 存储
- [ ] 已运行 `build_runner`（如有 model 修改）
- [ ] 已在本地 `flutter build apk` 或等 CI 通过

---

*最后更新：2026-05-31*
*维护者：赵露思（AI助手）*