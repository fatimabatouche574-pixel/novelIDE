import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/presentation/pages/ai/ai_chat_page.dart';
import 'package:novel_ide/presentation/pages/writing/editor_page.dart';
import 'package:novel_ide/presentation/pages/materials/materials_tree_page.dart';
import 'package:novel_ide/presentation/pages/outline/outline_page.dart';
import 'package:novel_ide/presentation/pages/stats/stats_page.dart';
import 'package:novel_ide/presentation/state/app_providers.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/core/theme/app_themes.dart';

/// 主内容区 - 带屏幕缓存的 Tab 切换
///
/// 使用 [IndexedStack] + 内部 [Map] 缓存已构建的页面，
/// 切换 Tab 时不会重建已有页面，保留滚动位置和输入状态。
class AppContent extends ConsumerStatefulWidget {
  const AppContent({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  /// 当前选中的 Tab 索引
  final int selectedIndex;

  /// Tab 切换回调
  final ValueChanged<int> onIndexChanged;

  @override
  ConsumerState<AppContent> createState() => _AppContentState();
}

class _AppContentState extends ConsumerState<AppContent> {
  /// 屏幕缓存：key = tab index, value = 已构建的 Widget
  final Map<int, Widget> _screenCache = {};

  @override
  Widget build(BuildContext context) {
    // 确保当前选中的 Tab 已缓存
    _screenCache.putIfAbsent(widget.selectedIndex, () {
      return _buildScreen(widget.selectedIndex);
    });

    // 用 IndexedStack 保持所有已缓存页面的状态
    return IndexedStack(
      index: widget.selectedIndex,
      children: List.generate(_screenCache.length, (i) {
        return _screenCache[i] ?? const SizedBox.shrink();
      }),
    );
  }

  /// 根据索引构建对应页面
  Widget _buildScreen(int index) {
    return switch (index) {
      0 => const AiChatPage(),
      1 => const _EditorTab(),
      2 => const MaterialsTreePage(),
      3 => const OutlinePage(),
      4 => const StatsPage(),
      _ => const SizedBox.shrink(),
    };
  }
}

/// 编辑器 Tab - 无章节选中时显示引导，选中后缓存 EditorPage
class _EditorTab extends ConsumerStatefulWidget {
  const _EditorTab();

  @override
  ConsumerState<_EditorTab> createState() => _EditorTabState();
}

class _EditorTabState extends ConsumerState<_EditorTab> {
  /// 缓存已打开的编辑器，避免重建
  Widget? _cachedEditor;
  String? _cachedChapterId;

  @override
  Widget build(BuildContext context) {
    final selectedNovel = ref.watch(selectedNovelProvider);
    final selectedChapter = ref.watch(selectedChapterProvider);
    final skin = ref.watch(skinThemeProvider);

    // 章节发生变化时更新缓存
    if (selectedChapter != null &&
        selectedChapter.id != _cachedChapterId) {
      _cachedChapterId = selectedChapter.id;
      _cachedEditor = EditorPage(
        novelId: selectedNovel!.id,
        chapterId: selectedChapter.id,
      );
    }

    // 有选中章节 → 显示缓存的编辑器
    if (_cachedEditor != null && selectedChapter != null) {
      return _cachedEditor!;
    }

    // 无选中章节 → 显示引导
    return _buildPlaceholder(context, skin);
  }

  Widget _buildPlaceholder(BuildContext context, SkinTheme skin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_note,
              size: 64,
              color: skin.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '从左侧作品树选择章节开始编辑',
              style: TextStyle(
                color: skin.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // 打开侧边栏（由父级处理）
                Scaffold.maybeOf(context)?.openDrawer();
              },
              icon: const Icon(Icons.menu_book, size: 18),
              label: const Text('打开作品列表'),
              style: OutlinedButton.styleFrom(
                foregroundColor: skin.primary,
                side: BorderSide(
                  color: skin.textSecondary.withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
