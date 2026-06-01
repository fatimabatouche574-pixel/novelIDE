import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/app_themes.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/data/models/file_tree_node.dart';

/// 单行文件树节点渲染
///
/// 缩进 + 展开箭头 + 图标 + 名称 + 字数。
/// 文件夹：粗体名称 + 子项数量。
/// 章节：字数统计 + 未保存红点 + 当前编辑高亮。
class FileTreeItem extends ConsumerWidget {
  const FileTreeItem({
    super.key,
    required this.node,
    required this.depth,
    required this.isExpanded,
    required this.hasChildren,
  });

  final FileTreeNode node;
  final int depth;
  final bool isExpanded;
  final bool hasChildren;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinThemeProvider);
    final indent = depth * 20.0;

    return Container(
      padding: EdgeInsets.only(left: 8 + indent, right: 12, top: 6, bottom: 6),
      color: node.isCurrentFile ? skin.primary.withOpacity(0.08) : null,
      child: Row(
        children: [
          // 展开/折叠箭头
          if (hasChildren)
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_right,
                size: 18,
                color: skin.textSecondary,
              ),
            )
          else
            const SizedBox(width: 18),
          const SizedBox(width: 4),
          // 图标
          _buildIcon(skin),
          const SizedBox(width: 8),
          // 名称 + 右侧信息
          Expanded(child: _buildContent(skin)),
          // 未保存红点
          if (node.isModified)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.red[400],
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon(SkinTheme skin) {
    if (node.isFolder) {
      return Icon(
        isExpanded ? Icons.folder_open : Icons.folder,
        size: 18,
        color: skin.primary.withOpacity(0.8),
      );
    }
    return Icon(
      Icons.description,
      size: 16,
      color: skin.textSecondary.withOpacity(0.7),
    );
  }

  Widget _buildContent(SkinTheme skin) {
    if (node.isFolder) {
      return Row(
        children: [
          Expanded(
            child: Text(
              node.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: skin.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (node.children.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: skin.textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${node.totalChildCount}',
                style: TextStyle(fontSize: 10, color: skin.textSecondary),
              ),
            ),
        ],
      );
    }
    // 章节节点
    return Row(
      children: [
        Expanded(
          child: Text(
            node.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: node.isCurrentFile
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: node.isCurrentFile ? skin.primary : skin.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (node.wordCount != null && node.wordCount! > 0)
          Text(
            '${node.wordCount}字',
            style: TextStyle(
              fontSize: 10,
              color: skin.textSecondary.withOpacity(0.6),
            ),
          ),
      ],
    );
  }
}
