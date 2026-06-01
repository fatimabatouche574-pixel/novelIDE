import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/app_themes.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/data/models/file_tree_node.dart';

/// 长按上下文菜单（BottomSheet）
/// 文件夹：新建章节、新建子文件夹、重命名
/// 章节：打开编辑、重命名、章节信息、删除
class ChapterContextMenu extends ConsumerWidget {
  const ChapterContextMenu({
    super.key,
    required this.node,
    this.onEdit,
    this.onRename,
    this.onCreateChapter,
    this.onCreateFolder,
    this.onDelete,
  });
  final FileTreeNode node;
  final void Function(String chapterId, String title)? onEdit;
  final void Function(String nodeId, String newName, bool isFolder)? onRename;
  final void Function(String volumeId)? onCreateChapter;
  final void Function()? onCreateFolder;
  final void Function(String nodeId, bool isFolder)? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinThemeProvider);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: skin.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              node.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: skin.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          if (node.isFolder)
            ..._buildFolderActions(context, skin)
          else
            ..._buildFileActions(context, skin),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildFolderActions(BuildContext context, SkinTheme skin) {
    return [
      ListTile(
        leading: Icon(Icons.note_add, color: skin.primary),
        title: Text('新建章节'),
        subtitle: Text('在 "${node.name}" 下新建'),
        onTap: () {
          Navigator.pop(context);
          onCreateChapter?.call(node.id);
        },
      ),
      ListTile(
        leading: Icon(Icons.create_new_folder, color: skin.primary),
        title: Text('新建子文件夹'),
        onTap: () {
          Navigator.pop(context);
          onCreateFolder?.call();
        },
      ),
      ListTile(
        leading: Icon(Icons.edit, color: skin.textPrimary),
        title: Text('重命名'),
        onTap: () {
          Navigator.pop(context);
          _showRenameDialog(context, skin);
        },
      ),
    ];
  }

  List<Widget> _buildFileActions(BuildContext context, SkinTheme skin) {
    return [
      ListTile(
        leading: Icon(Icons.open_in_new, color: skin.primary),
        title: Text('打开编辑'),
        onTap: () {
          Navigator.pop(context);
          onEdit?.call(node.id, node.name);
        },
      ),
      ListTile(
        leading: Icon(Icons.edit, color: skin.textPrimary),
        title: Text('重命名'),
        onTap: () {
          Navigator.pop(context);
          _showRenameDialog(context, skin);
        },
      ),
      ListTile(
        leading: Icon(Icons.info_outline, color: skin.textSecondary),
        title: Text('章节信息'),
        onTap: () {
          Navigator.pop(context);
          _showInfoDialog(context, skin);
        },
      ),
      ListTile(
        leading: Icon(Icons.delete, color: Colors.red[400]),
        title: Text('删除', style: TextStyle(color: Colors.red[400])),
        onTap: () {
          Navigator.pop(context);
          _confirmDelete(context, skin);
        },
      ),
    ];
  }

  void _showRenameDialog(BuildContext context, SkinTheme skin) {
    final ctrl = TextEditingController(text: node.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('重命名'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: node.isFolder ? '文件夹名称' : '章节标题',
          ),
          style: TextStyle(color: skin.textPrimary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                onRename?.call(node.id, ctrl.text.trim(), node.isFolder);
              }
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, SkinTheme skin) {
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
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '最后修改: ${node.lastModified}',
                  style: TextStyle(color: skin.textSecondary),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('关闭')),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, SkinTheme skin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('确认删除'),
        content: Text('确定删除 "${node.name}" ？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call(node.id, node.isFolder);
            },
            child: Text('删除'),
          ),
        ],
      ),
    );
  }
}
