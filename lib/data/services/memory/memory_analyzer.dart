import 'dart:convert';
import 'dart:developer' as developer;
import 'package:novel_ide/data/models/ai_config_model.dart';
import 'package:novel_ide/data/models/memory/memory_entity.dart';
import 'package:novel_ide/data/models/memory/memory_repository.dart';
import 'package:novel_ide/data/services/ai_service.dart';

// =================================================================
// 内部数据类
// =================================================================
class _ParsedEntity {
  final String title, content, folderPath;
  final List<String> tags;
  final String? aliasFor;
  const _ParsedEntity({
    required this.title,
    required this.content,
    this.tags = const [],
    this.aliasFor,
    this.folderPath = '',
  });
}

class _ParsedLink {
  final String sourceTitle, targetTitle, type, description;
  final double weight;
  const _ParsedLink({
    required this.sourceTitle,
    required this.targetTitle,
    required this.type,
    this.description = '',
    this.weight = 1.0,
  });
}

class _ParsedUpdate {
  final String titleToUpdate, newContent, reason;
  final double? newCredibility, newImportance;
  const _ParsedUpdate({
    required this.titleToUpdate,
    required this.newContent,
    required this.reason,
    this.newCredibility,
    this.newImportance,
  });
}

class _ParsedMerge {
  final List<String> sourceTitles, newTags;
  final String newTitle, newContent, folderPath, reason;
  const _ParsedMerge({
    required this.sourceTitles,
    required this.newTitle,
    required this.newContent,
    this.newTags = const [],
    this.folderPath = '',
    this.reason = '',
  });
}

class _ParsedAnalysis {
  final _ParsedEntity? mainProblem;
  final List<_ParsedEntity> entities;
  final List<_ParsedLink> links;
  final List<_ParsedUpdate> updates;
  final List<_ParsedMerge> merges;
  const _ParsedAnalysis({
    this.mainProblem,
    this.entities = const [],
    this.links = const [],
    this.updates = const [],
    this.merges = const [],
  });
  bool get isEmpty =>
      mainProblem == null &&
      entities.isEmpty &&
      links.isEmpty &&
      updates.isEmpty &&
      merges.isEmpty;
}

/// analyzeAndSave 的返回结果。
class AnalysisResult {
  final int createdCount, updatedCount, linkedCount;
  const AnalysisResult({
    this.createdCount = 0,
    this.updatedCount = 0,
    this.linkedCount = 0,
  });
}

// =================================================================
// MemoryAnalyzer
// =================================================================

/// 从对话历史中提取知识图谱（移植自 Operit，适配小说写作场景）。
class MemoryAnalyzer {
  final MemoryRepository _repo;
  final AiService _aiService;

  const MemoryAnalyzer({
    required MemoryRepository repository,
    required AiService aiService,
  }) : _repo = repository,
       _aiService = aiService;

  /// 从对话历史中提取知识图谱并持久化。
  Future<AnalysisResult> analyzeAndSave({
    required AiConfig config,
    required List<Map<String, String>> conversationHistory,
    String query = '',
    String solution = '',
  }) async {
    try {
      final processed = conversationHistory
          .where((m) => m['role'] != 'system')
          .toList();
      if (processed.isEmpty) return const AnalysisResult();
      final effectiveQuery = query.isNotEmpty
          ? query
          : processed.lastWhere(
                  (m) => m['role'] == 'user',
                  orElse: () => {'content': ''},
                )['content'] ??
                '';
      if (effectiveQuery.isEmpty) return const AnalysisResult();
      final effectiveSolution = solution.isNotEmpty
          ? solution
          : processed.lastWhere(
                  (m) => m['role'] == 'assistant',
                  orElse: () => {'content': ''},
                )['content'] ??
                '';
      final candidates = await _repo
          .searchMemories(query: '$effectiveQuery $effectiveSolution')
          .then((l) => l.take(15).toList());
      final folders = await _repo.getAllFolderPaths();
      final result = await _aiService.send(
        config: config,
        systemPrompt: _buildSystemPrompt(candidates, folders),
        userMessage: _buildAnalysisMsg(
          effectiveQuery,
          effectiveSolution,
          processed,
        ),
        taskType: 'memory_analysis',
      );
      final analysis = _parseResult(result);
      if (analysis.isEmpty) return const AnalysisResult();
      return await _apply(analysis);
    } on Exception catch (e) {
      developer.log('记忆分析失败: $e');
      return const AnalysisResult();
    }
  }

  /// 批量对未分类记忆进行 AI 自动归类（每批 [batchSize] 条，默认 10）。
  Future<int> autoCategorize({
    required AiConfig config,
    String novelId = '',
    int batchSize = 10,
  }) async {
    try {
      final all = await _repo.searchMemories(
        query: '*',
        novelId: novelId.isNotEmpty ? novelId : null,
      );
      final uncategorized = all
          .where(
            (m) =>
                (m.folderPath == null || m.folderPath!.isEmpty) &&
                m.title != '.folder_placeholder' &&
                m.title != '文件夹说明',
          )
          .toList();
      if (uncategorized.isEmpty) return 0;
      int total = 0;
      for (var i = 0; i < uncategorized.length; i += batchSize) {
        final end = (i + batchSize > uncategorized.length)
            ? uncategorized.length
            : i + batchSize;
        total += await _categorizeBatch(
          config: config,
          memories: uncategorized.sublist(i, end),
        );
      }
      developer.log('自动归类: $total / ${uncategorized.length}');
      return total;
    } on Exception catch (e) {
      developer.log('自动归类失败: $e');
      return 0;
    }
  }

  // =============================================================
  // 系统提示词（小说知识库专用）
  // =============================================================
  String _buildSystemPrompt(List<Memory> candidates, List<String> folders) {
    final dup = _dupHint(candidates);
    final mem = candidates.isNotEmpty
        ? '【已有记忆】\n${candidates.map((m) {
            final p = m.content.replaceAll('\n', ' ');
            return '- "${m.title}": '
                '${p.length > 120 ? '${p.substring(0, 120)}...' : p}';
          }).join('\n')}'
        : '';
    final fld = folders.isNotEmpty ? '\n【已有文件夹】${folders.join("、")}' : '';
    return '从对话中构建小说知识图谱。$dup$mem$fld\n\n'
        '只记小说特异性知识(角色/情节/世界观/地点/势力/伏笔/道具)，'
        '不记通用常识或TODO，无价值返回{}。\n'
        '优先update/merge，new最多5条。'
        '已有记忆可直接操作。改写旧概念main=null只用update。\n'
        '标题模板：角色:名(身份) / 设定:名(类型) / 地点:名(区域) / '
        '势力:名(阵营) / 事件:动作+结果 / 伏笔:摘要 / 道具:名(功能)。\n'
        '关系(大写下划线)：FOLLOWS/CORRECTS/UPDATES/INVOLVES/'
        'HAPPENS_AT/PART_OF/ALLIED_WITH/OPPOSES/'
        'MENTORS/SERVES/BETRAYS/LOVES。输出前两两检查。\n\n'
        'JSON格式：main:["标题","内容",["标签"],"folder"]或null。'
        'new:[["标题","内容",["标签"],"folder","alias"],...]。'
        'update:[["标题","新内容","原因",cred,imp],...]。'
        'merge:[{"source_titles":[],"new_title":"",'
        '"new_content":"","new_tags":[],"folder_path":"","reason":""},...]。'
        'links:[["源","目标","TYPE","描述",weight],...]。'
        '数值0.0~1.0或null。'
        '文件夹：角色记忆/设定记忆/地点记忆/势力记忆/事件记忆/道具记忆/对话摘要。'
        '只返回JSON。';
  }

  String _buildAnalysisMsg(
    String query,
    String solution,
    List<Map<String, String>> history,
  ) {
    final text = history
        .map((m) => '${m['role'] == 'user' ? '用户' : '助手'}: ${m['content']}')
        .join('\n\n');
    final sol = solution.length > 800
        ? '${solution.substring(0, 800)}...'
        : solution;
    return '对话：\n\n$text\n\n---\n'
        '问题：$query\n\n回复：$sol\n\n提取知识图谱。';
  }

  String _dupHint(List<Memory> cands) {
    if (cands.length < 2) return '';
    final groups = <String, List<String>>{};
    for (final m in cands) {
      groups.putIfAbsent(m.title.trim().toLowerCase(), () => []).add(m.title);
    }
    final dups = groups.entries.where((e) => e.value.length > 1).toList();
    if (dups.isEmpty) return '';
    return '【重复请合并】${dups.map((e) => e.value.join("/")).join("；")}\n';
  }

  // =============================================================
  // 解析
  // =============================================================
  _ParsedAnalysis _parseResult(String raw) {
    try {
      final s = raw.indexOf('{');
      final e = raw.lastIndexOf('}');
      if (s < 0 || e < 0 || e <= s) return const _ParsedAnalysis();
      final clean = raw.substring(s, e + 1);
      if (clean == '{}') return const _ParsedAnalysis();
      final j = jsonDecode(clean) as Map<String, dynamic>;
      final mainArr = j['main'] as List<dynamic>?;
      final main = (mainArr != null && mainArr.isNotEmpty)
          ? _ParsedEntity(
              title: '${mainArr[0]}',
              content: '${mainArr[1]}',
              tags: _tags(mainArr, 2),
              folderPath: mainArr.length > 3 ? '${mainArr[3]}' : '',
            )
          : null;
      final ents = (j['new'] as List? ?? []).map((i) {
        final a = i as List;
        return _ParsedEntity(
          title: '${a[0]}',
          content: '${a[1]}',
          tags: _tags(a, 2),
          folderPath: a.length > 3 ? '${a[3]}' : '',
          aliasFor: (a.length > 4 && a[4] != null) ? '${a[4]}' : null,
        );
      }).toList();
      final links = (j['links'] as List? ?? []).map((i) {
        final a = i as List;
        return _ParsedLink(
          sourceTitle: '${a[0]}',
          targetTitle: '${a[1]}',
          type: '${a[2]}',
          description: a.length > 3 ? '${a[3]}' : '',
          weight: (a.length > 4 && a[4] != null)
              ? (a[4] as num).toDouble()
              : 1.0,
        );
      }).toList();
      final ups = (j['update'] as List? ?? []).map((i) {
        final a = i as List;
        return _ParsedUpdate(
          titleToUpdate: '${a[0]}',
          newContent: '${a[1]}',
          reason: a.length > 2 ? '${a[2]}' : '',
          newCredibility: _od(a, 3),
          newImportance: _od(a, 4),
        );
      }).toList();
      final mrgs = (j['merge'] as List? ?? []).map((i) {
        final o = i as Map<String, dynamic>;
        return _ParsedMerge(
          sourceTitles: (o['source_titles'] as List).map((e) => '$e').toList(),
          newTitle: '${o['new_title']}',
          newContent: '${o['new_content']}',
          newTags:
              (o['new_tags'] as List?)?.map((e) => '$e').toList() ?? const [],
          folderPath: o['folder_path']?.toString() ?? '',
          reason: o['reason']?.toString() ?? '',
        );
      }).toList();
      return _ParsedAnalysis(
        mainProblem: main,
        entities: ents,
        links: links,
        updates: ups,
        merges: mrgs,
      );
    } on Exception catch (e) {
      developer.log('解析失败: $e');
      return const _ParsedAnalysis();
    }
  }

  List<String> _tags(List<dynamic> a, int i) => (a.length > i && a[i] is List)
      ? (a[i] as List).map((e) => '$e').toList()
      : const [];
  double? _od(List<dynamic> a, int i) =>
      (a.length > i && a[i] != null) ? (a[i] as num).toDouble() : null;

  // =============================================================
  // 应用结果
  // =============================================================
  Future<AnalysisResult> _apply(_ParsedAnalysis analysis) async {
    final cache = <String, Memory>{};
    int nC = 0, nU = 0, nL = 0;
    // 合并（使用 repository 的 mergeMemories 来保留关联关系）
    for (final m in analysis.merges) {
      if (m.sourceTitles.isEmpty) continue;
      final merged = await _repo.mergeMemories(
        sourceTitles: m.sourceTitles,
        newTitle: m.newTitle,
        newContent: m.newContent,
        newTags: m.newTags,
        folderPath: m.folderPath,
      );
      if (merged != null) {
        cache[m.newTitle] = merged;
        nC++;
      }
    }
    // 更新
    for (final u in analysis.updates) {
      final ex = await _find(u.titleToUpdate, cache);
      if (ex == null) continue;
      await _repo.updateMemory(
        memory: ex,
        newTitle: ex.title,
        newContent: u.newContent,
        newCredibility: u.newCredibility ?? ex.credibility,
        newImportance: u.newImportance ?? ex.importance,
      );
      final r = await _repo.findMemoryById(ex.id);
      if (r != null) {
        cache[r.title] = r;
        nU++;
      }
    }
    // 主节点
    if (analysis.mainProblem != null) {
      final mp = analysis.mainProblem!;
      final ex = await _repo.findMemoryByTitle(mp.title);
      if (ex != null) {
        await _repo.updateMemory(
          memory: ex,
          newTitle: ex.title,
          newContent: mp.content,
        );
        final r = await _repo.findMemoryById(ex.id);
        if (r != null) {
          cache[r.title] = r;
          nU++;
        }
      } else {
        final m = await _repo.createMemory(
          title: mp.title,
          content: mp.content,
          source: 'memory_analysis',
          folderPath: mp.folderPath,
          tags: mp.tags,
        );
        if (m != null) {
          cache[m.title] = m;
          nC++;
        }
      }
    }
    // 新实体
    for (final ent in analysis.entities) {
      Memory? res;
      if (ent.aliasFor != null && ent.aliasFor!.isNotEmpty) {
        res = await _find(ent.aliasFor!, cache);
      }
      res ??= await _find(ent.title, cache);
      if (res == null) {
        res = await _repo.createMemory(
          title: ent.title,
          content: ent.content,
          source: 'memory_analysis',
          folderPath: ent.folderPath.isNotEmpty
              ? ent.folderPath
              : (analysis.mainProblem?.folderPath ?? ''),
          tags: ent.tags,
        );
        if (res != null) nC++;
      }
      if (res != null) cache[ent.title] = res;
    }
    // 链接
    for (final lk in analysis.links) {
      final src = await _find(lk.sourceTitle, cache);
      final tgt = await _find(lk.targetTitle, cache);
      if (src != null && tgt != null) {
        await _repo.linkMemories(
          source: src,
          target: tgt,
          type: lk.type,
          weight: lk.weight,
          description: lk.description,
        );
        nL++;
      }
    }
    developer.log('图谱写入: 创建=$nC 更新=$nU 链接=$nL');
    return AnalysisResult(createdCount: nC, updatedCount: nU, linkedCount: nL);
  }

  Future<Memory?> _find(String title, Map<String, Memory> cache) async =>
      cache[title] ?? await _repo.findMemoryByTitle(title);

  // =============================================================
  // 批量归类
  // =============================================================
  Future<int> _categorizeBatch({
    required AiConfig config,
    required List<Memory> memories,
  }) async {
    if (memories.isEmpty) return 0;
    const folders = ['角色记忆', '设定记忆', '地点记忆', '势力记忆', '事件记忆', '道具记忆', '对话摘要'];
    final entries = memories
        .map((m) {
          final p = m.content.replaceAll('\n', ' ');
          return '[ID:${m.id}] ${m.title}: '
              '${p.length > 80 ? '${p.substring(0, 80)}...' : p}';
        })
        .join('\n');
    try {
      final result = await _aiService.send(
        config: config,
        systemPrompt:
            '将记忆分到：${folders.join("、")}。'
            '角色->角色记忆，设定->设定记忆，地点->地点记忆，'
            '势力->势力记忆，事件->事件记忆，道具->道具记忆。'
            '返回[[ID,"文件夹"],...]，只返回JSON。',
        userMessage: '分类：\n\n$entries',
        taskType: 'memory_categorize',
      );
      final s = result.indexOf('[');
      final e = result.lastIndexOf(']');
      if (s < 0 || e < 0) return 0;
      final arr = jsonDecode(result.substring(s, e + 1)) as List;
      int count = 0;
      for (final item in arr) {
        final pair = item as List;
        if (pair.length < 2) continue;
        final id = pair[0] is int ? pair[0] as int : int.tryParse('${pair[0]}');
        final folder = '${pair[1]}'.trim();
        if (id == null || folder.isEmpty) continue;
        if (!folders.any((f) => folder == f || folder.startsWith('$f/'))) {
          continue;
        }
        final mem = await _repo.findMemoryById(id);
        if (mem != null) {
          await _repo.updateMemory(
            memory: mem,
            newTitle: mem.title,
            newContent: mem.content,
            newFolderPath: folder,
          );
          count++;
        }
      }
      return count;
    } on Exception catch (e) {
      developer.log('批次归类失败: $e');
      return 0;
    }
  }
}
