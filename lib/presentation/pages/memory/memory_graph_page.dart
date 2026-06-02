import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/app_themes.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/data/datasources/database_helper.dart';
import 'package:novel_ide/data/models/memory/memory_entity.dart';
import 'package:novel_ide/data/models/memory/memory_repository.dart';

class MemoryGraphPage extends ConsumerStatefulWidget {
  const MemoryGraphPage({super.key});

  @override
  ConsumerState<MemoryGraphPage> createState() => _MemoryGraphPageState();
}

class _MemoryGraphPageState extends ConsumerState<MemoryGraphPage> {
  List<Memory> _memories = [];
  List<MemoryLink> _links = [];
  bool _isLoading = true;
  int? _selectedNodeId;
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final db = await DatabaseHelper().database;
      final repo = MemoryRepository(db: db, profileId: 'global');
      final memories = await repo.searchMemories(query: '*');
      final links = await repo.getMemoryGraph();
      if (mounted) {
        setState(() {
          _memories = memories;
          _links = links;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinThemeProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('记忆图谱'),
          backgroundColor: skin.appBarBg,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_memories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('记忆图谱'),
          backgroundColor: skin.appBarBg,
        ),
        body: Center(
          child: Text('暂无记忆数据', style: TextStyle(color: skin.textSecondary)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('记忆图谱'),
        backgroundColor: skin.appBarBg,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 3.0,
              child: GestureDetector(
                onTapUp: (details) =>
                    _onNodeTap(details.localPosition, skin),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _MemoryGraphPainter(
                    memories: _memories,
                    links: _links,
                    selectedNodeId: _selectedNodeId,
                    skin: skin,
                  ),
                ),
              ),
            ),
          ),
          _buildStatsBar(skin),
        ],
      ),
    );
  }

  void _onNodeTap(Offset tapPosition, SkinTheme skin) {
    final size = context.size ?? Size.zero;
    for (final memory in _memories) {
      final center = _getNodePosition(memory.id, size);
      if (center == null) continue;
      final distance = (tapPosition - center).distance;
      final radius = memory.importance * 20 + 10;
      if (distance <= radius) {
        setState(() => _selectedNodeId = memory.id);
        _showNodeDetail(memory, skin);
        return;
      }
    }
  }

  Offset? _getNodePosition(int memoryId, Size size) {
    final index = _memories.indexWhere((m) => m.id == memoryId);
    if (index < 0) return null;
    final n = _memories.length;
    final canvasSize = min(size.width, size.height);
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = canvasSize * 0.35;
    final angle = 2 * pi * index / n;
    return Offset(
      centerX + radius * cos(angle),
      centerY + radius * sin(angle),
    );
  }

  void _showNodeDetail(Memory memory, SkinTheme skin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: skin.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              memory.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: skin.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (memory.content.isNotEmpty)
              Text(
                memory.content.length > 200
                    ? '${memory.content.substring(0, 200)}...'
                    : memory.content,
                style: TextStyle(color: skin.textSecondary),
              ),
            const SizedBox(height: 8),
            if (memory.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: memory.tags
                    .map(
                      (t) => Chip(
                        label: Text(
                          t.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 4),
            Text(
              '来源: ${memory.source}',
              style: TextStyle(color: skin.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              '重要性: ${(memory.importance * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: skin.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(SkinTheme skin) {
    return Container(
      height: 48,
      color: skin.appBarBg,
      alignment: Alignment.center,
      child: Text(
        '节点: ${_memories.length} | 连线: ${_links.length}',
        style: TextStyle(color: skin.textSecondary),
      ),
    );
  }
}

class _MemoryGraphPainter extends CustomPainter {
  final List<Memory> memories;
  final List<MemoryLink> links;
  final int? selectedNodeId;
  final SkinTheme skin;

  _MemoryGraphPainter({
    required this.memories,
    required this.links,
    this.selectedNodeId,
    required this.skin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 先画连线
    for (final link in links) {
      final sourcePos = _getNodePosition(link.sourceId, size);
      final targetPos = _getNodePosition(link.targetId, size);
      if (sourcePos == null || targetPos == null) continue;

      final paint = Paint()
        ..color = skin.textSecondary.withValues(alpha: 0.3)
        ..strokeWidth = link.weight * 2 + 0.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(sourcePos, targetPos, paint);

      // 中点画 type 标签
      final mid = Offset(
        (sourcePos.dx + targetPos.dx) / 2,
        (sourcePos.dy + targetPos.dy) / 2,
      );
      final typePainter = TextPainter(
        text: TextSpan(
          text: link.type,
          style: TextStyle(color: skin.textSecondary, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bgRect = Rect.fromCenter(
        center: mid,
        width: typePainter.width + 6,
        height: typePainter.height + 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
        Paint()..color = skin.cardBg,
      );
      typePainter.paint(
        canvas,
        Offset(mid.dx - typePainter.width / 2, mid.dy - typePainter.height / 2),
      );
    }

    // 2. 再画节点
    for (int i = 0; i < memories.length; i++) {
      final memory = memories[i];
      final center = _getNodePosition(memory.id, size);
      if (center == null) continue;

      final radius = memory.importance * 20 + 10;
      final isSelected = memory.id == selectedNodeId;

      // 填充
      canvas.drawCircle(center, radius, Paint()..color = skin.surface);
      // 边框
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = skin.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 4.0 : 2.0,
      );

      // 文字
      final displayTitle = memory.title.length > 6
          ? '${memory.title.substring(0, 6)}...'
          : memory.title;
      final textPainter = TextPainter(
        text: TextSpan(
          text: displayTitle,
          style: TextStyle(color: skin.textPrimary, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * 2);
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
      );
    }
  }

  Offset? _getNodePosition(int memoryId, Size size) {
    final index = memories.indexWhere((m) => m.id == memoryId);
    if (index < 0) return null;
    final n = memories.length;
    final canvasSize = min(size.width, size.height);
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = canvasSize * 0.35;
    final angle = 2 * pi * index / n;
    return Offset(
      centerX + radius * cos(angle),
      centerY + radius * sin(angle),
    );
  }

  @override
  bool shouldRepaint(_MemoryGraphPainter oldDelegate) =>
      oldDelegate.memories != memories ||
      oldDelegate.links != links ||
      oldDelegate.selectedNodeId != selectedNodeId ||
      oldDelegate.skin != skin;
}
