import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/presentation/state/app_providers.dart';
import 'package:novel_ide/presentation/widgets/file_tree_view.dart';
import 'package:novel_ide/presentation/widgets/explorer/explorer_panel.dart';
import 'package:novel_ide/presentation/pages/materials/relationship_graph_page.dart';
import 'package:novel_ide/data/models/novel_model.dart';
import 'package:novel_ide/data/models/chapter_model.dart';
import 'package:novel_ide/data/models/ai_chat_session_model.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/core/theme/app_themes.dart';

/// 侧边栏内容组件
///
/// 包含：新会话按钮、历史会话列表、作品树（ExplorerPanel）、资料库、导入导出。
class DrawerContent extends ConsumerStatefulWidget {
  const DrawerContent({
    super.key,
    required this.chatSessions,
    required this.selectedNovel,
    required this.onNewSession,
    required this.onSwitchSession,
    required this.onImport,
    required this.onExport,
    required this.onCreateNovel,
    required this.onNavigateToMaterial,
    required this.onChapterTap,
  });

  final List<AiChatSessionModel> chatSessions;
  final Novel? selectedNovel;

  final VoidCallback onNewSession;
  final void Function(String sessionId) onSwitchSession;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onCreateNovel;
  final void Function(String? materialType) onNavigateToMaterial;
  final void Function(String novelId, Chapter chapter) onChapterTap;

  @override
  ConsumerState<DrawerContent> createState() => _DrawerContentState();
}

class _DrawerContentState extends ConsumerState<DrawerContent> {
  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinThemeProvider);
    final dividerColor = skin.textSecondary.withValues(alpha: 0.15);

    return Container(
      decoration: BoxDecoration(
        color: skin.surface,
        border: Border(right: BorderSide(color: dividerColor)),
      ),
      child: Column(
        children: [
          // 顶部安全区域留白
          SizedBox(height: MediaQuery.of(context).padding.top + 8),

          // 新会话按钮
          _buildNewSessionButton(skin, dividerColor),

          // 滚动内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 历史会话
                  _buildHistorySection(skin),
                  const SizedBox(height: 8),

                  // 作品（ExplorerPanel）
                  _buildNovelsSection(skin),
                  const SizedBox(height: 8),

                  // 资料库
                  _buildMaterialsSection(skin),
                ],
              ),
            ),
          ),

          // 底部导入导出
          _buildBottomActions(skin, dividerColor),
        ],
      ),
    );
  }

  // ── 新会话按钮 ─────────────────────────────────────────────

  Widget _buildNewSessionButton(SkinTheme skin, Color dividerColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: GestureDetector(
        onTap: widget.onNewSession,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: dividerColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.add, color: skin.textPrimary, size: 18),
              const SizedBox(width: 8),
              Text(
                '新会话',
                style: TextStyle(color: skin.textPrimary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 历史会话 ───────────────────────────────────────────────

  Widget _buildHistorySection(SkinTheme skin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('历史会话', skin.textSecondary),
        if (widget.chatSessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text(
              '暂无历史会话',
              style: TextStyle(
                color: skin.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          )
        else
          ...widget.chatSessions.take(10).map(
                (session) => _buildSessionItem(session, skin),
              ),
      ],
    );
  }

  Widget _buildSessionItem(AiChatSessionModel session, SkinTheme skin) {
    final currentSessionId = ref.watch(currentSessionIdProvider);
    final isSelected = currentSessionId == session.id;

    // 格式化时间
    String timeStr;
    final now = DateTime.now();
    final updatedAt = session.updatedAt;
    if (now.year == updatedAt.year &&
        now.month == updatedAt.month &&
        now.day == updatedAt.day) {
      timeStr =
          '今天 ${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}';
    } else if (now.year == updatedAt.year &&
        now.month == updatedAt.month &&
        now.day - updatedAt.day == 1) {
      timeStr =
          '昨天 ${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}';
    } else {
      timeStr = '${updatedAt.month}月${updatedAt.day}日';
    }

    return GestureDetector(
      onTap: () => widget.onSwitchSession(session.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? skin.primary.withValues(alpha: 0.15)
              : skin.cardBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              style: TextStyle(color: skin.textPrimary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              timeStr,
              style: TextStyle(
                color: skin.textSecondary.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 作品区（ExplorerPanel） ─────────────────────────────────

  Widget _buildNovelsSection(SkinTheme skin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
          child: Row(
            children: [
              Text(
                '作品',
                style: TextStyle(
                  color: skin.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: widget.onCreateNovel,
                child: Icon(
                  Icons.add_circle_outline,
                  color: skin.textSecondary,
                  size: 18,
                ),
              ),
            ],
          ),
        ),

        // 无作品引导 或 ExplorerPanel
        if (widget.selectedNovel == null)
          _buildNoNovelPrompt(skin)
        else
          SizedBox(
            height: 320,
            child: ExplorerPanel(
              novelId: widget.selectedNovel!.id,
              onChapterTap: (chapterId, title) async {
                // 查找完整 Chapter 对象
                final novelId = widget.selectedNovel!.id;
                final chaptersAsync = ref.read(chaptersProvider(novelId));
                final chapters = chaptersAsync.valueOrNull ?? [];
                final chapter = chapters
                    .where((c) => c.id == chapterId)
                    .firstOrNull;
                if (chapter != null) {
                  widget.onChapterTap(novelId, chapter);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildNoNovelPrompt(SkinTheme skin) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: skin.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: skin.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.create_new_folder_outlined, color: skin.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            '还没有作品',
            style: TextStyle(
              color: skin.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '创建第一部作品开始写作',
            style: TextStyle(
              color: skin.textSecondary.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: FilledButton.icon(
              onPressed: widget.onCreateNovel,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('创建作品', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 资料库 ─────────────────────────────────────────────────

  Widget _buildMaterialsSection(SkinTheme skin) {
    final selectedNovel = widget.selectedNovel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('资料库', skin.textSecondary),
        if (selectedNovel == null)
          const SizedBox.shrink()
        else
          ..._buildMaterialTreeNodes(selectedNovel).map(
            (node) => _buildMaterialItem(node, skin, selectedNovel),
          ),
      ],
    );
  }

  Widget _buildMaterialItem(
    FileTreeNode node,
    SkinTheme skin,
    Novel selectedNovel,
  ) {
    return InkWell(
      onTap: () => _handleMaterialTap(node, selectedNovel),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(node.icon ?? Icons.folder, size: 18, color: node.iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                node.name,
                style: TextStyle(color: skin.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMaterialTap(FileTreeNode node, Novel selectedNovel) {
    if (node.parentType == 'relation_graph') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RelationshipGraphPage(
            novelId: selectedNovel.id,
            novelTitle: selectedNovel.title,
          ),
        ),
      );
      return;
    }
    widget.onNavigateToMaterial(node.parentType);
  }

  List<FileTreeNode> _buildMaterialTreeNodes(Novel selectedNovel) {
    final novelId = selectedNovel.id;
    final characters = ref.watch(charactersProvider(novelId));
    final settings = ref.watch(settingCardsProvider(novelId));
    final locations = ref.watch(locationsProvider(novelId));
    final hooks = ref.watch(plotHooksProvider(novelId));
    final factions = ref.watch(factionsProvider(novelId));
    final items = ref.watch(itemsProvider(novelId));
    final references = ref.watch(referencesProvider(novelId));

    return [
      FileTreeNode(
        id: 'mat_char',
        name: '角色 (${characters.length})',
        icon: Icons.person,
        iconColor: const Color(0xFF42A5F5),
        isFolder: false,
        parentType: 'character',
      ),
      FileTreeNode(
        id: 'mat_graph',
        name: '关系图',
        icon: Icons.people_outline,
        iconColor: const Color(0xFFAB47BC),
        isFolder: false,
        parentType: 'relation_graph',
      ),
      FileTreeNode(
        id: 'mat_setting',
        name: '设定 (${settings.length})',
        icon: Icons.settings,
        iconColor: const Color(0xFF42A5F5),
        isFolder: false,
        parentType: 'setting',
      ),
      FileTreeNode(
        id: 'mat_location',
        name: '地点 (${locations.length})',
        icon: Icons.location_on,
        iconColor: const Color(0xFF42A5F5),
        isFolder: false,
        parentType: 'location',
      ),
      FileTreeNode(
        id: 'mat_faction',
        name: '势力 (${factions.length})',
        icon: Icons.account_balance,
        iconColor: const Color(0xFF42A5F5),
        isFolder: false,
        parentType: 'faction',
      ),
      FileTreeNode(
        id: 'mat_item',
        name: '道具 (${items.length})',
        icon: Icons.inventory_2,
        iconColor: const Color(0xFF42A5F5),
        isFolder: false,
        parentType: 'item',
      ),
      FileTreeNode(
        id: 'mat_hook',
        name: '伏笔 (${hooks.length})',
        icon: Icons.lightbulb_outline,
        iconColor: const Color(0xFF42A5F5),
        isFolder: false,
        parentType: 'hook',
      ),
      FileTreeNode(
        id: 'mat_ref',
        name: '参考 (${references.length})',
        icon: Icons.book,
        iconColor: const Color(0xFF42A5F5),
        isFolder: false,
        parentType: 'reference',
      ),
      FileTreeNode(
        id: 'mat_memory',
        name: '记忆包',
        icon: Icons.psychology,
        iconColor: const Color(0xFF42A5F5),
        isFolder: false,
        parentType: 'memory',
      ),
    ];
  }

  // ── 底部导入导出按钮 ───────────────────────────────────────

  Widget _buildBottomActions(SkinTheme skin, Color dividerColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onExport,
              icon: const Icon(Icons.upload, size: 16),
              label: const Text('导出'),
              style: OutlinedButton.styleFrom(
                foregroundColor: skin.textPrimary,
                side: BorderSide(color: dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onImport,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('导入'),
              style: OutlinedButton.styleFrom(
                foregroundColor: skin.textPrimary,
                side: BorderSide(color: dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 工具方法 ───────────────────────────────────────────────

  Widget _buildSectionLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
