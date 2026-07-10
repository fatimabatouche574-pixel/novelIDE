import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:novel_ide/core/theme/app_themes.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/data/models/ai_chat_session_model.dart';
import 'package:novel_ide/data/repositories/chat_history_repository.dart';
import 'package:novel_ide/presentation/state/app_providers.dart';

/// 真实的对话历史管理页：查看、切换、重命名与批量删除会话。
class OperitChatHistoryPage extends ConsumerStatefulWidget {
  const OperitChatHistoryPage({super.key, this.onSessionSelected});

  final ValueChanged<String>? onSessionSelected;

  @override
  ConsumerState<OperitChatHistoryPage> createState() =>
      _OperitChatHistoryPageState();
}

class _OperitChatHistoryPageState
    extends ConsumerState<OperitChatHistoryPage> {
  final ChatHistoryRepository _repository = ChatHistoryRepository();
  final Set<String> _selectedIds = {};
  List<AiChatSessionModel> _sessions = [];
  bool _isLoading = true;
  String? _error;
  int _storageSize = 0;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _repository.loadSessions();
      final storageSize = await _repository.getStorageSize();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _storageSize = storageSize;
        _isLoading = false;
        _error = null;
        _selectedIds.removeWhere(
          (id) => !sessions.any((session) => session.id == id),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '加载对话历史失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinThemeProvider);
    final currentSessionId = ref.watch(currentSessionIdProvider);

    return Scaffold(
      backgroundColor: skin.background,
      appBar: AppBar(
        backgroundColor: skin.surface,
        foregroundColor: skin.textPrimary,
        title: Text(
          _selectedIds.isEmpty ? '对话历史' : '已选 ${_selectedIds.length} 项',
        ),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '删除选中',
              onPressed: _confirmDeleteSelected,
            ),
          if (_sessions.isNotEmpty)
            TextButton(
              onPressed: _toggleSelectAll,
              child: Text(
                _selectedIds.length == _sessions.length ? '取消全选' : '全选',
                style: TextStyle(color: skin.primary),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSession,
        backgroundColor: skin.primary,
        foregroundColor: ThemeData.estimateBrightnessForColor(skin.primary) ==
                Brightness.dark
            ? Colors.white
            : Colors.black,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('新对话'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: skin.primary))
          : _error != null
          ? _buildError(skin)
          : RefreshIndicator(
              onRefresh: _loadSessions,
              color: skin.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildOverview(skin)),
                  if (_sessions.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(skin),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                      sliver: SliverList.builder(
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) => _buildSessionCard(
                          _sessions[index],
                          skin,
                          currentSessionId,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildOverview(SkinTheme skin) {
    final messageCount = _sessions.fold<int>(
      0,
      (total, session) => total + session.messageCount,
    );
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: skin.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildStat('对话', '${_sessions.length}', skin),
          _buildStat('消息', '$messageCount', skin),
          _buildStat('占用', _formatBytes(_storageSize), skin),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, SkinTheme skin) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: skin.primary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: skin.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(
    AiChatSessionModel session,
    SkinTheme skin,
    String? currentSessionId,
  ) {
    final isSelected = _selectedIds.contains(session.id);
    final isCurrent = session.id == currentSessionId;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected
          ? skin.primary.withValues(alpha: 0.12)
          : skin.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrent
              ? skin.primary.withValues(alpha: 0.65)
              : skin.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        onTap: () => _onSessionTap(session),
        onLongPress: () => _toggleSelection(session.id),
        leading: isSelected
            ? Icon(Icons.check_circle, color: skin.primary)
            : CircleAvatar(
                backgroundColor: skin.primary.withValues(alpha: 0.12),
                child: Icon(
                  isCurrent ? Icons.chat_bubble : Icons.chat_bubble_outline,
                  color: skin.primary,
                  size: 19,
                ),
              ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                session.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: skin.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isCurrent)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: skin.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '当前',
                  style: TextStyle(color: skin.primary, fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.lastMessagePreview.isEmpty
                    ? '暂无消息'
                    : session.lastMessagePreview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: skin.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                '${session.messageCount} 条消息 · ${DateFormat('MM-dd HH:mm').format(session.updatedAt)}',
                style: TextStyle(
                  color: skin.textSecondary.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        trailing: _selectedIds.isEmpty
            ? PopupMenuButton<String>(
                color: skin.surface,
                iconColor: skin.textSecondary,
                onSelected: (value) {
                  if (value == 'rename') _renameSession(session);
                  if (value == 'delete') _confirmDelete({session.id});
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'rename', child: Text('重命名')),
                  const PopupMenuItem(value: 'delete', child: Text('删除')),
                ],
              )
            : Checkbox(
                value: isSelected,
                activeColor: skin.primary,
                onChanged: (_) => _toggleSelection(session.id),
              ),
      ),
    );
  }

  Widget _buildEmptyState(SkinTheme skin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 52,
              color: skin.textSecondary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text('还没有对话记录', style: TextStyle(color: skin.textPrimary)),
            const SizedBox(height: 5),
            Text(
              '新建对话后，每个会话都会单独保存',
              style: TextStyle(color: skin.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(SkinTheme skin) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 42),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: skin.textPrimary)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _loadSessions, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  void _onSessionTap(AiChatSessionModel session) {
    if (_selectedIds.isNotEmpty) {
      _toggleSelection(session.id);
      return;
    }
    ref.read(currentSessionIdProvider.notifier).state = session.id;
    widget.onSessionSelected?.call(session.id);
  }

  Future<void> _createSession() async {
    final session = AiChatSessionModel.create(
      title: '新对话 ${_sessions.length + 1}',
    );
    await _repository.saveSession(session);
    if (!mounted) return;
    ref.read(currentSessionIdProvider.notifier).state = session.id;
    widget.onSessionSelected?.call(session.id);
  }

  Future<void> _renameSession(AiChatSessionModel session) async {
    final controller = TextEditingController(text: session.title);
    final skin = ref.read(skinThemeProvider);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: skin.surface,
        title: Text('重命名对话', style: TextStyle(color: skin.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          style: TextStyle(color: skin.textPrimary),
          decoration: const InputDecoration(hintText: '输入对话名称'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle == null || newTitle.isEmpty || newTitle == session.title) return;
    session.title = newTitle;
    session.touch();
    await _repository.saveSession(session);
    await _loadSessions();
  }

  void _toggleSelection(String sessionId) {
    setState(() {
      if (!_selectedIds.add(sessionId)) _selectedIds.remove(sessionId);
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _sessions.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_sessions.map((session) => session.id));
      }
    });
  }

  void _confirmDeleteSelected() => _confirmDelete(Set.of(_selectedIds));

  Future<void> _confirmDelete(Set<String> ids) async {
    if (ids.isEmpty) return;
    final skin = ref.read(skinThemeProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: skin.surface,
        title: Text('删除对话', style: TextStyle(color: skin.textPrimary)),
        content: Text(
          '确定删除选中的 ${ids.length} 个对话吗？此操作无法撤销。',
          style: TextStyle(color: skin.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _repository.deleteSessions(ids);
    if (!mounted) return;
    final currentId = ref.read(currentSessionIdProvider);
    if (currentId != null && ids.contains(currentId)) {
      final remaining = await _repository.loadSessions();
      ref.read(currentSessionIdProvider.notifier).state = remaining.firstOrNull?.id;
    }
    _selectedIds.clear();
    await _loadSessions();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
    return '${(kilobytes / 1024).toStringAsFixed(1)} MB';
  }
}
