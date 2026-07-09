import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/presentation/models/nav_item.dart';
import 'package:novel_ide/presentation/pages/sidebar_panel.dart';
import 'package:novel_ide/presentation/widgets/operit_snackbar.dart';
import 'package:novel_ide/presentation/state/app_providers.dart';
import 'package:novel_ide/data/models/novel_model.dart';
import 'package:novel_ide/presentation/pages/ai/ai_chat_page.dart';
import 'package:novel_ide/presentation/pages/memory/memory_list_page.dart';
import 'package:novel_ide/presentation/pages/memory/memory_graph_page.dart';
import 'package:novel_ide/presentation/pages/writing/global_search_page.dart';
// Operit pages
import 'package:novel_ide/presentation/pages/operit_assistant_page.dart';
import 'package:novel_ide/presentation/pages/operit_about_page.dart';
import 'package:novel_ide/presentation/pages/operit_help_page.dart';
import 'package:novel_ide/presentation/widgets/import_export_dialog.dart';
import 'package:novel_ide/presentation/pages/operit_token_stats_page.dart';
import 'package:novel_ide/presentation/pages/operit_persona_gen_page.dart';
import 'package:novel_ide/presentation/pages/operit_chat_history_page.dart';
import 'package:novel_ide/presentation/pages/operit_global_display_page.dart';
import 'package:novel_ide/presentation/pages/operit_layout_adjust_page.dart';
import 'package:novel_ide/presentation/pages/operit_external_http_page.dart';
import 'package:novel_ide/presentation/pages/tools/operit_toolbox_page.dart';
import 'package:novel_ide/presentation/pages/tools/operit_workflow_page.dart';
import 'package:novel_ide/presentation/pages/tools/operit_terminal_page.dart';
import 'package:novel_ide/presentation/pages/tools/operit_log_viewer_page.dart';
import 'package:novel_ide/presentation/pages/tools/operit_file_manager_page.dart';
import 'package:novel_ide/presentation/pages/tools/operit_sql_viewer_page.dart';
import 'package:novel_ide/presentation/pages/packages/operit_packages_page.dart';
import 'package:novel_ide/presentation/pages/packages/operit_skill_detail_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_theme_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_user_prefs_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_language_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_model_config_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_functional_config_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_speech_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_prompts_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_waifu_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_backup_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_context_summary_page.dart';
import 'package:novel_ide/presentation/pages/settings/operit_tool_perm_page.dart';
import 'package:novel_ide/presentation/pages/packages/operit_market_page.dart';
import 'package:novel_ide/presentation/pages/profile/profile_page.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/core/theme/app_themes.dart';

/// Operit 风格主壳层
///
/// - 顶部栏：汉堡/返回箭头、标题、操作按钮
/// - Drawer: Scaffold.drawer 内嵌 SidebarPanel
/// - 导航历史栈支持返回按钮
/// - 抽屉打开时内容区 3D 变换动画（translateX + scale + rotateY）
class MainShellV2 extends ConsumerStatefulWidget {
  const MainShellV2({super.key});

  @override
  ConsumerState<MainShellV2> createState() => _MainShellV2State();
}

class _MainShellV2State extends ConsumerState<MainShellV2>
    with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 导航历史栈
  final List<String> _navHistory = ['ai_chat'];

  /// 专注模式
  bool _focusMode = false;
  int _focusExitCountdown = 0;

  /// 抽屉动画控制器
  late AnimationController _drawerController;
  late Animation<double> _drawerAnimation;

  String get _currentRoute =>
      _navHistory.isNotEmpty ? _navHistory.last : 'ai_chat';

  bool get _isHomeRoute => _navHistory.length <= 1;

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: UiTokens.drawerAnimMs),
    );
    _drawerAnimation = CurvedAnimation(
      parent: _drawerController,
      curve: const Cubic(0.2, 0.9, 0.3, 1.0),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  // ── 打开 / 关闭抽屉 ──

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
    _drawerController.forward();
  }

  void _closeDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    _drawerController.reverse();
  }

  /// 抽屉内导航
  void _onDrawerNavigate(NavItem item) {
    _closeDrawer();
    _navigateTo(item.route);
  }

  /// 导航到指定路由
  void _navigateTo(String route) {
    setState(() {
      final existingIndex = _navHistory.indexOf(route);
      if (existingIndex >= 0) {
        // 回到已有位置，裁剪后续历史
        _navHistory.removeRange(
          existingIndex + 1,
          _navHistory.length,
        );
      } else if (_currentRoute != route) {
        _navHistory.add(route);
      }
    });
  }

  /// 新建一个完全独立的 AI 对话，避免小说创作上下文串线。
  void _triggerNewChat() {
    ref.read(newSessionTriggerProvider.notifier).state =
        ref.read(newSessionTriggerProvider) + 1;
    if (_currentRoute != 'ai_chat') {
      _navigateTo('ai_chat');
    }
  }

  /// 返回上一页
  void _goBack() {
    if (_navHistory.length > 1) {
      setState(() => _navHistory.removeLast());
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinThemeProvider);

    if (_focusMode) {
      return _buildFocusMode(skin);
    }

    return AnimatedBuilder(
      animation: _drawerAnimation,
      builder: (context, child) {
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: skin.background,
          onDrawerChanged: (isOpen) {
            if (isOpen) {
              _drawerController.forward();
            } else {
              _drawerController.reverse();
            }
          },
          drawer: Drawer(
            width: UiTokens.drawerW,
            child: SafeArea(
              child: SidebarPanel(
                currentRoute: _currentRoute,
                onNavigate: _onDrawerNavigate,
                onChapterTap: (chapterId, chapterTitle) {
                  _closeDrawer();
                  // TODO: 导航到编辑器页面
                  showOperitToast(context, '打开章节: $chapterTitle');
                },
                onCreateNovel: () {
                  _closeDrawer();
                  // TODO: 打开创建作品对话框
                  showOperitToast(context, '创建新作品');
                },
                onMaterialCategoryTap: (categoryType) {
                  _closeDrawer();
                  _navigateTo('materials');
                },
                onImport: () {
                  _closeDrawer();
                  showImportExportDialog(context, initialTab: 0);
                },
                onExport: () {
                  _closeDrawer();
                  showImportExportDialog(context, initialTab: 1);
                },
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  isHome: _isHomeRoute,
                  title: _getPageTitle(),
                  onMenuTap: _openDrawer,
                  onBackTap: _goBack,
                  onNewChatTap: _currentRoute == 'ai_chat'
                      ? _triggerNewChat
                      : null,
                  skin: skin,
                ),
                Expanded(child: _buildContentTransform(skin)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 内容区 3D 变换包装
  Widget _buildContentTransform(SkinTheme skin) {
    final animValue = _drawerAnimation.value;
    final translateX = UiTokens.drawerW * 0.82 * animValue;
    final scale = 1.0 - 0.08 * animValue;
    final rotateY = -7.0 * animValue * math.pi / 180.0;

    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(0, 3, translateX)
        ..setEntry(1, 1, scale)
        ..setEntry(2, 2, scale)
        ..setEntry(0, 0, scale * math.cos(rotateY))
        ..setEntry(0, 2, scale * math.sin(rotateY))
        ..setEntry(2, 0, -scale * math.sin(rotateY))
        ..setEntry(2, 2, scale * math.cos(rotateY)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(animValue * 16),
          color: skin.background,
        ),
        clipBehavior: Clip.antiAlias,
        child: _buildPageContent(),
      ),
    );
  }

  /// 获取当前页面标题
  String _getPageTitle() {
    return NavItem.titleForRoute(_currentRoute);
  }

  /// 页面内容切换
  Widget _buildPageContent() {
    switch (_currentRoute) {
      // ── AI功能区 ──
      case 'ai_chat':
        return const AiChatPage();
      case 'assistant_config':
        return const OperitAssistantPage();
      case 'memory':
        final novel = ref.watch(selectedNovelProvider);
        if (novel != null) {
          return MemoryListPage(novelId: novel.id);
        }
        return _buildNoNovelPlaceholder('记忆库');
      case 'toolbox':
        return const OperitToolboxPage();
      case 'workflow':
        return const OperitWorkflowPage();
      case 'package_manager':
        return const OperitPackagesPage();
      case 'token_usage':
        return const OperitTokenStatsPage();
      // ── 工具箱子页面 ──
      case 'terminal':
        return const OperitTerminalPage();
      case 'log_viewer':
        return const OperitLogViewerPage();
      case 'file_manager':
        return const OperitFileManagerPage();
      case 'sql_viewer':
        return const OperitSqlViewerPage();
      case 'skill_detail':
        return const OperitSkillDetailPage();
      // ── 设置子页面 ──
      case 'theme':
        return const OperitThemePage();
      case 'user_prefs':
        return const OperitUserPrefsPage();
      case 'language':
        return const OperitLanguagePage();
      case 'model_config':
        return const OperitModelConfigPage();
      case 'functional_config':
        return const OperitFunctionalConfigPage();
      case 'speech':
        return const OperitSpeechPage();
      case 'prompts':
        return const OperitPromptsPage();
      case 'waifu':
        return const OperitWaifuPage();
      case 'tool_perm':
        return const OperitToolPermPage();
      case 'backup':
        return const OperitBackupPage();
      case 'context_summary':
        return const OperitContextSummaryPage();
      case 'market':
        return const OperitMarketPage();
      case 'persona_gen':
        return const OperitPersonaGenPage();
      case 'chat_history':
        return const OperitChatHistoryPage();
      case 'global_display':
        return const OperitGlobalDisplayPage();
      case 'layout_adjust':
        return const OperitLayoutAdjustPage();
      case 'external_http':
        return const OperitExternalHttpPage();
      // ── 系统 ──
      case 'settings':
        return const ProfilePage();
      case 'about':
        return const OperitAboutPage();
      case 'help':
        return const OperitHelpPage();
      // ── 其他 ──
      case 'global_search':
        final selectedNovel = ref.watch(selectedNovelProvider);
        if (selectedNovel != null) {
          return GlobalSearchPage(
            novelId: selectedNovel.id,
            novelTitle: selectedNovel.title,
          );
        }
        return _buildNoNovelPlaceholder('全局搜索');
      case 'memory_graph':
        return const MemoryGraphPage();
      case 'memory_list':
        return const MemoryListPage();
      default:
        return const AiChatPage();
    }
  }

  /// 未选择作品占位
  Widget _buildNoNovelPlaceholder(String featureName) {
    final skin = ref.watch(skinThemeProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: skin.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            '请先选择一个作品',
            style: TextStyle(color: skin.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '选择作品后即可使用$featureName',
            style: TextStyle(
              color: skin.textSecondary.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 专注模式
  // ════════════════════════════════════════════════════════════════

  Widget _buildFocusMode(SkinTheme skin) {
    return Scaffold(
      backgroundColor: skin.background,
      body: SafeArea(
        child: Stack(
          children: [
            const AiChatPage(),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 36,
                color: UiTokens.primary.withOpacity(0.85),
                child: Center(
                  child: Text(
                    _focusExitCountdown > 0
                        ? '继续长按 ${_focusExitCountdown} 秒退出专注模式'
                        : '长按 3 秒退出专注模式',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 36,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onLongPressStart: (_) {
                  _focusExitCountdown = 3;
                  setState(() {});
                  _startFocusExitTimer();
                },
                onLongPressEnd: (_) {
                  _focusExitCountdown = 0;
                  setState(() {});
                },
                onLongPressCancel: () {
                  _focusExitCountdown = 0;
                  setState(() {});
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startFocusExitTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_focusExitCountdown <= 0) return false;
      _focusExitCountdown--;
      if (_focusExitCountdown <= 0) {
        setState(() => _focusMode = false);
        return false;
      }
      setState(() {});
      return true;
    });
  }
}

// ════════════════════════════════════════════════════════════════
// 顶部栏
// ════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isHome,
    required this.title,
    required this.onMenuTap,
    required this.onBackTap,
    required this.skin,
    this.onNewChatTap,
  });

  final bool isHome;
  final String title;
  final VoidCallback onMenuTap;
  final VoidCallback onBackTap;
  final SkinTheme skin;
  final VoidCallback? onNewChatTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: UiTokens.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(color: UiTokens.primary),
      child: Row(
        children: [
          // 汉堡菜单 / 返回箭头
          GestureDetector(
            onTap: isHome ? onMenuTap : onBackTap,
            child: Icon(
              isHome ? Icons.menu : Icons.arrow_back,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          // 动态标题
          Text(
            title,
            style: const TextStyle(
              fontSize: UiTokens.titleFS,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (onNewChatTap != null)
            TextButton.icon(
              onPressed: onNewChatTap,
              icon: const Icon(
                Icons.add_comment_outlined,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                '新对话',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          // 语音通话图标
          _TopBarAction(
            icon: Icons.call,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Scaffold(body: SizedBox.shrink()),
                ),
              );
            },
          ),
          // AI PC 图标
          _TopBarAction(icon: Icons.computer, onTap: () {}),
          // 工作区图标
          _TopBarAction(icon: Icons.workspaces_outline, onTap: () {}),
        ],
      ),
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white, size: 20),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
