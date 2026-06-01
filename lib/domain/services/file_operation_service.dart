import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:novel_ide/data/datasources/public_storage_helper.dart';
import 'package:novel_ide/data/datasources/database_helper.dart';

/// 文件操作服务
///
/// 封装章节文件夹、章节文件的增删改查操作。
/// 所有路径均通过 [PublicStorageHelper] 获取，不硬编码。
class FileOperationService {
  FileOperationService({DatabaseHelper? databaseHelper})
    : _db = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _db;
  final _uuid = const Uuid();

  /// 创建章节文件
  ///
  /// [novelId] 作品ID
  /// [volumeId] 卷ID（卷内新建时传入，根目录新建时传空）
  /// [title] 章节标题
  /// [orderIndex] 排序序号
  /// 返回新建的 Chapter 数据
  Future<_ChapterResult> createChapter({
    required String novelId,
    required String volumeId,
    required String title,
    int orderIndex = 0,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final db = await _db.database;

    // 获取作品路径
    final novelTitle = await _getNovelTitle(novelId);
    final projectDir = await _getProjectDir(novelId, novelTitle);
    final chaptersDir = Directory(p.join(projectDir, 'chapters'));
    if (!await chaptersDir.exists()) {
      await chaptersDir.create(recursive: true);
    }

    // 创建 .md 文件
    final filePath = p.join(chaptersDir.path, '$id.md');
    await File(filePath).writeAsString('', encoding: utf8);

    // 插入数据库
    await db.insert('chapters', {
      'id': id,
      'novel_id': novelId,
      'volume_id': volumeId,
      'title': title,
      'word_count': 0,
      'status': 'draft',
      'order_index': orderIndex,
      'created_at': now.millisecondsSinceEpoch,
      'updated_at': now.millisecondsSinceEpoch,
    });

    return _ChapterResult(
      id: id,
      title: title,
      volumeId: volumeId,
      filePath: filePath,
      createdAt: now,
    );
  }

  /// 创建文件夹（卷）
  ///
  /// [novelId] 作品ID
  /// [title] 卷标题
  /// [orderIndex] 排序序号
  /// 返回新建的卷ID
  Future<String> createFolder({
    required String novelId,
    required String title,
    int orderIndex = 0,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final db = await _db.database;

    await db.insert('volumes', {
      'id': id,
      'novel_id': novelId,
      'title': title,
      'order_index': orderIndex,
      'created_at': now.millisecondsSinceEpoch,
    });

    return id;
  }

  /// 删除节点
  ///
  /// [nodePath] 节点的文件路径
  /// [nodeId] 节点ID（数据库主键）
  /// [isFolder] 是否为文件夹（卷）
  Future<void> deleteNode({
    required String nodeId,
    required String nodePath,
    required bool isFolder,
  }) async {
    final db = await _db.database;

    if (isFolder) {
      // 删除卷：先删除该卷下所有章节的文件，再删数据库记录
      final chapters = await db.query(
        'chapters',
        where: 'volume_id = ?',
        whereArgs: [nodeId],
      );
      for (final ch in chapters) {
        final chId = ch['id'] as String;
        final novelId = ch['novel_id'] as String;
        final novelTitle = await _getNovelTitle(novelId);
        final projectDir = await _getProjectDir(novelId, novelTitle);
        final file = File(p.join(projectDir, 'chapters', '$chId.md'));
        if (await file.exists()) await file.delete();
      }
      await db.delete('chapters', where: 'volume_id = ?', whereArgs: [nodeId]);
      await db.delete('volumes', where: 'id = ?', whereArgs: [nodeId]);
    } else {
      // 删除章节文件
      final file = File(nodePath);
      if (await file.exists()) await file.delete();
      await db.delete('chapters', where: 'id = ?', whereArgs: [nodeId]);
    }
  }

  /// 移动节点
  ///
  /// [chapterId] 章节ID
  /// [targetVolumeId] 目标卷ID
  Future<void> moveNode({
    required String chapterId,
    required String targetVolumeId,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();

    // 获取目标卷的最大排序号
    final maxOrder = await db.rawQuery(
      'SELECT MAX(order_index) as max_order FROM chapters WHERE volume_id = ?',
      [targetVolumeId],
    );
    final nextOrder = ((maxOrder.first['max_order'] as int?) ?? 0) + 1;

    await db.update(
      'chapters',
      {
        'volume_id': targetVolumeId,
        'order_index': nextOrder,
        'updated_at': now.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [chapterId],
    );
  }

  /// 重命名节点
  ///
  /// [nodeId] 节点ID
  /// [newName] 新名称
  /// [isFolder] 是否为文件夹（卷）
  Future<void> renameNode({
    required String nodeId,
    required String newName,
    required bool isFolder,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();

    if (isFolder) {
      await db.update(
        'volumes',
        {'title': newName},
        where: 'id = ?',
        whereArgs: [nodeId],
      );
    } else {
      await db.update(
        'chapters',
        {'title': newName, 'updated_at': now.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [nodeId],
      );
    }
  }

  /// 获取作品标题（用于路径拼接）
  Future<String> _getNovelTitle(String novelId) async {
    final db = await _db.database;
    final maps = await db.query(
      'novels',
      columns: ['title'],
      where: 'id = ?',
      whereArgs: [novelId],
    );
    if (maps.isEmpty) return '';
    return maps.first['title'] as String;
  }

  /// 获取作品目录路径（通过 PublicStorageHelper）
  /// 路径遍历防护：清洗标题中的路径分隔符
  Future<String> _getProjectDir(String novelId, String title) async {
    final worksDir = await PublicStorageHelper.worksDir;
    // 清洗标题中的路径分隔符，防止路径遍历
    final safeTitle = title.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    final projectDir = p.join(worksDir.path, '${novelId}_$safeTitle');
    // 验证最终路径在 worksDir 内
    if (!p.isWithin(worksDir.path, projectDir)) {
      throw ArgumentError('Path traversal detected');
    }
    return projectDir;
  }
}

/// 创建章节结果
class _ChapterResult {
  const _ChapterResult({
    required this.id,
    required this.title,
    required this.volumeId,
    required this.filePath,
    required this.createdAt,
  });
  final String id;
  final String title;
  final String volumeId;
  final String filePath;
  final DateTime createdAt;
}
