import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/app_themes.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/presentation/state/explorer_provider.dart';
import 'package:novel_ide/presentation/widgets/explorer/file_tree_widget.dart';
import 'package:novel_ide/presentation/widgets/explorer/writing_progress_bar.dart';

class ExplorerPanel extends ConsumerStatefulWidget {
  const ExplorerPanel({
    super.key,
    required this.novelId,
    this.onChapterTap,
    this.onCreateChapter,
    this.onCreateFolder,
  });
  final String novelId;
  final void Function(String chapterId, String title)? onChapterTap;
  final void Function(String volumeId)? onCreateChapter;
  final void Function()? onCreateFolder;
  @override
  ConsumerState<ExplorerPanel> createState() => _ExplorerPanelState();
}

class _ExplorerPanelState extends ConsumerState<ExplorerPanel> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinThemeProvider);
    final explorer = ref.watch(explorerStateProvider(widget.novelId));
    final stats = ref.watch(writingStatsProvider(widget.novelId));
    return Container(
      color: skin.surface,
      child: Column(
        children: [
          _buildToolbar(context, skin, explorer),
          const Divider(height: 1),
          Expanded(child: _buildBody(context, skin, explorer)),
          const Divider(height: 1),
          WritingProgressBar(
            totalWords: stats.totalWords,
            todayWords: stats.todayWords,
            todayGoalPercent: stats.todayGoalPercent,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    SkinTheme skin,
    ExplorerData explorer,
  ) {
    if (_isSearching) return _buildSearchBar(skin);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '文件管理',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: skin.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.search, size: 20, color: skin.textSecondary),
            tooltip: '搜索',
            onPressed: () => setState(() => _isSearching = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 20, color: skin.primary),
            tooltip: '新建',
            onPressed: () => _showCreateMenu(context, skin),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: Icon(Icons.sort, size: 20, color: skin.textSecondary),
            tooltip: '排序',
            onPressed: () => _showSortMenu(context, skin, explorer.sortMode),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(SkinTheme skin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(fontSize: 14, color: skin.textPrimary),
              decoration: InputDecoration(
                hintText: '搜索章节...',
                hintStyle: TextStyle(color: skin.textSecondary, fontSize: 14),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: skin.textSecondary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: skin.primary),
                ),
              ),
              onChanged: (v) {
                ref
                    .read(explorerStateProvider(widget.novelId).notifier)
                    .setSearchQuery(v);
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 20, color: skin.textSecondary),
            onPressed: () {
              _searchController.clear();
              ref
                  .read(explorerStateProvider(widget.novelId).notifier)
                  .setSearchQuery('');
              setState(() => _isSearching = false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SkinTheme skin,
    ExplorerData explorer,
  ) {
    if (explorer.isLoading)
      return Center(child: CircularProgressIndicator(color: skin.primary));
    if (explorer.errorMessage != null)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: skin.textSecondary),
            const SizedBox(height: 8),
            Text(
              explorer.errorMessage!,
              style: TextStyle(color: skin.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref
                  .read(explorerStateProvider(widget.novelId).notifier)
                  .refresh(),
              child: Text('重试', style: TextStyle(color: skin.primary)),
            ),
          ],
        ),
      );
    return FileTreeWidget(
      novelId: widget.novelId,
      onChapterTap: widget.onChapterTap,
    );
  }

  void _showCreateMenu(BuildContext context, SkinTheme skin) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.description, color: skin.primary),
              title: const Text('新建章节'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onCreateChapter?.call('');
              },
            ),
            ListTile(
              leading: Icon(Icons.create_new_folder, color: skin.primary),
              title: const Text('新建卷（文件夹）'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onCreateFolder?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSortMenu(BuildContext context, SkinTheme skin, SortMode current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: SortMode.values.map((mode) {
            final isSelected = mode == current;
            return ListTile(
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? skin.primary : skin.textSecondary,
              ),
              title: Text(mode.label),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(explorerStateProvider(widget.novelId).notifier)
                    .setSortMode(mode);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
