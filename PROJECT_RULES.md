# 🚫 项目铁律（所有AI必读）

> **违反以下规则的代码会被拒绝合并，请在修改代码前阅读本文档。**

---

## 1. 📂 存储路径：只用公共目录

**❌ 禁止使用：**
```dart
import 'package:path_provider/path_provider.dart';
getExternalStorageDirectory()
getApplicationDocumentsDirectory()
getDatabasesPath()
```

**✅ 必须使用：**
```dart
import 'package:novel_ide/data/datasources/public_storage_helper.dart';
// 根目录：/storage/emulated/0/NovelIDE/
PublicStorageHelper.publicRoot   // 根目录
PublicStorageHelper.projectsDir  // 作品区/
PublicStorageHelper.materialsDir // 资料区/
PublicStorageHelper.memoryDir    // 记忆包/
PublicStorageHelper.skillDir     // Skill/
PublicStorageHelper.agentDir     // Agent/
PublicStorageHelper.backupDir    // 备份/
PublicStorageHelper.configFile   // app_config.json
```

**原因：** 应用专属目录（`Android/data/{包名}/`）卸载会丢失用户数据，公共目录卸载保留。

---

## 2. 🎨 主题颜色：必须接入 SkinTheme

**❌ 禁止使用：**
```dart
const bgColor = Color(0xFF000000);
static const primaryColor = Color(0xFF10A37F);
// 任何硬编码的 Color(0xFF...) 颜色值
```

**✅ 必须使用：**
```dart
import 'package:novel_ide/core/theme/skin_provider.dart';

// 在 ConsumerWidget / ConsumerState 中：
final skin = ref.watch(skinThemeProvider);
final bgColor = skin.background;      // 背景色
final cardBg = skin.surface;          // 卡片/表面
final cardBg2 = skin.cardBg;          // 次级卡片
final primaryColor = skin.primary;    // 主题色
final textPrimary = skin.textPrimary; // 主文字
final textSecondary = skin.textSecondary; // 次文字
final isDark = skin.brightness == Brightness.dark; // 判断深色/浅色
```

**原因：** 用户可以选择8种主题皮肤，硬编码颜色会导致主题切换失效。

---

## 3. ✍️ 签名配置：固定使用 GitHub Secrets

**构建签名由 GitHub Actions secrets 管理，不要本地覆盖：**
- `secrets.KEYSTORE_BASE64` → keystore 文件
- `secrets.KEYSTORE_PASSWORD` → 密码
- `secrets.KEY_ALIAS` → 别名
- `secrets.KEY_PASSWORD` → 密钥密码

**不要在 `build.gradle` 中硬编码签名路径或密码。**

---

## 4. 📦 添加新智能体（Agent）

位置：`lib/presentation/state/app_providers.dart` 的 `tomatoAgentsProvider` 列表

```dart
TomatoAgent(
  id: 'xxx',           // 唯一ID，下划线命名
  name: '显示名称',
  icon: '🎯',          // emoji 图标
  description: '功能描述',
  systemPrompt: '''完整提示词''',
  parameterHints: ['参数提示'],
),
```

如果需要在AI工具菜单中调用，还需在 `main_shell.dart` 的 `_showAiToolsMenu()` 添加入口。

---

## 5. 🏗️ Flutter Widget 规范

- **有状态页面** 继承 `ConsumerStatefulWidget`（不是 `StatefulWidget`）
- **无状态组件** 继承 `ConsumerWidget`（不是 `StatelessWidget`）
- **颜色/样式** 通过 `Theme.of(context)` 或 `skinThemeProvider` 读取
- **禁止** 在 Widget 中使用 `const Color(0xFF...)` 作为主色调

---

## 6. 📁 项目结构速查

```
lib/
├── core/
│   ├── constants.dart          # 全局常量
│   ├── router.dart             # 路由
│   └── theme/
│       ├── app_themes.dart     # 8种 SkinTheme 定义
│       └── skin_provider.dart  # 主题状态管理
├── data/
│   ├── datasources/
│   │   ├── database_helper.dart      # SQLite
│   │   ├── local_file_datasource.dart # 文件操作
│   │   └── public_storage_helper.dart # 公共存储工具类 ⭐
│   ├── models/                 # 数据模型
│   ├── repositories/           # 仓库层
│   └── services/               # 业务服务
└── presentation/
    ├── pages/                  # 页面
    ├── state/                  # Riverpod providers
    └── widgets/                # 通用组件
```

---

## ⚡ 快速检查清单

在提交代码前，检查以下几点：

- [ ] 没有使用 `getExternalStorageDirectory()` 或 `getApplicationDocumentsDirectory()`
- [ ] 没有硬编码 `Color(0xFF...)` 作为界面主色
- [ ] 新 Widget 使用 `ConsumerStatefulWidget` / `ConsumerWidget`
- [ ] 新智能体已添加到 `tomatoAgentsProvider`
- [ ] 存储路径通过 `PublicStorageHelper` 访问

---

*最后更新：2026-05-31*