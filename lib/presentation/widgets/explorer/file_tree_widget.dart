import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/app_themes.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/data/models/file_tree_node.dart';
import 'package:novel_ide/presentation/state/explorer_provider.dart';
import 'package:novel_ide/presentation/widgets/explorer/file_tree_item.dart';

/// 核心树组件
///
/// ListView.builder 虚拟化，展开/折叠动画，当前编辑文件高亮，48px 最小触摸区域。
class FileTreeWidget extends ConsumerStatefulWidget {
  const FileTreeWidget({super.key, required this.novelId, this.onChapterTap});
  final String novelId;
  final void Function(String chapterId, String title)? onChapterTap;

  @override
  ConsumerState<FileTreeWidget> createState() => _FileTreeWidgetState();
}

class _FileTreeWidgetState extends ConsumerState<FileTreeWidget> {
  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinThemeProvider);
    final items = ref.watch(flattenedTreeProvider(widget.novelId));

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 48,
                color: skin.textSecondary.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                '暂无章节',
                style: TextStyle(color: skin.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '点击右上角 + 新建章节',
                style: TextStyle(
                  color: skin.textSecondary.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildAnimatedItem(context, skin, item);
      },
    );
  }

  Widget _buildAnimatedItem(
    BuildContext context,
    SkinTheme skin,
    FlattenedNode item,
  ) {
    final node = item.node;

    return GestureDetector(
      onTap: () {
        if (item.hasChildren) {
          ref
              .read(explorerStateProvider(widget.novelId).notifier)
              .toggleExpand(node.path);
        } else if (node.isLeaf) {
          widget.onChapterTap?.call(node.id, node.name);
          ref
              .read(explorerStateProvider(widget.novelId).notifier)
              .setCurrentFile(node.path);
        }
      },
      onLongPress: () => _showContextMenu(context, skin, node),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: FileTreeItem(
            node: node,
            depth: item.depth,
            isExpanded: item.isExpanded,
            hasChildren: item.hasChildren,
          ),
        ),
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    SkinTheme skin,
    FileTreeNode node,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (node.isFolder) ...[
              ListTile(
                leading: Icon(Icons.note_add, color: skin.primary),
                title: const Text('新建章节'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(Icons.create_new_folder, color: skin.primary),
                title: const Text('新建子文件夹'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: skin.textPrimary),
                title: const Text('重命名'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(Icons.open_in_new, color: skin.primary),
                title: const Text('打开编辑'),
                onTap: () {
                  Navigator.pop(ctx);
                  widget.onChapterTap?.call(node.id, node.name);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: skin.textPrimary),
                title: const Text('重命名'),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: skin.textSecondary),
                title: const Text('章节信息'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showChapterInfo(context, skin, node);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red[400]),
                title: Text('删除', style: TextStyle(color: Colors.red[400])),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showChapterInfo(
    BuildContext context,
    SkinTheme skin,
    FileTreeNode node,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(node.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '字数: ${node.wordCount ?? 0}',
              style: TextStyle(color: skin.textSecondary),
            ),
            if (node.lastModified != null)
              Text(
                '最后修改: ${node.lastModified}',
                style: TextStyle(color: skin.textSecondary),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
