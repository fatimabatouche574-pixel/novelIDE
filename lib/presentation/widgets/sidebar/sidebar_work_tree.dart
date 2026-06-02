import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';
import 'package:novel_ide/data/models/chapter_model.dart';
import 'package:novel_ide/data/models/volume_model.dart';
import 'package:novel_ide/presentation/state/app_providers.dart';

/// 侧边栏可折叠作品树 - Novel / Volumes / Chapters
class SidebarWorkTree extends ConsumerStatefulWidget {
  const SidebarWorkTree({
    super.key,
    required this.textColor,
    required this.activeColor,
    required this.bg,
    required this.onChapterTap,
    required this.onCreateNovel,
  });
  final Color textColor;
  final Color activeColor;
  final Color bg;
  final void Function(String chapterId, String chapterTitle) onChapterTap;
  final VoidCallback onCreateNovel;
  @override
  ConsumerState<SidebarWorkTree> createState() => _State();
}

class _State extends ConsumerState<SidebarWorkTree> {
  bool _expanded = true;
  final Set<String> _openVols = {};
  Color get _c => widget.textColor;
  Color get _ac => widget.activeColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [_header(), if (_expanded) _body()],
  );

  Widget _header() => InkWell(
    onTap: () => setState(() => _expanded = !_expanded),
    borderRadius: BorderRadius.circular(UiTokens.cardRadius),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
      child: Row(
        children: [
          Icon(
            _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
            size: UiTokens.navIconSize,
            color: _c.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            '作品树',
            style: TextStyle(
              fontSize: UiTokens.microFS + 1,
              fontWeight: FontWeight.w600,
              color: _c.withValues(alpha: 0.4),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _body() {
    final na = ref.watch(novelsProvider);
    return na.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (novels) {
        if (novels.isEmpty) return _empty();
        final n = novels.first;
        final va = ref.watch(volumesProvider(n.id));
        final ca = ref.watch(chaptersProvider(n.id));
        return va.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (vols) => ca.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (chs) => _tree(n.title, vols, chs),
          ),
        );
      },
    );
  }

  Widget _tree(String title, List<Volume> vols, List<Chapter> chs) {
    final sel = ref.watch(selectedChapterProvider);
    final sorted = List<Volume>.from(vols)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final byVol = <String, List<Chapter>>{};
    for (final ch in chs) {
      byVol.putIfAbsent(ch.volumeId, () => []).add(ch);
    }
    for (final list in byVol.values) {
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              Icon(
                Icons.auto_stories,
                size: UiTokens.navIconSize,
                color: _c.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: UiTokens.bodyFS,
                    fontWeight: FontWeight.w600,
                    color: _c,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        for (final vol in sorted) ...[
          _volTile(vol),
          if (_openVols.contains(vol.id))
            for (final ch in (byVol[vol.id] ?? []))
              _chTile(ch, ch.id == sel?.id),
        ],
      ],
    );
  }

  Widget _volTile(Volume vol) {
    final open = _openVols.contains(vol.id);
    return InkWell(
      onTap: () => setState(
        () => open ? _openVols.remove(vol.id) : _openVols.add(vol.id),
      ),
      borderRadius: BorderRadius.circular(UiTokens.cardRadius),
      child: Padding(
        padding: const EdgeInsets.only(left: 28, right: 8),
        child: SizedBox(
          height: UiTokens.navItemHeight,
          child: Row(
            children: [
              Icon(
                open ? Icons.folder_open : Icons.folder,
                size: UiTokens.iconSize,
                color: _c,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  vol.title,
                  style: TextStyle(fontSize: UiTokens.smallFS + 1, color: _c),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                size: UiTokens.iconSize,
                color: _c.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chTile(Chapter ch, bool active) => InkWell(
    onTap: () => widget.onChapterTap(ch.id, ch.title),
    onLongPress: () => _showMenu(ch),
    borderRadius: BorderRadius.circular(UiTokens.cardRadius),
    child: Container(
      height: UiTokens.navItemHeight,
      padding: const EdgeInsets.only(left: 44, right: 8),
      decoration: active
          ? BoxDecoration(
              color: UiTokens.sidebarActiveBg,
              borderRadius: BorderRadius.circular(UiTokens.cardRadius),
              border: Border(left: BorderSide(color: _ac, width: 3)),
            )
          : null,
      child: Row(
        children: [
          Icon(
            Icons.description,
            size: UiTokens.iconSize,
            color: active ? _ac : _c.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              ch.title,
              style: TextStyle(
                fontSize: UiTokens.smallFS + 1,
                color: active ? _ac : _c,
                fontWeight: active ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _empty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    child: Column(
      children: [
        Text(
          '暂无作品',
          style: TextStyle(
            fontSize: UiTokens.smallFS,
            color: _c.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 28,
          child: TextButton(
            onPressed: widget.onCreateNovel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              '创建作品',
              style: TextStyle(fontSize: UiTokens.smallFS, color: _ac),
            ),
          ),
        ),
      ],
    ),
  );

  void _showMenu(Chapter ch) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('重命名'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: UiTokens.error),
              title: Text('删除', style: TextStyle(color: UiTokens.error)),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
