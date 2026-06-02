import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/data/datasources/database_helper.dart';
import 'package:novel_ide/data/models/memory/memory_entity.dart';
import 'package:novel_ide/data/models/memory/memory_repository.dart';

/// 记忆编辑/创建页面
/// null memory = 创建模式，非 null = 编辑模式
class MemoryEditPage extends ConsumerStatefulWidget {
  const MemoryEditPage({super.key, this.memory, this.novelId});

  final Memory? memory;
  final String? novelId;

  @override
  ConsumerState<MemoryEditPage> createState() => _MemoryEditPageState();
}

class _MemoryEditPageState extends ConsumerState<MemoryEditPage> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _tagsCtrl;
  late TextEditingController _sourceCtrl;
  double _importance = 0.5;
  String _source = 'user_input';
  bool _isSaving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    final memory = widget.memory;
    _titleCtrl = TextEditingController(text: memory?.title ?? '');
    _contentCtrl = TextEditingController(text: memory?.content ?? '');
    _tagsCtrl = TextEditingController(
      text: memory?.tags.map((t) => t.name).join(', ') ?? '',
    );
    _sourceCtrl = TextEditingController(text: memory?.source ?? 'user_input');
    if (memory != null) {
      _importance = memory.importance;
      _source = memory.source;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagsCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final db = await DatabaseHelper().database;
      final repo = MemoryRepository(
        db: db,
        profileId: widget.novelId ?? 'global',
      );

      final tags = _tagsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (widget.memory == null) {
        // 创建模式
        final created = await repo.createMemory(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text,
          source: _source,
          tags: tags,
        );
        if (created != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('创建成功')),
          );
          Navigator.pop(context, true);
        }
      } else {
        // 编辑模式
        final updated = await repo.updateMemory(
          memory: widget.memory!,
          newTitle: _titleCtrl.text.trim(),
          newContent: _contentCtrl.text,
          newSource: _source,
          newImportance: _importance,
          newTags: tags,
        );
        if (updated != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存成功')),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memory != null ? '编辑记忆' : '创建记忆'),
        backgroundColor: skin.appBarBg,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('保存'),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: skin.surface,
                labelStyle: TextStyle(color: skin.textSecondary),
              ),
              style: TextStyle(color: skin.textPrimary),
              onChanged: (_) => _markDirty(),
            ),
            const SizedBox(height: 16),
            // 内容
            TextField(
              controller: _contentCtrl,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: skin.surface,
                labelStyle: TextStyle(color: skin.textSecondary),
                alignLabelWithHint: true,
              ),
              style: TextStyle(color: skin.textPrimary),
              onChanged: (_) => _markDirty(),
            ),
            const SizedBox(height: 16),
            // 标签
            TextField(
              controller: _tagsCtrl,
              decoration: InputDecoration(
                labelText: '标签（逗号分隔）',
                hintText: '例如: 人物,事件,设定',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: skin.surface,
                labelStyle: TextStyle(color: skin.textSecondary),
                hintStyle: TextStyle(color: skin.textSecondary),
              ),
              style: TextStyle(color: skin.textPrimary),
              onChanged: (_) => _markDirty(),
            ),
            const SizedBox(height: 16),
            // 重要性滑块
            Row(
              children: [
                Text(
                  '重要性',
                  style: TextStyle(color: skin.textPrimary),
                ),
                Expanded(
                  child: Slider(
                    value: _importance,
                    onChanged: (v) => setState(() => _importance = v),
                  ),
                ),
                Text(
                  '${(_importance * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: skin.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 来源
            TextField(
              controller: _sourceCtrl,
              decoration: InputDecoration(
                labelText: '来源',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: skin.surface,
                labelStyle: TextStyle(color: skin.textSecondary),
              ),
              style: TextStyle(color: skin.textPrimary),
              onChanged: (v) => setState(() => _source = v),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
