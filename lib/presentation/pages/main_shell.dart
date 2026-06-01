import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:novel_ide/presentation/state/app_providers.dart';
import 'package:novel_ide/presentation/pages/ai/ai_chat_page.dart';
import 'package:novel_ide/presentation/pages/profile/profile_page.dart';
import 'package:novel_ide/presentation/pages/works/export_page.dart'
    hide FileTreeNode;
import 'package:novel_ide/presentation/widgets/file_tree_view.dart';
import 'package:novel_ide/presentation/pages/materials/materials_tree_page.dart';
import 'package:novel_ide/presentation/pages/materials/relationship_graph_page.dart';
import 'package:novel_ide/data/models/novel_model.dart';
import 'package:novel_ide/data/models/chapter_model.dart';
import 'package:novel_ide/data/models/volume_model.dart';
import 'package:novel_ide/data/models/ai_config_model.dart';
import 'package:novel_ide/data/models/ai_chat_session_model.dart';
import 'package:novel_ide/data/repositories/chat_history_repository.dart';
import 'package:novel_ide/data/services/novel_import_service.dart';
import 'package:novel_ide/presentation/pages/writing/editor_page.dart';
import 'package:novel_ide/presentation/pages/writing/global_search_page.dart';
import 'package:novel_ide/presentation/widgets/top_notification.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/core/theme/app_themes.dart';

/// GPT风格单页面聊天应用
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _sidebarOpen = false;
  bool _modelDropdownOpen = false;
  bool _focusMode = false; // 专注模式：隐藏所有面板

  // 作品树展开状态
  final Set<String> _expandedNovels = {};
  final Set<String> _expandedVolumes = {};
  final Map<String, List<Volume>> _loadedVolumes = {};
  final Map<String, List<Chapter>> _loadedChapters = {};

  // 历史会话列表
  final ChatHistoryRepository _historyRepo = ChatHistoryRepository();
  List<AiChatSessionModel> _chatSessions = [];
  bool _sessionsLoaded = false;

  // 当前选中的模型名称（用于显示）
  String _selectedModelDisplay = 'GLM-4.7-Flash';

  // 主题颜色实例变量（build 时更新）
  late SkinTheme _skin;
  late Color _bgColor;
  late Color _sidebarBg;
  late Color _cardBg;
  late Color _cardBg2;
  late Color _primaryColor;
  late Color _textPrimary;
  late Color _textSecondary;
  late Color _textTertiary;
  late Color _dividerColor;

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }

  /// 加载历史会话列表
  Future<void> _loadChatSessions() async {
    try {
      final sessions = await _historyRepo.loadSessions();
      if (mounted) {
        setState(() {
          _chatSessions = sessions;
          _sessionsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Load chat sessions error: $e');
      if (mounted) {
        setState(() => _sessionsLoaded = true);
      }
    }
  }

  /// 触发新建会话
  void _triggerNewSession() {
    // 通过增加触发器值来通知 AiChatPage 新建会话
    final currentTrigger = ref.read(newSessionTriggerProvider);
    ref.read(newSessionTriggerProvider.notifier).state = currentTrigger + 1;
    setState(() => _sidebarOpen = false);
  }

  /// 切换到指定会话
  void _switchToSession(String sessionId) {
    ref.read(currentSessionIdProvider.notifier).state = sessionId;
    setState(() => _sidebarOpen = false);
  }

  /// 处理导入文件
  Future<void> _handleImport() async {
    setState(() => _sidebarOpen = false);

    final selectedNovel = ref.read(selectedNovelProvider);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'docx', 'epub'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      final importService = NovelImportService();
      final preview = await importService.previewImport(filePath);

      if (!mounted) return;

      // 显示导入预览对话框
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('导入预览'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('类型: ${preview.detectedType}'),
              Text('识别来源: ${preview.matchSource}'),
              Text('章节数: ${preview.chapters.length}'),
              Text('总字数: ${preview.totalWords}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('导入'),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      // 执行导入
      final importResult = await importService.importFromFile(
        novelId: selectedNovel?.id,
        novelTitle: selectedNovel?.title,
        filePath: filePath,
      );

      if (!mounted) return;

      if (importResult.success) {
        TopNotification.success(context, '导入成功：${importResult.chapterCount} 章');
        // 刷新作品列表
        ref.invalidate(novelsProvider);
      } else {
        TopNotification.error(context, '导入失败：${importResult.error}');
      }
    } catch (e) {
      if (mounted) {
        TopNotification.error(context, '导入失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final novels = ref.watch(novelsProvider).valueOrNull ?? [];
    final selectedNovel = ref.watch(selectedNovelProvider);
    final aiConfigs = ref.watch(aiConfigsProvider);
    final selectedAiConfig = ref.watch(selectedAiConfigProvider);

    // 更新显示的模型名称
    if (selectedAiConfig != null) {
      _selectedModelDisplay = selectedAiConfig.name;
    } else if (aiConfigs.isNotEmpty) {
      final textConfig = aiConfigs
          .where((c) => c.modelType == ModelType.text)
          .firstOrNull;
      if (textConfig != null) {
        _selectedModelDisplay = textConfig.name;
      }
    }

    // 从主题系统读取颜色，跟随皮肤切换
    final skin = ref.watch(skinThemeProvider);
    _skin = skin;
    _bgColor = skin.background;
    _sidebarBg = skin.surface;
    _cardBg = skin.surface;
    _cardBg2 = skin.cardBg;
    _primaryColor = skin.primary;
    _textPrimary = skin.textPrimary;
    _textSecondary = skin.textSecondary;
    _textTertiary = skin.textSecondary.withOpacity(0.7);
    _dividerColor = skin.brightness == Brightness.dark
        ? _dividerColor
        : skin.textSecondary.withOpacity(0.2);

    return Scaffold(
      backgroundColor: _bgColor,
      body: _focusMode
          // 专注模式：隐藏所有面板，全屏聊天
          ? GestureDetector(
              onLongPress: () => setState(() => _focusMode = false),
              child: AiChatPage(),
            )
          : Stack(
        children: [
          // 主内容区
          Column(
            children: [
              // 顶部栏
              _buildTopBar(
                context: context,
                bgColor: _bgColor,
                textPrimary: _textPrimary,
                textSecondary: _textSecondary,
                primaryColor: _primaryColor,
                cardBg: _cardBg,
              ),
              // 聊天内容区
              Expanded(child: AiChatPage()),
            ],
          ),

          // 侧边栏遮罩
          if (_sidebarOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _sidebarOpen = false),
                child: Container(color: Colors.black54),
              ),
            ),

          // 左侧侧边栏
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: _sidebarOpen ? 0 : -300,
            top: 0,
            bottom: 0,
            width: 280,
            child: _buildSidebar(
              context: context,
              sidebarBg: _sidebarBg,
              cardBg: _cardBg,
              cardBg2: _cardBg2,
              textPrimary: _textPrimary,
              textSecondary: _textSecondary,
              textTertiary: _textTertiary,
              primaryColor: _primaryColor,
              dividerColor: _dividerColor,
              novels: novels,
              selectedNovel: selectedNovel,
            ),
          ),

          // 模型选择下拉菜单
          if (_modelDropdownOpen)
            Positioned(
              top: 52,
              left: 0,
              right: 0,
              child: Center(
                child: _buildModelDropdown(
                  context: context,
                  cardBg: _cardBg,
                  cardBg2: _cardBg2,
                  textPrimary: _textPrimary,
                  textSecondary: _textSecondary,
                  primaryColor: _primaryColor,
                  dividerColor: _dividerColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 顶部栏
  Widget _buildTopBar({
    required BuildContext context,
    required Color bgColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required Color cardBg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: _dividerColor)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // 菜单按钮
            IconButton(
              icon: Icon(Icons.menu, color: textPrimary, size: 24),
              onPressed: () => setState(() => _sidebarOpen = true),
            ),
            // 标题区域（点击展开模型选择）
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _modelDropdownOpen = !_modelDropdownOpen),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '网文写作IDE',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _skin.cardBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedModelDisplay,
                        style: TextStyle(color: textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 新建按钮
            IconButton(
              icon: Icon(Icons.edit, color: textPrimary, size: 22),
              onPressed: _triggerNewSession,
            ),
            // 搜索按钮
            IconButton(
              icon: Icon(Icons.search, color: textPrimary, size: 22),
              onPressed: () {
                final novel = ref.read(selectedNovelProvider);
                if (novel != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GlobalSearchPage(
                        novelId: novel.id,
                        novelTitle: novel.title,
                      ),
                    ),
                  );
                } else {
                  _showCreateNovelDialog(context, ref);
                }
              },
            ),
            // 专注模式
            IconButton(
              icon: Icon(
                _focusMode ? Icons.fullscreen_exit : Icons.fullscreen,
                color: textPrimary, size: 22,
              ),
              onPressed: () => setState(() => _focusMode = !_focusMode),
            ),
            // 设置按钮
            IconButton(
              icon: Icon(Icons.settings, color: textPrimary, size: 22),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 左侧侧边栏
  Widget _buildSidebar({
    required BuildContext context,
    required Color sidebarBg,
    required Color cardBg,
    required Color cardBg2,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color primaryColor,
    required Color dividerColor,
    required List<Novel> novels,
    required Novel? selectedNovel,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: dividerColor)),
      ),
      child: Column(
        children: [
          // 顶部安全区域留白
          SizedBox(height: MediaQuery.of(context).padding.top + 8),
          // 新会话按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: GestureDetector(
              onTap: _triggerNewSession,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: _dividerColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add, color: textPrimary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '新会话',
                      style: TextStyle(color: textPrimary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 滚动内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 历史会话（从真实数据源读取）
                  _buildSectionLabel('历史会话', textSecondary),
                  if (_chatSessions.isEmpty && _sessionsLoaded)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        '暂无历史会话',
                        style: TextStyle(color: textTertiary, fontSize: 12),
                      ),
                    )
                  else
                    ..._chatSessions
                        .take(10)
                        .map(
                          (session) => _buildHistoryItemFromModel(
                            session,
                            textPrimary,
                            textTertiary,
                            cardBg2,
                          ),
                        ),

                  SizedBox(height: 8),
                  // 作品标题 + 新建按钮
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                    child: Row(
                      children: [
                        Text(
                          '作品',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        GestureDetector(
                          onTap: () => _showCreateNovelDialog(context, ref),
                          child: Icon(
                            Icons.add_circle_outline,
                            color: textSecondary,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 作品树
                  FileTreeView(
                    shrinkWrap: true,
                    nodes: _buildNovelTreeNodes(novels, selectedNovel),
                    onToggleExpand: _handleNovelTreeToggle,
                    onNodeTap: (node) => _handleNovelTreeTap(node, novels),
                    onNodeLongPress: (node) =>
                        _handleNovelTreeLongPress(node, novels),
                  ),

                  const SizedBox(height: 8),
                  _buildSectionLabel('资料库', textSecondary),

                  // 资料库分类 - 使用FileTreeView
                  if (selectedNovel == null)
                    _buildNoNovelPrompt(primaryColor, textPrimary, textTertiary)
                  else
                    FileTreeView(
                      shrinkWrap: true,
                      nodes: _buildMaterialTreeNodes(selectedNovel),
                      onNodeTap: (node) =>
                          _handleMaterialTreeTap(node, selectedNovel),
                    ),
                ],
              ),
            ),
          ),

          // 底部导出/导入按钮
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _sidebarOpen = false);
                      final novel = _ensureNovel(ref);
                      if (novel == null) {
                        _showCreateNovelDialog(context, ref);
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExportPage(
                            novelId: novel.id,
                            novelTitle: novel.title,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.upload, size: 16),
                    label: Text('导出'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: _dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleImport,
                    icon: Icon(Icons.download, size: 16),
                    label: Text('导入'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: _dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  /// 从会话模型构建历史会话项
  Widget _buildHistoryItemFromModel(
    AiChatSessionModel session,
    Color textPrimary,
    Color textTertiary,
    Color cardBg2,
  ) {
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
      onTap: () => _switchToSession(session.id),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.15) : _cardBg2,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              style: TextStyle(color: textPrimary, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(timeStr, style: TextStyle(color: textTertiary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  /// 构建作品树节点列表 (Novel -> Volume -> Chapter)
  List<FileTreeNode> _buildNovelTreeNodes(
    List<Novel> novels,
    Novel? selectedNovel,
  ) {
    return novels.map((novel) {
      final isExpanded = _expandedNovels.contains(novel.id);
      final volumes = _loadedVolumes[novel.id];
      final isSelected = selectedNovel?.id == novel.id;

      final children = <FileTreeNode>[];
      if (isExpanded && volumes != null) {
        for (final vol in volumes) {
          final volExpanded = _expandedVolumes.contains(vol.id);
          final chapters = _loadedChapters[vol.id];

          final chapterNodes = <FileTreeNode>[];
          if (volExpanded && chapters != null) {
            for (final ch in chapters) {
              final status = ChapterStatus.values.firstWhere(
                (e) => e.name == ch.status,
                orElse: () => ChapterStatus.draft,
              );
              Color badgeColor;
              String badgeText;
              switch (status) {
                case ChapterStatus.unwritten:
                  badgeColor = const Color(0xFF6C757D);
                  badgeText = '未写';
                  break;
                case ChapterStatus.draft:
                  badgeColor = const Color(0xFFFFC107);
                  badgeText = '草稿';
                  break;
                case ChapterStatus.polishing:
                  badgeColor = const Color(0xFF17A2B8);
                  badgeText = '润色中';
                  break;
                case ChapterStatus.completed:
                  badgeColor = const Color(0xFF28A745);
                  badgeText = '已完成';
                  break;
                case ChapterStatus.exported:
                  badgeColor = const Color(0xFF007BFF);
                  badgeText = '已导出';
                  break;
              }
              chapterNodes.add(
                FileTreeNode(
                  id: ch.id,
                  name: ch.title,
                  icon: Icons.description,
                  iconColor: const Color(0xFF4CAF50),
                  badge: badgeText,
                  badgeColor: badgeColor,
                  isFolder: false,
                  parentType: novel.id,
                ),
              );
            }
          }

          children.add(
            FileTreeNode(
              id: vol.id,
              name: vol.title,
              icon: Icons.folder,
              iconColor: const Color(0xFFFFC107),
              isFolder: true,
              isExpanded: volExpanded,
              children: chapterNodes,
              parentType: 'volume',
            ),
          );
        }
      }

      return FileTreeNode(
        id: novel.id,
        name: novel.title,
        icon: Icons.menu_book,
        iconColor: null,
        isFolder: true,
        isExpanded: isExpanded,
        children: children,
        trailing: '${novel.chapterCount}章',
        parentType: 'novel',
      );
    }).toList();
  }

  /// 处理作品树展开/折叠
  void _handleNovelTreeToggle(FileTreeNode node) {
    if (node.parentType == 'novel') {
      _toggleNovelExpand(node.id);
    } else if (node.parentType == 'volume') {
      _toggleVolumeExpand(node.id);
    }
  }

  /// 处理作品树节点点击（章节跳转）
  void _handleNovelTreeTap(FileTreeNode node, List<Novel> novels) {
    final novelId = node.parentType;
    if (novelId == null) return;
    final novel = novels.where((n) => n.id == novelId).firstOrNull;
    if (novel == null) return;

    // Find and set selected chapter
    for (final entry in _loadedChapters.entries) {
      final ch = entry.value.where((c) => c.id == node.id).firstOrNull;
      if (ch != null) {
        ref.read(selectedNovelProvider.notifier).state = novel;
        ref.read(selectedChapterProvider.notifier).state = ch;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditorPage(novelId: novel.id, chapterId: ch.id),
          ),
        );
        setState(() => _sidebarOpen = false);
        return;
      }
    }
  }

  /// 处理作品树长按菜单
  void _handleNovelTreeLongPress(FileTreeNode node, List<Novel> novels) {
    if (node.parentType == 'novel') {
      final novel = novels.where((n) => n.id == node.id).firstOrNull;
      if (novel != null) {
        _showNovelContextMenu(novel);
      }
    }
  }

  /// 构建资料库树节点列表（无选中作品时显示引导提示）
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

  /// 处理资料库树节点点击
  void _handleMaterialTreeTap(FileTreeNode node, Novel? selectedNovel) {
    if (selectedNovel == null) return;
    setState(() => _sidebarOpen = false);

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

    // 设置初始分类 tab
    if (node.parentType != null && node.parentType != 'memory') {
      ref.read(initialMaterialTabProvider.notifier).state = node.parentType;
    } else {
      ref.read(initialMaterialTabProvider.notifier).state = null;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MaterialsTreePage()),
    );
  }

  /// 无作品时的引导提示
  Widget _buildNoNovelPrompt(
    Color primaryColor,
    Color textPrimary,
    Color textTertiary,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.create_new_folder_outlined, color: primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            '还没有作品',
            style: TextStyle(
              color: textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '创建第一部作品开始写作',
            style: TextStyle(color: textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: FilledButton.icon(
              onPressed: () => _showCreateNovelDialog(context, ref),
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

  void _showNovelContextMenu(Novel novel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: _skin.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: _textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  novel.title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.add, color: _textPrimary),
                title: Text('新建卷', style: TextStyle(color: _textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showNewVolumeDialog(novel);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit, color: _textPrimary),
                title: Text('重命名作品', style: TextStyle(color: _textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showRenameNovelDialog(novel);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('删除作品', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteNovelConfirm(novel);
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 新建卷对话框
  void _showNewVolumeDialog(Novel novel) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _skin.surface,
        title: Text('新建卷', style: TextStyle(color: _textPrimary)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: _textPrimary),
          decoration: InputDecoration(
            hintText: '卷名称',
            hintStyle: TextStyle(color: _textSecondary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final volumeRepo = ref.read(volumeRepoProvider);
              await volumeRepo.createVolume(
                novelId: novel.id,
                title: ctrl.text.trim(),
                orderIndex: (_loadedVolumes[novel.id]?.length ?? 0),
              );
              Navigator.pop(ctx);
              // 刷新卷列表
              final volumes = await volumeRepo.getVolumesByNovel(novel.id);
              setState(() {
                _loadedVolumes[novel.id] = volumes;
              });
              TopNotification.success(context, '已创建卷：${ctrl.text.trim()}');
            },
            child: Text('创建'),
          ),
        ],
      ),
    );
  }

  /// 重命名作品对话框
  void _showRenameNovelDialog(Novel novel) {
    final ctrl = TextEditingController(text: novel.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _skin.surface,
        title: Text('重命名作品', style: TextStyle(color: _textPrimary)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: _textPrimary),
          decoration: InputDecoration(
            hintText: '作品名称',
            hintStyle: TextStyle(color: _textSecondary),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消')),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              final novelRepo = ref.read(novelRepoProvider);
              await novelRepo.updateNovel(
                novel.copyWith(title: ctrl.text.trim()),
              );
              Navigator.pop(ctx);
              // 刷新作品列表
              ref.invalidate(novelsProvider);
              TopNotification.success(context, '已重命名');
            },
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 删除作品确认
  void _showDeleteNovelConfirm(Novel novel) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _skin.surface,
        title: Text('删除作品', style: TextStyle(color: _textPrimary)),
        content: Text(
          '确定要删除「${novel.title}」吗？此操作不可恢复。',
          style: TextStyle(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final novelRepo = ref.read(novelRepoProvider);
              await novelRepo.deleteNovel(novel.id, novel.title);
              Navigator.pop(ctx);
              // 清除选中状态
              if (ref.read(selectedNovelProvider)?.id == novel.id) {
                ref.read(selectedNovelProvider.notifier).state = null;
              }
              // 刷新作品列表
              ref.invalidate(novelsProvider);
              TopNotification.success(context, '已删除');
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 获取当前选中的作品，若无则自动选中第一个作品
  Novel? _ensureNovel(WidgetRef ref) {
    final selected = ref.read(selectedNovelProvider);
    if (selected != null) return selected;
    final novels = ref.read(novelsProvider).valueOrNull ?? [];
    if (novels.isEmpty) return null;
    final first = novels.first;
    ref.read(selectedNovelProvider.notifier).state = first;
    loadNovelMaterials(ref, first.id);
    return first;
  }

  /// 获取当前选中的章节，若无则自动选中第一个章节
  Future<Chapter?> _ensureChapter(WidgetRef ref, String novelId) async {
    final selected = ref.read(selectedChapterProvider);
    if (selected != null && selected.novelId == novelId) return selected;
    final chaptersAsync = ref.read(chaptersProvider(novelId));
    final chapters = chaptersAsync.valueOrNull ?? [];
    if (chapters.isEmpty) {
      try {
        final loaded = await ref.read(chaptersProvider(novelId).future);
        if (loaded.isEmpty) return null;
        ref.read(selectedChapterProvider.notifier).state = loaded.first;
        return loaded.first;
      } catch (_) {
        return null;
      }
    }
    ref.read(selectedChapterProvider.notifier).state = chapters.first;
    return chapters.first;
  }

  /// 新建作品对话框
  void _showCreateNovelDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建作品'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: '作品名称',
                hintText: '例如：都市神医',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: '简介（可选）',
                hintText: '一句话简介',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              final repo = ref.read(novelRepoProvider);
              final novel = await repo.createNovel(
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
              );
              ref.invalidate(novelsProvider);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ref.read(selectedNovelProvider.notifier).state = novel;
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  /// 模型选择下拉菜单
  Widget _buildModelDropdown({
    required BuildContext context,
    required Color cardBg,
    required Color cardBg2,
    required Color textPrimary,
    required Color textSecondary,
    required Color primaryColor,
    required Color dividerColor,
  }) {
    final aiConfigs = ref.watch(aiConfigsProvider);
    final selectedConfig = ref.watch(selectedAiConfigProvider);
    final textConfigs = aiConfigs
        .where((c) => c.modelType == ModelType.text)
        .toList();

    // 如果没有配置，显示提示
    if (textConfigs.isEmpty) {
      return Container(
        width: 280,
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: _dividerColor),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 32)],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '暂无AI模型配置',
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
            SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                setState(() => _modelDropdownOpen = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
              child: Text('去配置'),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: _dividerColor),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 32)],
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...textConfigs.map(
            (config) => GestureDetector(
              onTap: () {
                // 更新选中的AI配置
                ref.read(selectedAiConfigProvider.notifier).state = config;
                setState(() {
                  _selectedModelDisplay = config.name;
                  _modelDropdownOpen = false;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selectedConfig?.id == config.id
                      ? cardBg2
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      config.name,
                      style: TextStyle(color: textPrimary, fontSize: 14),
                    ),
                    if (config.modelName.contains('GLM') ||
                        config.modelName.contains('glm')) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '内置',
                          style: TextStyle(color: primaryColor, fontSize: 10),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (selectedConfig?.id == config.id)
                      Icon(Icons.check, color: primaryColor, size: 18),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 1,
            color: dividerColor,
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
          GestureDetector(
            onTap: () {
              setState(() => _modelDropdownOpen = false);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                '管理模型',
                style: TextStyle(color: primaryColor, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleNovelExpand(String novelId) async {
    if (_expandedNovels.contains(novelId)) {
      setState(() => _expandedNovels.remove(novelId));
    } else {
      setState(() => _expandedNovels.add(novelId));
      if (!_loadedVolumes.containsKey(novelId)) {
        final volumes = await ref
            .read(volumeRepoProvider)
            .getVolumesByNovel(novelId);
        if (mounted) {
          setState(() {
            _loadedVolumes[novelId] = volumes;
          });
        }
      }
    }
  }

  void _toggleVolumeExpand(String volumeId) async {
    if (_expandedVolumes.contains(volumeId)) {
      setState(() => _expandedVolumes.remove(volumeId));
    } else {
      setState(() => _expandedVolumes.add(volumeId));
      if (!_loadedChapters.containsKey(volumeId)) {
        final chapters = await ref
            .read(chapterRepoProvider)
            .getChaptersByVolume(volumeId);
        if (mounted) {
          setState(() {
            _loadedChapters[volumeId] = chapters;
          });
        }
      }
    }
  }
}
