import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';
import 'package:novel_ide/data/datasources/database_helper.dart';
import 'package:novel_ide/data/models/memory/memory_entity.dart';
import 'package:novel_ide/data/models/memory/memory_repository.dart';
import 'package:novel_ide/presentation/pages/memory/memory_edit_page.dart';

const _folderColors = <String, Color>{
  '角色记忆': Color(0xFF4A90D9),
  '设定记忆': Color(0xFF4CAF50),
  '地点记忆': Color(0xFFFF9F43),
  '势力记忆': Color(0xFF9C27B0),
  '事件记忆': Color(0xFFFF6B6B),
  '道具记忆': Color(0xFF00BCD4),
  '对话摘要': Color(0xFF78909C),
};

class OperitMemoryLibraryPage extends ConsumerStatefulWidget {
  const OperitMemoryLibraryPage({super.key, this.novelId});
  final String? novelId;

  @override
  ConsumerState<OperitMemoryLibraryPage> createState() =>
      _OperitMemoryLibraryPageState();
}

class _OperitMemoryLibraryPageState
    extends ConsumerState<OperitMemoryLibraryPage> {
  List<Memory> _memories = [];
  List<MemoryLink> _links = [];
  List<Memory> _filtered = [];
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final db = await DatabaseHelper().database;
      final repo = MemoryRepository(
        db: db,
        profileId: widget.novelId ?? 'global',
      );
      final memories = await repo.searchMemories(
        query: '*',
        novelId: widget.novelId,
      );
      final allLinks = <MemoryLink>[];
      for (final m in memories) {
        allLinks.addAll(await repo.getOutgoingLinks(m.id));
      }
      if (!mounted) return;
      setState(() {
        _memories = memories;
        _links = allLinks;
        _applyFilter();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchQuery.toLowerCase();
    _filtered = q.isEmpty
        ? List.of(_memories)
        : _memories.where((m) => m.title.toLowerCase().contains(q)).toList();
  }

  Color _colorFor(Memory m) {
    final folder = m.folderPath ?? '';
    for (final e in _folderColors.entries) {
      if (folder.contains(e.key)) return e.value;
    }
    return UiTokens.primary;
  }

  void _navigateCreate() {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MemoryEditPage(novelId: widget.novelId),
      ),
    ).then((ok) {
      if (ok == true) _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆库'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              UiTokens.pagePadH,
              0,
              UiTokens.pagePadH,
              10,
            ),
            child: TextField(
              onChanged: (v) => setState(() {
                _searchQuery = v;
                _applyFilter();
              }),
              decoration: InputDecoration(
                hintText: '搜索记忆...',
                hintStyle: TextStyle(
                  fontSize: UiTokens.bodyFS,
                  color: UiTokens.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: UiTokens.onSurfaceVariant,
                ),
                filled: true,
                fillColor: UiTokens.surfaceVariant.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UiTokens.inputRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _filtered.isEmpty
          ? _buildEmpty()
          : _buildGraph(),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.auto_awesome_outlined,
          size: 56,
          color: UiTokens.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 12),
        Text(
          '暂无记忆',
          style: TextStyle(
            fontSize: UiTokens.titleFS,
            color: UiTokens.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _navigateCreate,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('创建记忆'),
        ),
      ],
    ),
  );

  Widget _buildGraph() {
    final idIndex = <int, int>{};
    for (int i = 0; i < _filtered.length; i++) {
      idIndex[_filtered[i].id] = i;
    }
    final edges = <(int, int, String)>[];
    for (final link in _links) {
      final si = idIndex[link.sourceId];
      final ti = idIndex[link.targetId];
      if (si != null && ti != null && si != ti) {
        edges.add((si, ti, link.type));
      }
    }
    final labels = _filtered.map((m) => m.title).toList();
    final colors = _filtered.map(_colorFor).toList();

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: _GraphPainter(
                  labels: labels,
                  colors: colors,
                  edges: edges,
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _navigateCreate,
            backgroundColor: UiTokens.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.labels,
    required this.colors,
    required this.edges,
  });

  final List<String> labels;
  final List<Color> colors;
  final List<(int, int, String)> edges;

  static const _r = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.length;
    if (n == 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final lr = min(size.width, size.height) * 0.35;

    final pos = <Offset>[];
    for (int i = 0; i < n; i++) {
      final a = -pi / 2 + 2 * pi * i / n;
      pos.add(Offset(cx + lr * cos(a), cy + lr * sin(a)));
    }

    final edgePaint = Paint()
      ..color = UiTokens.outlineVariant.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final e in edges) {
      canvas.drawLine(pos[e.$1], pos[e.$2], edgePaint);
      final mid = Offset(
        (pos[e.$1].dx + pos[e.$2].dx) / 2,
        (pos[e.$1].dy + pos[e.$2].dy) / 2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: e.$3,
          style: TextStyle(
            color: UiTokens.onSurfaceVariant,
            fontSize: UiTokens.microFS,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(mid.dx - tp.width / 2, mid.dy - tp.height / 2));
    }
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.08);
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (int i = 0; i < n; i++) {
      final p = pos[i];
      canvas.drawCircle(Offset(p.dx + 1, p.dy + 2), _r, shadowPaint);
      canvas.drawCircle(p, _r, Paint()..color = colors[i]);
      canvas.drawCircle(p, _r, borderPaint);
      final label = labels[i];
      final inner = label.length <= 2 ? label : label.substring(0, 2);
      final ip = TextPainter(
        text: TextSpan(
          text: inner,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ip.paint(canvas, Offset(p.dx - ip.width / 2, p.dy - ip.height / 2));

      if (label.length > 2) {
        final fp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: UiTokens.onSurface,
              fontSize: UiTokens.microFS,
              fontWeight: FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '...',
        )..layout(maxWidth: 64);
        fp.paint(canvas, Offset(p.dx - fp.width / 2, p.dy + _r + 4));
      }
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.labels != labels || old.colors != colors || old.edges != edges;
}
