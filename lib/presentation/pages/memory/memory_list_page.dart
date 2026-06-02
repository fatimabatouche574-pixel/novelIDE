import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/app_themes.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/data/datasources/database_helper.dart';
import 'package:novel_ide/data/models/memory/memory_entity.dart';
import 'package:novel_ide/data/models/memory/memory_repository.dart';
import 'package:novel_ide/presentation/pages/memory/memory_edit_page.dart';

class MemoryListPage extends ConsumerStatefulWidget {
  const MemoryListPage({super.key, this.novelId});

  final String? novelId;

  @override
  ConsumerState<MemoryListPage> createState() => _MemoryListPageState();
}

class _MemoryListPageState extends ConsumerState<MemoryListPage> {
  List<Memory> _memories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();

  // 文件夹筛选
  String? _selectedFolder;
  List<String> _folders = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final db = await DatabaseHelper().database;
      final repo = MemoryRepository(
        db: db,
        profileId: widget.novelId ?? 'global',
      );
      final memories = await repo.searchMemories(
        query: '*',
        folderPath: _selectedFolder,
      );
      final folders = await repo.getAllFolderPaths(
        novelId: widget.novelId,
      );
      if (mounted) {
        setState(() {
          _memories = memories;
          _folders = folders;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text;
    if (query == _searchQuery) return;
    _searchQuery = query;
    _performSearch();
  }

  Future<void> _performSearch() async {
    try {
      final db = await DatabaseHelper().database;
      final repo = MemoryRepository(
        db: db,
        profileId: widget.novelId ?? 'global',
      );
      final query = _searchQuery.trim();
      final results = await repo.searchMemories(
        query: query.isEmpty ? '*' : query,
        folderPath: _selectedFolder,
      );
      if (mounted) {
        setState(() => _memories = results);
      }
    } catch (_) {
      // 搜索失败时静默处理
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchCtrl.clear();
        _searchQuery = '';
        _loadData();
      }
    });
  }

  Future<void> _navigateToEdit(Memory? memory) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MemoryEditPage(memory: memory)),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _confirmDelete(Memory memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定删除"${memory.title}"？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final db = await DatabaseHelper().database;
      final repo = MemoryRepository(
        db: db,
        profileId: widget.novelId ?? 'global',
      );
      await repo.deleteMemory(memory.id);
      _loadData();
    } catch (_) {
      // 删除失败时静默处理
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆管理'),
        backgroundColor: skin.appBarBg,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearch) _buildSearchBar(skin),
          if (_folders.isNotEmpty) _buildFolderFilter(skin),
          Expanded(child: _buildBody(skin)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar(SkinTheme skin) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: skin.surface,
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '搜索记忆...',
          hintStyle: TextStyle(color: skin.textSecondary),
          prefixIcon: Icon(Icons.search, color: skin.textSecondary),
          filled: true,
          fillColor: skin.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(color: skin.textPrimary),
      ),
    );
  }

  Widget _buildFolderFilter(SkinTheme skin) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFolderChip(null, '全部', skin),
          ..._folders.map((f) => _buildFolderChip(f, f, skin)),
        ],
      ),
    );
  }

  Widget _buildFolderChip(String? folder, String label, SkinTheme skin) {
    final selected = _selectedFolder == folder;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFolder = folder);
          _performSearch();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? skin.primary.withValues(alpha: 0.15)
                : skin.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? skin.primary.withValues(alpha: 0.4)
                  : skin.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: selected ? skin.primary : skin.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(SkinTheme skin) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_memories.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.memory_outlined,
              size: 64,
              color: skin.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无记忆，点击右下角创建',
              style: TextStyle(fontSize: 16, color: skin.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _memories.length,
        itemBuilder: (context, index) {
          final memory = _memories[index];
          return _buildMemoryCard(memory, skin);
        },
      ),
    );
  }

  Widget _buildMemoryCard(Memory memory, SkinTheme skin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToEdit(memory),
        onLongPress: () => _confirmDelete(memory),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Text(
                memory.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: skin.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // 内容预览
              if (memory.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    memory.content,
                    style: TextStyle(fontSize: 14, color: skin.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // 底部信息行
              Row(
                children: [
                  // 重要性徽章
                  _buildImportanceBadge(memory.importance, skin),
                  const SizedBox(width: 8),

                  // 标签
                  if (memory.tags.isNotEmpty) ...[
                    ...memory.tags
                        .take(3)
                        .map(
                          (tag) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _buildTagChip(tag, skin),
                          ),
                        ),
                    if (memory.tags.length > 3)
                      Text(
                        '+${memory.tags.length - 3}',
                        style: TextStyle(
                          fontSize: 12,
                          color: skin.textSecondary,
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],

                  // 来源 + 文件夹
                  if (memory.source.isNotEmpty)
                    Text(
                      memory.source,
                      style: TextStyle(fontSize: 12, color: skin.textSecondary),
                    ),
                  if (memory.folderPath != null &&
                      memory.folderPath!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.folder_outlined,
                      size: 12,
                      color: skin.textSecondary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      memory.folderPath!,
                      style: TextStyle(fontSize: 11, color: skin.textSecondary),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportanceBadge(double importance, SkinTheme skin) {
    final bgColor = _importanceColor(importance);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${(importance * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: bgColor,
        ),
      ),
    );
  }

  Color _importanceColor(double importance) {
    if (importance >= 0.8) return Colors.red;
    if (importance >= 0.5) return Colors.orange;
    if (importance >= 0.3) return Colors.blue;
    return Colors.grey;
  }

  Widget _buildTagChip(MemoryTag tag, SkinTheme skin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: skin.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        tag.name,
        style: TextStyle(fontSize: 12, color: skin.primary),
      ),
    );
  }
}
