import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';
import 'package:novel_ide/data/services/import_export_service.dart';
import 'package:novel_ide/data/services/novel_import_service.dart';
import 'package:novel_ide/presentation/state/app_providers.dart';
import 'package:novel_ide/presentation/widgets/import_export_widgets.dart';

/// 导入/导出弹窗
/// 两个 Tab："导入" 和 "导出"
/// [initialTab] 0=导入, 1=导出
Future<void> showImportExportDialog(
  BuildContext context, {
  int initialTab = 0,
}) {
  return showDialog(
    context: context,
    builder: (_) => ImportExportDialog(initialTab: initialTab),
  );
}

class ImportExportDialog extends StatelessWidget {
  const ImportExportDialog({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiTokens.cardRadius * 2),
        ),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 顶部 Tab 栏
              Container(
                decoration: BoxDecoration(
                  color: UiTokens.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(UiTokens.cardRadius * 2),
                  ),
                ),
                child: TabBar(
                  labelColor: UiTokens.primary,
                  unselectedLabelColor: UiTokens.onSurfaceVariant,
                  indicatorColor: UiTokens.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(icon: Icon(Icons.file_upload), text: '导入'),
                    Tab(icon: Icon(Icons.file_download), text: '导出'),
                  ],
                ),
              ),
              // Tab 内容
              Flexible(
                child: TabBarView(
                  children: [
                    _ImportTab(),
                    _ExportTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  导入 Tab
// ════════════════════════════════════════════════════════════════

class _ImportTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends ConsumerState<_ImportTab> {
  final _service = ImportExportService();

  String? _filePath;
  ImportPreview? _preview;
  bool _isLoading = false;
  String? _error;

  Future<void> _doPickFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _preview = null;
      _filePath = null;
    });

    try {
      final pickResult = await _service.pickAndPreview();
      if (pickResult == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _filePath = pickResult.filePath;
        _preview = pickResult.preview;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '预览失败: $e';
      });
    }
  }

  Future<void> _doImport() async {
    if (_filePath == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await _service.importFromPath(filePath: _filePath!);
      if (!mounted) return;

      if (result.success) {
        ref.invalidate(novelsProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '导入成功: ${result.chapterCount} 章, '
              '${result.totalWords} 字',
            ),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _error = result.error ?? '导入失败';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '导入异常: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 选择文件按钮
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _doPickFile,
            icon: const Icon(Icons.folder_open, size: 20),
            label: const Text('选择文件'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: UiTokens.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UiTokens.cardRadius),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '支持 TXT / Markdown / DOCX / EPUB / JSON',
            style: TextStyle(
              fontSize: UiTokens.smallFS,
              color: UiTokens.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: UiTokens.errorContainer,
                borderRadius: BorderRadius.circular(UiTokens.cardRadius),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  fontSize: UiTokens.bodyFS,
                  color: UiTokens.error,
                ),
              ),
            ),
          ],

          if (_preview != null) ...[
            const SizedBox(height: 14),
            _PreviewCard(preview: _preview!),
          ],

          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],

          if (_preview != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _doImport,
              style: FilledButton.styleFrom(
                backgroundColor: UiTokens.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(UiTokens.cardRadius),
                ),
              ),
              child: const Text('开始导入'),
            ),
          ],
        ],
      ),
    );
  }
}

/// 导入预览卡片
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});

  final ImportPreview preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: UiTokens.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(UiTokens.cardRadius),
        border: Border.all(
          color: UiTokens.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, size: 16, color: UiTokens.primary),
              const SizedBox(width: 6),
              Text(
                '导入预览',
                style: TextStyle(
                  fontSize: UiTokens.bodyFS,
                  fontWeight: FontWeight.w600,
                  color: UiTokens.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _infoRow('类型', preview.detectedType),
          _infoRow('识别来源', preview.matchSource),
          _infoRow('章节数', '${preview.chapters.length}'),
          _infoRow('总字数', _formatWords(preview.totalWords)),
          if (preview.chapters.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '章节列表:',
              style: TextStyle(
                fontSize: UiTokens.smallFS,
                fontWeight: FontWeight.w500,
                color: UiTokens.onSurfaceVariant,
              ),
            ),
            ...preview.chapters.take(5).map(
              (ch) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '· ${ch.title}',
                  style: TextStyle(
                    fontSize: UiTokens.smallFS,
                    color: UiTokens.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (preview.chapters.length > 5)
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '...还有 ${preview.chapters.length - 5} 章',
                  style: TextStyle(
                    fontSize: UiTokens.smallFS,
                    color: UiTokens.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: UiTokens.smallFS,
                color: UiTokens.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: UiTokens.smallFS,
                fontWeight: FontWeight.w500,
                color: UiTokens.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatWords(int words) {
    if (words >= 10000) {
      return '${(words / 10000).toStringAsFixed(1)} 万字';
    }
    return '$words 字';
  }
}

// ════════════════════════════════════════════════════════════════
//  导出 Tab
// ════════════════════════════════════════════════════════════════

class _ExportTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ExportTab> createState() => _ExportTabState();
}

class _ExportTabState extends ConsumerState<_ExportTab> {
  final _service = ImportExportService();

  Novel? _selectedNovel;
  ExportFormat _format = ExportFormat.txt;
  bool _isFullNovel = true;
  Chapter? _selectedChapter;
  bool _isExporting = false;
  String? _error;
  List<Chapter>? _chapters;

  @override
  void initState() {
    super.initState();
    // 延迟到 build 完成后自动选中当前小说
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selected = ref.read(selectedNovelProvider);
      if (selected != null) {
        setState(() => _selectedNovel = selected);
        _loadChapters(selected.id);
      }
    });
  }

  Future<void> _loadChapters(String novelId) async {
    try {
      final chapters = await ref.read(chapterRepoProvider).getChaptersByNovel(novelId);
      if (mounted) setState(() => _chapters = chapters);
    } catch (_) {}
  }

  Future<void> _doExport() async {
    if (_selectedNovel == null) {
      setState(() => _error = '请先选择作品');
      return;
    }

    setState(() {
      _isExporting = true;
      _error = null;
    });

    try {
      List<Chapter>? chapters;
      if (!_isFullNovel && _selectedChapter != null) {
        // 确保章节有内容
        final fullChapter = await ref
            .read(chapterRepoProvider)
            .getChapter(_selectedChapter!.id);
        if (fullChapter != null) {
          chapters = [fullChapter];
        }
      }

      final result = await _service.exportNovel(
        novel: _selectedNovel!,
        format: _format,
        selectedChapters: chapters,
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出: ${result.filePath}')),
        );
      } else {
        setState(() {
          _isExporting = false;
          _error = result.error ?? '导出失败';
        });
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
        _error = '导出异常: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final novelsAsync = ref.watch(novelsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 作品选择器
          novelsAsync.when(
            data: (novels) => _NovelDropdown(
              novels: novels,
              selected: _selectedNovel,
              onChanged: (novel) {
                setState(() {
                  _selectedNovel = novel;
                  _selectedChapter = null;
                  _chapters = null;
                });
                if (novel != null) _loadChapters(novel.id);
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('加载作品失败: $e'),
          ),
          const SizedBox(height: 12),

          // 导出范围
          Text(
            '导出范围',
            style: TextStyle(
              fontSize: UiTokens.bodyFS,
              fontWeight: FontWeight.w500,
              color: UiTokens.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _ScopeChip(
                  label: '整部小说',
                  selected: _isFullNovel,
                  onTap: () => setState(() => _isFullNovel = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScopeChip(
                  label: '单个章节',
                  selected: !_isFullNovel,
                  onTap: () => setState(() => _isFullNovel = false),
                ),
              ),
            ],
          ),

          // 章节选择器（单章节模式）
          if (!_isFullNovel) ...[
            const SizedBox(height: 10),
            _ChapterDropdown(
              chapters: _chapters ?? [],
              selected: _selectedChapter,
              onChanged: (ch) => setState(() => _selectedChapter = ch),
            ),
          ],
          const SizedBox(height: 12),

          // 格式选择
          Text(
            '导出格式',
            style: TextStyle(
              fontSize: UiTokens.bodyFS,
              fontWeight: FontWeight.w500,
              color: UiTokens.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ExportFormat.values.map((fmt) {
              final selected = _format == fmt;
              return ChoiceChip(
                label: Text(fmt.label),
                selected: selected,
                onSelected: (_) => setState(() => _format = fmt),
                selectedColor: UiTokens.primaryContainer,
                labelStyle: TextStyle(
                  fontSize: UiTokens.smallFS + 1,
                  color: selected
                      ? UiTokens.onPrimaryContainer
                      : UiTokens.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: UiTokens.errorContainer,
                borderRadius: BorderRadius.circular(UiTokens.cardRadius),
              ),
              child: Text(
                _error!,
                style: TextStyle(
                  fontSize: UiTokens.bodyFS,
                  color: UiTokens.error,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isExporting ? null : _doExport,
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.file_download, size: 18),
            label: Text(_isExporting ? '导出中...' : '开始导出'),
            style: FilledButton.styleFrom(
              backgroundColor: UiTokens.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UiTokens.cardRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 作品下拉选择器
class _NovelDropdown extends StatelessWidget {
  const _NovelDropdown({
    required this.novels,
    required this.selected,
    required this.onChanged,
  });

  final List<Novel> novels;
  final Novel? selected;
  final ValueChanged<Novel?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Novel>(
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: '选择作品',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiTokens.cardRadius),
        ),
      ),
      items: novels
          .map(
            (n) => DropdownMenuItem(
              value: n,
              child: Text(
                n.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: UiTokens.bodyFS + 1),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// 章节下拉选择器
class _ChapterDropdown extends StatelessWidget {
  const _ChapterDropdown({
    required this.chapters,
    required this.selected,
    required this.onChanged,
  });

  final List<Chapter> chapters;
  final Chapter? selected;
  final ValueChanged<Chapter?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Chapter>(
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: '选择章节',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UiTokens.cardRadius),
        ),
      ),
      items: chapters
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(
                '${c.orderIndex + 1}. ${c.title}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: UiTokens.bodyFS + 1),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// 范围选择 Chip
class _ScopeChip extends StatelessWidget {
  const _ScopeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? UiTokens.primaryContainer
              : UiTokens.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(UiTokens.cardRadius),
          border: Border.all(
            color: selected
                ? UiTokens.primary.withValues(alpha: 0.4)
                : UiTokens.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: UiTokens.bodyFS + 1,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected
                  ? UiTokens.onPrimaryContainer
                  : UiTokens.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
