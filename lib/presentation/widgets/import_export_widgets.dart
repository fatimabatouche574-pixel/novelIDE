import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';
import 'package:novel_ide/data/models/novel_model.dart';
import 'package:novel_ide/data/models/chapter_model.dart';
import 'package:novel_ide/data/services/import_export_service.dart';
import 'package:novel_ide/data/services/novel_import_service.dart';

/// 导入预览卡片
class ImportPreviewCard extends StatelessWidget {
  const ImportPreviewCard({super.key, required this.preview});

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

/// 作品下拉选择器
class NovelDropdown extends StatelessWidget {
  const NovelDropdown({
    super.key,
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
class ChapterDropdown extends StatelessWidget {
  const ChapterDropdown({
    super.key,
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
class ScopeChip extends StatelessWidget {
  const ScopeChip({
    super.key,
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
