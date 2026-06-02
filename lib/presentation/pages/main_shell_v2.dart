import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/presentation/models/nav_item.dart';
import 'package:novel_ide/presentation/pages/sidebar_panel.dart';
import 'package:novel_ide/presentation/state/app_providers.dart';
import 'package:novel_ide/data/models/novel_model.dart';
import 'package:novel_ide/presentation/pages/ai/ai_chat_page.dart';
import 'package:novel_ide/presentation/pages/profile/profile_page.dart';
import 'package:novel_ide/presentation/pages/materials/materials_tree_page.dart';
import 'package:novel_ide/presentation/pages/memory/memory_list_page.dart';
import 'package:novel_ide/presentation/pages/memory/memory_graph_page.dart';
import 'package:novel_ide/presentation/pages/writing/global_search_page.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/core/theme/app_themes.dart';

/// V2 主壳层 — 手机竖屏适配版：抽屉式侧边栏 + 全宽内容
class MainShellV2 extends ConsumerStatefulWidget {
  const MainShellV2({super.key});

  @override
  ConsumerState<MainShellV2> createState() => _MainShellV2State();
}

class _MainShellV2State extends ConsumerState<MainShellV2> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 当前导航项
  NavItem _currentItem = NavItem.aiChat;

  /// 专注模式
  bool _focusMode = false;

  /// 专注模式退出倒计时
  int _focusExitCountdown = 0;

  // ── 打开 / 关闭抽屉 ──
  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();
  void _closeDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  /// 抽屉内导航
  void _onDrawerNavigate(NavItem item) {
    _closeDrawer();
    setState(() => _currentItem = item);
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinThemeProvider);

    // 专注模式：全屏 AiChatPage + 长按退出
    if (_focusMode) {
      return _buildFocusMode(skin);
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: skin.background,
      // ── 抽屉式侧边栏（从左侧滑出，覆盖在内容上方）──
      drawer: Drawer(
        width: UiTokens.sidebarWidth,
        child: SafeArea(
          child: SidebarPanel(
            currentItem: _currentItem,
            onNavigate: _onDrawerNavigate,
          ),
        ),
      ),
      // ── 主内容区（全屏宽度）──
      body: SafeArea(
        child: Column(
          children: [
            // 顶部栏
            _buildTopBar(),
            // 页面内容
            Expanded(child: _buildPageContent()),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 顶部栏
  // ════════════════════════════════════════════════════════════════

  Widget _buildTopBar() {
    return Container(
      height: UiTokens.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: UiTokens.primary,
      ),
      child: Row(
        children: [
          // 汉堡菜单 ☰ — 打开抽屉
          GestureDetector(
            onTap: _openDrawer,
            child: const Text(
              '☰',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 动态标题
          Text(
            _currentItem.title,
            style: const TextStyle(
              fontSize: UiTokens.titleFS,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // 专注模式按钮
          IconButton(
            icon: Icon(
              _focusMode ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => setState(() => _focusMode = !_focusMode),
            tooltip: _focusMode ? '退出专注模式' : '专注模式',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // 页面内容切换
  // ════════════════════════════════════════════════════════════════

  Widget _buildPageContent() {
    switch (_currentItem.route) {
      case 'ai_chat':
        return const AiChatPage();

      case 'workspace':
        return const MaterialsTreePage();

      case 'materials':
        return const MaterialsTreePage();

      case 'memory':
        final novel = ref.watch(selectedNovelProvider);
        if (novel != null) {
          return MemoryListPage(novelId: novel.id);
        }
        return _buildNoNovelPlaceholder();

      case 'global_search':
        final selectedNovel = ref.watch(selectedNovelProvider);
        if (selectedNovel != null) {
          return GlobalSearchPage(
            novelId: selectedNovel.id,
            novelTitle: selectedNovel.title,
          );
        }
        return _buildNoNovelPlaceholder();

      case 'settings':
        return const ProfilePage();

      default:
        return const AiChatPage();
    }
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
            // 全屏 AiChatPage
            const AiChatPage(),

            // 顶部专注指示条
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

            // 长按退出区域
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
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 专注模式退出倒计时
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

  // ════════════════════════════════════════════════════════════════
  // 未选择作品占位
  // ════════════════════════════════════════════════════════════════

  Widget _buildNoNovelPlaceholder() {
    final skin = ref.watch(skinThemeProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: skin.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            '请先在侧边栏选择一个作品',
            style: TextStyle(
              color: skin.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '选择作品后即可使用此功能',
            style: TextStyle(
              color: skin.textSecondary.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
