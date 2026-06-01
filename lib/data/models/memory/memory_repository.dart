import 'dart:math';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';

import 'memory_entity.dart';
import 'embedding.dart';
import 'memory_search_config.dart';

/// 记忆仓库
///
/// 负责记忆数据的所有持久化操作，基于 SQLite (sqflite)。
/// 向量搜索相关保留接口定义，具体实现依赖外部 embedding 服务。
class MemoryRepository {
  // --- 关联强度常量 ---
  static const double strongLink = 1.0;
  static const double mediumLink = 0.7;
  static const double weakLink = 0.3;

  // --- 搜索常量 ---
  static const double _searchRrfK = 60.0;
  static const double _searchKeywordCoverageBonus = 0.6;
  static const double _searchRelevanceThreshold = 0.025;
  static const int _danglingLinkCleanupIntervalMs = 30000;

  // --- 依赖 ---
  final Database _db;
  final String _profileId;

  /// 嵌入向量生成接口（由外部注入实现）
  final Future<Embedding?> Function(String text)? generateEmbedding;

  int _lastDanglingCleanupAtMs = 0;

  MemoryRepository({
    required Database db,
    required String profileId,
    this.generateEmbedding,
  })  : _db = db,
        _profileId = profileId;

  // ============================================================
  // 数据库表初始化
  // ============================================================

  /// 创建记忆系统所需的全部表结构（含 novel_id 字段）
  static Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS memories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        novel_id TEXT,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        content_type TEXT NOT NULL DEFAULT 'text/plain',
        source TEXT NOT NULL DEFAULT 'unknown',
        credibility REAL NOT NULL DEFAULT 0.5,
        importance REAL NOT NULL DEFAULT 0.5,
        document_path TEXT,
        is_document_node INTEGER NOT NULL DEFAULT 0,
        chunk_index_file_path TEXT,
        folder_path TEXT,
        embedding BLOB,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_accessed_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        FOREIGN KEY (parent_id) REFERENCES memory_tags(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_tag_relations (
        memory_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (memory_id, tag_id),
        FOREIGN KEY (memory_id) REFERENCES memories(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES memory_tags(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_id INTEGER NOT NULL,
        target_id INTEGER NOT NULL,
        type TEXT NOT NULL DEFAULT 'related',
        weight REAL NOT NULL DEFAULT 1.0,
        description TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (source_id) REFERENCES memories(id) ON DELETE CASCADE,
        FOREIGN KEY (target_id) REFERENCES memories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memory_id INTEGER NOT NULL,
        key TEXT NOT NULL,
        value TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (memory_id) REFERENCES memories(id) ON DELETE CASCADE
      )
    ''');

    // 索引
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memories_novel_id ON memories(novel_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memories_folder_path ON memories(folder_path)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memories_uuid ON memories(uuid)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memory_links_source ON memory_links(source_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memory_links_target ON memory_links(target_id)');
  }

  // ============================================================
  // 工具方法
  // ============================================================

  static String? normalizeFolderPath(String? folderPath) {
    final raw = folderPath?.trim();
    if (raw == null || raw.isEmpty) return null;

    final parts = raw
        .replaceAll('\\', '/')
        .split('/')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return parts.isEmpty ? null : parts.join('/');
  }

  bool _isFolderPlaceholderMemory(Memory memory) {
    final title = memory.title.trim();
    return title == '.folder_placeholder' ||
        title == '文件夹说明';
  }

  // ============================================================
  // Memory CRUD 操作
  // ============================================================

  /// 创建或更新一条记忆，自动生成嵌入向量
  Future<int> saveMemory(Memory memory) async {
    final now = DateTime.now().toIso8601String();
    final normalizedFolder =
        normalizeFolderPath(memory.folderPath);
    final clampedCredibility =
        memory.credibility.clamp(0.0, 1.0);
    final clampedImportance =
        memory.importance.clamp(0.0, 1.0);

    // 生成嵌入向量
    Embedding? newEmbedding = memory.embedding;
    final textForEmbedding =
        memory.isDocumentNode ? memory.title : memory.content;
    if (textForEmbedding.trim().isNotEmpty &&
        generateEmbedding != null) {
      newEmbedding =
          await generateEmbedding!(textForEmbedding);
    }

    final data = <String, dynamic>{
      'uuid': memory.uuid,
      'novel_id':
          memory.novelId.isEmpty ? null : memory.novelId,
      'title': memory.title,
      'content': memory.content,
      'content_type': memory.contentType,
      'source': memory.source,
      'credibility': clampedCredibility,
      'importance': clampedImportance,
      'document_path': memory.documentPath,
      'is_document_node': memory.isDocumentNode ? 1 : 0,
      'chunk_index_file_path': memory.chunkIndexFilePath,
      'folder_path': normalizedFolder,
      'embedding': newEmbedding != null
          ? _encodeEmbedding(newEmbedding)
          : null,
      'updated_at': now,
      'last_accessed_at': now,
    };

    int id;
    if (memory.id > 0) {
      await _db.update('memories', data,
          where: 'id = ?', whereArgs: [memory.id]);
      id = memory.id;
    } else {
      data['created_at'] = now;
      id = await _db.insert('memories', data);
    }

    return id;
  }

  Future<Memory?> findMemoryById(int id) async {
    final rows = await _db.query('memories',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _memoryFromRow(rows.first);
  }

  Future<Memory?> findMemoryByUuid(String uuid) async {
    final rows = await _db.query('memories',
        where: 'uuid = ?', whereArgs: [uuid], limit: 1);
    if (rows.isEmpty) return null;
    return _memoryFromRow(rows.first);
  }

  Future<Memory?> findMemoryByTitle(String title) async {
    final rows = await _db.query('memories',
        where: 'title = ?', whereArgs: [title], limit: 1);
    if (rows.isEmpty) return null;
    return _memoryFromRow(rows.first);
  }

  Future<List<Memory>> findMemoriesByTitle(
      String title) async {
    final rows = await _db.query('memories',
        where: 'title = ?', whereArgs: [title]);
    return Future.wait(rows.map((r) => _memoryFromRow(r)));
  }

  Future<bool> deleteMemory(int memoryId) async {
    final memory = await findMemoryById(memoryId);
    if (memory == null) return false;

    await _db.transaction((txn) async {
      await txn.delete('memory_links',
          where: 'source_id = ? OR target_id = ?',
          whereArgs: [memoryId, memoryId]);
      await txn.delete('memory_tag_relations',
          where: 'memory_id = ?', whereArgs: [memoryId]);
      await txn.delete('memory_properties',
          where: 'memory_id = ?', whereArgs: [memoryId]);
      await txn.delete('memories',
          where: 'id = ?', whereArgs: [memoryId]);
    });

    return true;
  }

  Future<bool> deleteMemoriesByUuids(
      Set<String> uuids) async {
    if (uuids.isEmpty) return true;

    final placeholders =
        uuids.map((_) => '?').join(',');
    final memories = await _db.query('memories',
        where: 'uuid IN ($placeholders)',
        whereArgs: uuids.toList());

    if (memories.isEmpty) return true;

    final ids =
        memories.map((m) => m['id'] as int).toList();
    final idPlaceholders =
        ids.map((_) => '?').join(',');

    await _db.transaction((txn) async {
      await txn.delete('memory_links',
          where:
              'source_id IN ($idPlaceholders) OR target_id IN ($idPlaceholders)',
          whereArgs: [...ids, ...ids]);
      await txn.delete('memory_tag_relations',
          where: 'memory_id IN ($idPlaceholders)',
          whereArgs: ids);
      await txn.delete('memory_properties',
          where: 'memory_id IN ($idPlaceholders)',
          whereArgs: ids);
      await txn.delete('memories',
          where: 'id IN ($idPlaceholders)',
          whereArgs: ids);
    });

    return true;
  }

  /// 创建一条新记忆并自动生成嵌入向量
  Future<Memory?> createMemory({
    required String title,
    required String content,
    String contentType = 'text/plain',
    String source = 'user_input',
    String folderPath = '',
    List<String>? tags,
  }) async {
    final memory = Memory(
      uuid: _generateUuid(),
      novelId: _profileId,
      title: title,
      content: content,
      contentType: contentType,
      source: source,
      folderPath: normalizeFolderPath(folderPath),
    );

    final id = await saveMemory(memory);
    final saved = await findMemoryById(id);
    if (saved == null) return null;

    if (tags != null && tags.isNotEmpty) {
      for (final tagName
          in tags.where((t) => t.trim().isNotEmpty)) {
        await addTagToMemory(saved, tagName.trim());
      }
    }

    return findMemoryById(id);
  }

  /// 更新已有记忆的内容、元数据和标签
  Future<Memory?> updateMemory({
    required Memory memory,
    required String newTitle,
    required String newContent,
    String? newContentType,
    String? newSource,
    double? newCredibility,
    double? newImportance,
    String? newFolderPath,
    List<String>? newTags,
  }) async {
    final updatedMemory = memory.copyWith(
      title: newTitle,
      content: newContent,
      contentType:
          newContentType ?? memory.contentType,
      source: newSource ?? memory.source,
      credibility:
          (newCredibility ?? memory.credibility)
              .clamp(0.0, 1.0),
      importance:
          (newImportance ?? memory.importance)
              .clamp(0.0, 1.0),
      folderPath: normalizeFolderPath(
          newFolderPath ?? memory.folderPath),
      updatedAt: DateTime.now(),
    );

    final id = await saveMemory(updatedMemory);

    if (newTags != null) {
      await _db.delete('memory_tag_relations',
          where: 'memory_id = ?',
          whereArgs: [memory.id]);
      for (final tagName
          in newTags.where((t) => t.trim().isNotEmpty)) {
        await addTagToMemory(
            updatedMemory, tagName.trim());
      }
    }

    return findMemoryById(id);
  }

  // ============================================================
  // Link CRUD 操作
  // ============================================================

  Future<MemoryLink?> findLinkById(int linkId) async {
    final rows = await _db.query('memory_links',
        where: 'id = ?', whereArgs: [linkId], limit: 1);
    if (rows.isEmpty) return null;
    return _linkFromRow(rows.first);
  }

  Future<MemoryLink?> updateLink({
    required int linkId,
    required String type,
    required double weight,
    required String description,
  }) async {
    final link = await findLinkById(linkId);
    if (link == null) return null;

    await _db.update(
      'memory_links',
      {
        'type': type,
        'weight': weight.clamp(0.0, 1.0),
        'description': description,
      },
      where: 'id = ?',
      whereArgs: [linkId],
    );

    return findLinkById(linkId);
  }

  Future<bool> deleteLink(int linkId) async {
    final count = await _db.delete('memory_links',
        where: 'id = ?', whereArgs: [linkId]);
    return count > 0;
  }

  /// 创建记忆之间的关联
  Future<void> linkMemories({
    required Memory source,
    required Memory target,
    required String type,
    double weight = mediumLink,
    String description = '',
  }) async {
    final existing = await _db.query(
      'memory_links',
      where:
          'source_id = ? AND target_id = ? AND type = ?',
      whereArgs: [source.id, target.id, type],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    await _db.insert('memory_links', {
      'source_id': source.id,
      'target_id': target.id,
      'type': type,
      'weight': weight.clamp(0.0, 1.0),
      'description': description,
    });
  }

  Future<List<MemoryLink>> getOutgoingLinks(
      int memoryId) async {
    final rows = await _db.query('memory_links',
        where: 'source_id = ?',
        whereArgs: [memoryId]);
    return rows.map(_linkFromRow).toList();
  }

  Future<List<MemoryLink>> getIncomingLinks(
      int memoryId) async {
    final rows = await _db.query('memory_links',
        where: 'target_id = ?',
        whereArgs: [memoryId]);
    return rows.map(_linkFromRow).toList();
  }

  Future<List<MemoryLink>> queryMemoryLinks({
    int? linkId,
    int? sourceMemoryId,
    int? targetMemoryId,
    String? linkType,
    int limit = 20,
  }) async {
    final validLimit = limit.clamp(1, 200);
    final normalizedType = linkType?.trim();

    await _cleanupDanglingLinksIfNeeded();

    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (linkId != null) {
      whereClauses.add('id = ?');
      whereArgs.add(linkId);
    }
    if (sourceMemoryId != null) {
      whereClauses.add('source_id = ?');
      whereArgs.add(sourceMemoryId);
    }
    if (targetMemoryId != null) {
      whereClauses.add('target_id = ?');
      whereArgs.add(targetMemoryId);
    }
    if (normalizedType != null &&
        normalizedType.isNotEmpty) {
      whereClauses.add('type = ?');
      whereArgs.add(normalizedType);
    }

    final whereStr = whereClauses.isEmpty
        ? null
        : whereClauses.join(' AND ');
    final rows = await _db.query(
      'memory_links',
      where: whereStr,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'id DESC',
      limit: validLimit,
    );

    return rows.map(_linkFromRow).toList();
  }

  // ============================================================
  // 标签操作
  // ============================================================

  Future<MemoryTag> addTagToMemory(
      Memory memory, String tagName) async {
    var rows = await _db.query('memory_tags',
        where: 'name = ?',
        whereArgs: [tagName],
        limit: 1);

    int tagId;
    if (rows.isNotEmpty) {
      tagId = rows.first['id'] as int;
    } else {
      tagId = await _db
          .insert('memory_tags', {'name': tagName});
    }

    await _db.insert(
      'memory_tag_relations',
      {'memory_id': memory.id, 'tag_id': tagId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return MemoryTag(id: tagId, name: tagName);
  }

  Future<List<MemoryTag>> getTagsForMemory(
      int memoryId) async {
    final rows = await _db.rawQuery('''
      SELECT t.id, t.name, t.parent_id
      FROM memory_tags t
      INNER JOIN memory_tag_relations r ON t.id = r.tag_id
      WHERE r.memory_id = ?
    ''', [memoryId]);

    return rows
        .map((r) => MemoryTag(
              id: r['id'] as int,
              name: r['name'] as String,
              parentId: r['parent_id'] as int?,
            ))
        .toList();
  }

  Future<List<int>> getMemoryIdsForTag(
      int tagId) async {
    final rows = await _db.query('memory_tag_relations',
        columns: ['memory_id'],
        where: 'tag_id = ?',
        whereArgs: [tagId]);
    return rows
        .map((r) => r['memory_id'] as int)
        .toList();
  }

  // ============================================================
  // 文件夹操作
  // ============================================================

  Future<List<String>> getAllFolderPaths() async {
    final rows = await _db.rawQuery(
        "SELECT DISTINCT folder_path FROM memories ORDER BY folder_path ASC");

    return rows.map((r) {
      final path = r['folder_path'] as String?;
      return normalizeFolderPath(path) ?? '未分类';
    }).toList();
  }

  Future<List<Memory>> getMemoriesByFolderPath(
      String folderPath) async {
    final normalizedTarget =
        normalizeFolderPath(folderPath);

    List<Map<String, dynamic>> rows;
    if (folderPath == '未分类' ||
        normalizedTarget == null) {
      rows = await _db.query('memories',
          where: 'folder_path IS NULL');
    } else {
      rows = await _db.query(
        'memories',
        where: 'folder_path = ? OR folder_path LIKE ?',
        whereArgs: [
          normalizedTarget,
          '$normalizedTarget/%'
        ],
      );
    }

    return Future.wait(
        rows.map((r) => _memoryFromRow(r)));
  }

  Future<bool> createFolder(String folderPath) async {
    final normalizedPath =
        normalizeFolderPath(folderPath);
    if (normalizedPath == null) return false;

    final existing = await _db.query(
      'memories',
      where: 'folder_path = ?',
      whereArgs: [normalizedPath],
      limit: 1,
    );
    if (existing.isNotEmpty) return true;

    final placeholder = Memory(
      uuid: _generateUuid(),
      novelId: _profileId,
      title: '.folder_placeholder',
      content: '文件夹: $normalizedPath',
      folderPath: normalizedPath,
    );
    await saveMemory(placeholder);
    return true;
  }

  Future<bool> renameFolder(
      String oldPath, String newPath) async {
    final normalizedOld = normalizeFolderPath(oldPath);
    final normalizedNew = normalizeFolderPath(newPath);
    if (normalizedOld == null ||
        normalizedNew == null) return false;
    if (normalizedOld == normalizedNew) return true;

    final memories = await _db.query(
      'memories',
      where: 'folder_path = ? OR folder_path LIKE ?',
      whereArgs: [
        normalizedOld,
        '$normalizedOld/%'
      ],
    );

    final batch = _db.batch();
    for (final row in memories) {
      final currentPath =
          row['folder_path'] as String?;
      if (currentPath == null) continue;

      final String updatedPath;
      if (currentPath == normalizedOld) {
        updatedPath = normalizedNew;
      } else {
        updatedPath = normalizedNew +
            currentPath
                .substring(normalizedOld.length);
      }

      batch.update(
          'memories', {'folder_path': updatedPath},
          where: 'id = ?',
          whereArgs: [row['id']]);
    }
    await batch.commit(noResult: true);

    return true;
  }

  Future<bool> moveMemoriesToFolder(
      List<int> memoryIds,
      String targetFolderPath) async {
    final normalizedTarget =
        targetFolderPath == '未分类'
            ? null
            : normalizeFolderPath(targetFolderPath);

    final batch = _db.batch();
    for (final id in memoryIds) {
      batch.update(
          'memories', {'folder_path': normalizedTarget},
          where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);

    return true;
  }

  Future<void> deleteFolder(
      String folderPath) async {
    final normalizedTarget =
        normalizeFolderPath(folderPath);

    List<Map<String, dynamic>> memories;
    if (normalizedTarget == null ||
        folderPath == '未分类') {
      memories = await _db.query('memories',
          where: 'folder_path IS NULL');
    } else {
      memories = await _db.query('memories',
          where: 'folder_path = ?',
          whereArgs: [normalizedTarget]);
    }

    final batch = _db.batch();
    for (final row in memories) {
      batch.update(
          'memories', {'folder_path': null},
          where: 'id = ?',
          whereArgs: [row['id']]);
    }
    await batch.commit(noResult: true);
  }

  // ============================================================
  // 搜索操作
  // ============================================================

  /// 搜索记忆（按 novelId 过滤）
  Future<List<Memory>> searchMemories({
    required String query,
    String? novelId,
    String? folderPath,
    MemoryScoreMode scoreMode =
        MemoryScoreMode.balanced,
    double keywordWeight = 10.0,
    double tagWeight = 0.0,
    double semanticWeight = 0.5,
    double edgeWeight = 0.4,
    double relevanceThreshold =
        _searchRelevanceThreshold,
    int? createdAtStartMs,
    int? createdAtEndMs,
  }) async {
    final normalizedFolder =
        normalizeFolderPath(folderPath);

    // 获取作用域内的记忆（按 novelId 过滤）
    List<Memory> memoriesInScope;
    if (normalizedFolder == null) {
      if (folderPath == '未分类') {
        final allRows = await _queryScopedMemories(
            novelId);
        memoriesInScope = allRows
            .where((m) =>
                normalizeFolderPath(m.folderPath) ==
                null)
            .toList();
      } else {
        memoriesInScope =
            await _queryScopedMemories(novelId);
      }
    } else {
      memoriesInScope =
          await getMemoriesByFolderPath(
              normalizedFolder);
      // 进一步按 novelId 过滤
      if (novelId != null) {
        memoriesInScope = memoriesInScope
            .where((m) =>
                m.novelId == novelId ||
                m.novelId.isEmpty)
            .toList();
      }
    }

    // 排除文件夹占位记忆
    final searchableMemories = memoriesInScope
        .where((m) => !_isFolderPlaceholderMemory(m))
        .toList();

    // 时间过滤
    final timeFiltered =
        (createdAtStartMs == null &&
                createdAtEndMs == null)
            ? searchableMemories
            : searchableMemories.where((m) {
                final createdAtMs = m
                    .createdAt.millisecondsSinceEpoch;
                if (createdAtStartMs != null &&
                    createdAtMs < createdAtStartMs) {
                  return false;
                }
                if (createdAtEndMs != null &&
                    createdAtMs > createdAtEndMs) {
                  return false;
                }
                return true;
              }).toList();

    // 通配符查询
    if (query.trim() == '*' ||
        query.trim().isEmpty) {
      return timeFiltered;
    }

    // 拆分关键词
    final keywords = _splitSearchKeywords(query);
    if (keywords.isEmpty) return [];

    // 计算权重
    final config = MemorySearchConfig(
      scoreMode: scoreMode,
      keywordWeight: keywordWeight,
      tagWeight: tagWeight,
      vectorWeight: semanticWeight,
      edgeWeight: edgeWeight,
    ).normalized();

    // --- 关键词匹配评分（RRF） ---
    final scores = <int, double>{};

    final keywordTokens =
        _buildLexicalQueryTokens(query, keywords);
    if (keywordTokens.isNotEmpty &&
        config.keywordWeight > 0) {
      final titleMatches = <int, int>{};
      for (final memory in timeFiltered) {
        final matchedCount = keywordTokens
            .where((token) =>
                _textMatchesLexicalToken(
                    memory.title, token))
            .length;
        if (matchedCount > 0) {
          titleMatches[memory.id] = matchedCount;
        }
      }

      final contentMatches = <int, int>{};
      for (final memory in timeFiltered) {
        final matchedCount = keywordTokens
            .where((token) =>
                _textMatchesLexicalToken(
                    memory.content, token))
            .length;
        if (matchedCount > 0) {
          contentMatches[memory.id] = matchedCount;
        }
      }

      final allMatchedIds = {
        ...titleMatches.keys,
        ...contentMatches.keys
      };
      final rankedIds = allMatchedIds.toList()
        ..sort((a, b) {
          final aTitle = titleMatches[a] ?? 0;
          final bTitle = titleMatches[b] ?? 0;
          if (aTitle != bTitle) {
            return bTitle.compareTo(aTitle);
          }
          final aContent =
              contentMatches[a] ?? 0;
          final bContent =
              contentMatches[b] ?? 0;
          return bContent.compareTo(aContent);
        });

      for (int i = 0; i < rankedIds.length; i++) {
        final id = rankedIds[i];
        final rank = i + 1;
        final baseScore =
            1.0 / (_searchRrfK + rank);
        final matchedTokenCount =
            (titleMatches[id] ?? 0) +
                (contentMatches[id] ?? 0);
        final coverageRatio =
            keywordTokens.isEmpty
                ? 0.0
                : matchedTokenCount /
                    keywordTokens.length;
        final coverageMultiplier = 1.0 +
            (_searchKeywordCoverageBonus *
                coverageRatio);
        final weightedScore = baseScore *
            config.keywordWeight *
            config.keywordMultiplier *
            coverageMultiplier;
        scores[id] =
            (scores[id] ?? 0.0) + weightedScore;
      }
    }

    // --- 标签匹配评分 ---
    if (config.tagWeight > 0) {
      for (final memory in timeFiltered) {
        final tags =
            await getTagsForMemory(memory.id);
        final matchedTagCount =
            keywords.where((keyword) {
          return tags.any((tag) =>
              _textMatchesLexicalToken(
                  tag.name, keyword));
        }).length;
        if (matchedTagCount > 0) {
          final tagScore = matchedTagCount *
              config.tagWeight *
              config.keywordMultiplier;
          scores[memory.id] =
              (scores[memory.id] ?? 0.0) +
                  tagScore;
        }
      }
    }

    // --- 语义搜索（需要 embedding 服务） ---
    if (config.vectorWeight > 0 &&
        generateEmbedding != null) {
      for (final keyword in keywords) {
        final queryEmbedding =
            await generateEmbedding!(keyword);
        if (queryEmbedding == null) continue;

        for (final memory in timeFiltered) {
          if (memory.embedding == null) continue;
          final similarity =
              Embedding.cosineSimilarity(
                  queryEmbedding,
                  memory.embedding!);
          if (similarity > 0) {
            final semanticScore = similarity *
                config.vectorWeight *
                config.semanticMultiplier;
            scores[memory.id] =
                (scores[memory.id] ?? 0.0) +
                    semanticScore;
          }
        }
      }
    }

    // --- 按得分排序并过滤阈值 ---
    final threshold =
        relevanceThreshold.clamp(0.0, double.infinity);
    final memoryById = <int, Memory>{};
    for (final m in timeFiltered) {
      memoryById[m.id] = m;
    }

    final sortedEntries = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .where((e) => e.value >= threshold)
        .map((e) => memoryById[e.key])
        .whereType<Memory>()
        .toList();
  }

  // ============================================================
  // 图谱相关
  // ============================================================

  Future<List<MemoryLink>> getMemoryGraph() async {
    await _cleanupDanglingLinksIfNeeded();
    final rows = await _db.query('memory_links');
    return rows.map(_linkFromRow).toList();
  }

  Future<List<MemoryLink>> getGraphForMemories(
      List<Memory> memories) async {
    final ids = memories.map((m) => m.id).toSet();
    if (ids.isEmpty) return [];

    final expandedIds = Set<int>.from(ids);
    for (final memory in memories) {
      final outgoing =
          await getOutgoingLinks(memory.id);
      final incoming =
          await getIncomingLinks(memory.id);
      for (final link in outgoing) {
        expandedIds.add(link.targetId);
      }
      for (final link in incoming) {
        expandedIds.add(link.sourceId);
      }
    }

    final idPlaceholders =
        expandedIds.map((_) => '?').join(',');
    final rows = await _db.query(
      'memory_links',
      where:
          'source_id IN ($idPlaceholders) AND target_id IN ($idPlaceholders)',
      whereArgs: [
        ...expandedIds,
        ...expandedIds
      ],
    );

    return rows.map(_linkFromRow).toList();
  }

  Future<List<MemoryLink>> getGraphForFolder(
      String folderPath) async {
    final memories =
        await getMemoriesByFolderPath(folderPath);
    return getGraphForMemories(memories);
  }

  // ============================================================
  // 内部辅助方法
  // ============================================================

  /// 按 novelId 查询作用域内的记忆
  Future<List<Memory>> _queryScopedMemories(
      String? novelId) async {
    List<Map<String, dynamic>> rows;
    if (novelId != null) {
      rows = await _db.query(
        'memories',
        where: 'novel_id = ? OR novel_id IS NULL',
        whereArgs: [novelId],
      );
    } else {
      rows = await _db.query('memories');
    }
    return Future.wait(
        rows.map((r) => _memoryFromRow(r)));
  }

  Future<Memory> _memoryFromRow(
      Map<String, dynamic> row) async {
    final id = row['id'] as int;
    final tags = await getTagsForMemory(id);
    final outgoingLinks = await getOutgoingLinks(id);
    final incomingLinks = await getIncomingLinks(id);
    final properties =
        await _getPropertiesForMemory(id);

    return Memory(
      id: id,
      uuid: row['uuid'] as String,
      novelId: row['novel_id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      content: row['content'] as String? ?? '',
      contentType:
          row['content_type'] as String? ?? 'text/plain',
      source: row['source'] as String? ?? 'unknown',
      credibility:
          (row['credibility'] as num?)?.toDouble() ??
              0.5,
      importance:
          (row['importance'] as num?)?.toDouble() ??
              0.5,
      documentPath:
          row['document_path'] as String?,
      isDocumentNode:
          (row['is_document_node'] as int?) == 1,
      chunkIndexFilePath:
          row['chunk_index_file_path'] as String?,
      folderPath: row['folder_path'] as String?,
      embedding: row['embedding'] != null
          ? _decodeEmbedding(
              row['embedding'] as List<int>)
          : null,
      tags: tags,
      properties: properties,
      links: outgoingLinks,
      backlinks: incomingLinks,
      createdAt: DateTime.tryParse(
              row['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
              row['updated_at'] as String? ?? '') ??
          DateTime.now(),
      lastAccessedAt: DateTime.tryParse(
              row['last_accessed_at'] as String? ??
                  '') ??
          DateTime.now(),
    );
  }

  MemoryLink _linkFromRow(Map<String, dynamic> row) {
    return MemoryLink(
      id: row['id'] as int,
      sourceId: row['source_id'] as int,
      targetId: row['target_id'] as int,
      type: row['type'] as String? ?? 'related',
      weight:
          (row['weight'] as num?)?.toDouble() ?? 1.0,
      description:
          row['description'] as String? ?? '',
    );
  }

  Future<List<MemoryProperty>>
      _getPropertiesForMemory(int memoryId) async {
    final rows = await _db.query('memory_properties',
        where: 'memory_id = ?',
        whereArgs: [memoryId]);
    return rows
        .map((r) => MemoryProperty(
              id: r['id'] as int,
              key: r['key'] as String? ?? '',
              value: r['value'] as String? ?? '',
            ))
        .toList();
  }

  Future<void> _cleanupDanglingLinksIfNeeded(
      {bool force = false}) async {
    final now =
        DateTime.now().millisecondsSinceEpoch;
    if (!force &&
        now - _lastDanglingCleanupAtMs <
            _danglingLinkCleanupIntervalMs) {
      return;
    }

    final danglingLinks = await _db.rawQuery('''
      SELECT l.id FROM memory_links l
      LEFT JOIN memories ms ON l.source_id = ms.id
      LEFT JOIN memories mt ON l.target_id = mt.id
      WHERE ms.id IS NULL OR mt.id IS NULL
    ''');

    if (danglingLinks.isNotEmpty) {
      final ids = danglingLinks
          .map((r) => r['id'] as int)
          .toList();
      final placeholders =
          ids.map((_) => '?').join(',');
      await _db.delete('memory_links',
          where: 'id IN ($placeholders)',
          whereArgs: ids);
    }

    _lastDanglingCleanupAtMs = now;
  }

  static List<String> _splitSearchKeywords(
      String query) {
    final separator =
        query.contains('|') ? '|' : null;
    final parts = separator != null
        ? query.split('|')
        : query.split(RegExp(r'\s+'));
    return parts
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static List<String> _buildLexicalQueryTokens(
      String query, List<String> keywords) {
    final merged = <String>{};
    if (keywords.isNotEmpty) {
      for (final kw in keywords) {
        merged.addAll(_expandKeywordToken(kw));
      }
    } else {
      merged.addAll(_expandKeywordToken(query));
    }

    return merged
        .where((t) => _shouldKeepLexicalToken(t))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
  }

  static Set<String> _expandKeywordToken(
      String token) {
    final normalized = token.trim().toLowerCase();
    if (normalized.isEmpty) return {};

    final expanded = <String>{};
    if (_shouldKeepLexicalToken(normalized)) {
      expanded.add(normalized);
    }
    return expanded;
  }

  static bool _shouldKeepLexicalToken(
      String token) {
    final normalized = token.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    if (normalized.length < 2 ||
        normalized.length > 24) return false;
    return normalized.runes.any((r) =>
        (r >= 0x30 && r <= 0x39) ||
        (r >= 0x41 && r <= 0x5A) ||
        (r >= 0x61 && r <= 0x7A) ||
        (r >= 0x4E00 && r <= 0x9FFF));
  }

  static bool _textMatchesLexicalToken(
      String text, String token) {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) return false;

    if (normalizedToken.contains('*') &&
        normalizedToken != '*') {
      final parts = normalizedToken
          .split('*')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isEmpty) return false;
      final pattern =
          parts.map(RegExp.escape).join('.*');
      return RegExp(pattern, caseSensitive: false)
          .hasMatch(text);
    }

    return text
        .toLowerCase()
        .contains(normalizedToken.toLowerCase());
  }

  List<int> _encodeEmbedding(Embedding embedding) {
    final bytes = <int>[];
    for (final value in embedding.vector) {
      final byteData = ByteData(8);
      byteData.setFloat64(0, value, Endian.little);
      bytes.addAll(byteData.buffer.asUint8List());
    }
    return bytes;
  }

  Embedding _decodeEmbedding(List<int> bytes) {
    if (bytes.length % 8 != 0) {
      throw FormatException(
          'Embedding bytes length must be multiple of 8');
    }
    final values = <double>[];
    for (int i = 0; i < bytes.length; i += 8) {
      final byteData = ByteData.sublistView(
          Uint8List.fromList(
              bytes.sublist(i, i + 8)));
      values
          .add(byteData.getFloat64(0, Endian.little));
    }
    return Embedding(Float64List.fromList(values));
  }

  static String _generateUuid() {
    final random = Random();
    return '${_hex(random, 8)}-${_hex(random, 4)}-4${_hex(random, 3)}-${_hexVariant(random)}-${_hex(random, 12)}';
  }

  static String _hex(Random random, int length) {
    return List.generate(
        length,
        (_) => random
            .nextInt(16)
            .toRadixString(16)).join();
  }

  static String _hexVariant(Random random) {
    final variant =
        (random.nextInt(4) + 8).toRadixString(16);
    return '$variant${_hex(random, 3)}';
  }
}
