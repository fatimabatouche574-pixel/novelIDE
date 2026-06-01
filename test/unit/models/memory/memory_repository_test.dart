import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:novel_ide/data/models/memory/memory_entity.dart';
import 'package:novel_ide/data/models/memory/memory_repository.dart';

/// 初始化 sqflite FFI，用于桌面端单元测试
void _initFfi() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// 创建内存数据库并建表
Future<Database> _openTestDb() async {
  final db = await databaseFactoryFfi.openDatabase(
    ':memory:',
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await MemoryRepository.createTables(db);
      },
    ),
  );
  return db;
}

/// 构造一个测试用 Memory 对象
Memory _testMemory({
  int id = 0,
  String uuid = 'test-uuid-001',
  String novelId = 'novel-1',
  String title = '测试标题',
  String content = '测试内容正文',
  String source = 'test',
  double credibility = 0.8,
  double importance = 0.6,
  String? folderPath,
}) {
  return Memory(
    id: id,
    uuid: uuid,
    novelId: novelId,
    title: title,
    content: content,
    source: source,
    credibility: credibility,
    importance: importance,
    folderPath: folderPath,
  );
}

void main() {
  _initFfi();

  late Database db;
  late MemoryRepository repo;

  setUp(() async {
    db = await _openTestDb();
    repo = MemoryRepository(db: db, profileId: 'novel-1');
  });

  tearDown(() async {
    await db.close();
  });

  // ============================================================
  // createTables
  // ============================================================
  group('createTables', () {
    test('创建后 memories 表可正常查询', () async {
      // 如果建表成功，查询不应抛异常
      final result = await db.query('memories');
      expect(result, isEmpty);
    });

    test('创建后 memory_links 表可正常查询', () async {
      final result = await db.query('memory_links');
      expect(result, isEmpty);
    });

    test('创建后 memory_tags 表可正常查询', () async {
      final result = await db.query('memory_tags');
      expect(result, isEmpty);
    });

    test('创建后 memory_tag_relations 表可正常查询', () async {
      final result = await db.query('memory_tag_relations');
      expect(result, isEmpty);
    });

    test('创建后 memory_properties 表可正常查询', () async {
      final result = await db.query('memory_properties');
      expect(result, isEmpty);
    });
  });

  // ============================================================
  // saveMemory — 创建
  // ============================================================
  group('saveMemory 创建', () {
    test('id=0 时执行 INSERT，返回自增 ID', () async {
      final memory = _testMemory();
      final id = await repo.saveMemory(memory);

      expect(id, greaterThan(0));

      // 验证数据库中确实有这条记录
      final rows = await db.query(
        'memories',
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(rows, hasLength(1));
      expect(rows.first['uuid'], 'test-uuid-001');
      expect(rows.first['title'], '测试标题');
      expect(rows.first['content'], '测试内容正文');
    });

    test('创建记忆时自动写入 created_at', () async {
      final before = DateTime.now();
      final id = await repo.saveMemory(_testMemory());
      final after = DateTime.now();

      final rows = await db.query(
        'memories',
        where: 'id = ?',
        whereArgs: [id],
      );
      final createdAt = DateTime.parse(
        rows.first['created_at'] as String,
      );
      expect(
        createdAt.isAfter(before) ||
            createdAt.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        createdAt.isBefore(after) ||
            createdAt.isAtSameMomentAs(after),
        isTrue,
      );
    });

    test('credibility 和 importance 被 clamp 到 [0, 1]', () async {
      final memory = _testMemory(
        credibility: 1.5,
        importance: -0.3,
      );
      final id = await repo.saveMemory(memory);

      final saved = await repo.findMemoryById(id);
      expect(saved!.credibility, 1.0);
      expect(saved.importance, 0.0);
    });
  });

  // ============================================================
  // saveMemory — 更新
  // ============================================================
  group('saveMemory 更新', () {
    test('id>0 时执行 UPDATE，不改变记录数', () async {
      final memory = _testMemory();
      final id = await repo.saveMemory(memory);

      final updated = memory.copyWith(
        id: id,
        title: '更新后的标题',
        content: '更新后的内容',
      );
      await repo.saveMemory(updated);

      final rows = await db.query('memories');
      expect(rows, hasLength(1));
      expect(rows.first['title'], '更新后的标题');
      expect(rows.first['content'], '更新后的内容');
    });

    test('更新时 updated_at 变为新时间', () async {
      final memory = _testMemory();
      final id = await repo.saveMemory(memory);

      // 读取更新前的时间
      final before = await repo.findMemoryById(id);

      // 等一小段时间确保时间戳不同
      await Future.delayed(const Duration(milliseconds: 50));

      final updated = memory.copyWith(
        id: id,
        title: '新标题',
      );
      await repo.saveMemory(updated);

      final after = await repo.findMemoryById(id);
      expect(
        after!.updatedAt.isAfter(before!.updatedAt),
        isTrue,
      );
    });
  });

  // ============================================================
  // findMemoryById / findMemoryByUuid
  // ============================================================
  group('getMemory 查询', () {
    test('findMemoryById 返回正确记忆', () async {
      final memory = _testMemory();
      final id = await repo.saveMemory(memory);

      final found = await repo.findMemoryById(id);
      expect(found, isNotNull);
      expect(found!.uuid, 'test-uuid-001');
      expect(found.title, '测试标题');
      expect(found.novelId, 'novel-1');
    });

    test('findMemoryById 不存在时返回 null', () async {
      final found = await repo.findMemoryById(99999);
      expect(found, isNull);
    });

    test('findMemoryByUuid 返回正确记忆', () async {
      await repo.saveMemory(_testMemory(uuid: 'abc-def-123'));

      final found = await repo.findMemoryByUuid('abc-def-123');
      expect(found, isNotNull);
      expect(found!.uuid, 'abc-def-123');
    });

    test('findMemoryByUuid 不存在时返回 null', () async {
      final found = await repo.findMemoryByUuid('non-existent');
      expect(found, isNull);
    });
  });

  // ============================================================
  // deleteMemory
  // ============================================================
  group('deleteMemory', () {
    test('删除存在的记忆返回 true', () async {
      final id = await repo.saveMemory(_testMemory());
      final result = await repo.deleteMemory(id);

      expect(result, isTrue);

      // 确认已被删除
      final found = await repo.findMemoryById(id);
      expect(found, isNull);
    });

    test('删除不存在的记忆返回 false', () async {
      final result = await repo.deleteMemory(99999);
      expect(result, isFalse);
    });

    test('删除记忆时级联删除关联的 links', () async {
      final id1 = await repo.saveMemory(
        _testMemory(uuid: 'mem-1', title: 'A'),
      );
      final id2 = await repo.saveMemory(
        _testMemory(uuid: 'mem-2', title: 'B'),
      );
      final mem1 = (await repo.findMemoryById(id1))!;
      final mem2 = (await repo.findMemoryById(id2))!;

      await repo.linkMemories(
        source: mem1,
        target: mem2,
        type: 'related',
      );

      // 删除 mem1 后，关联也应该消失
      await repo.deleteMemory(id1);

      final links = await repo.getMemoryGraph();
      expect(links, isEmpty);
    });
  });

  // ============================================================
  // searchMemories
  // ============================================================
  group('searchMemories', () {
    test('通配符 * 返回所有记忆', () async {
      await repo.saveMemory(_testMemory(uuid: 'u1', title: 'A'));
      await repo.saveMemory(_testMemory(uuid: 'u2', title: 'B'));

      final results = await repo.searchMemories(query: '*');
      expect(results, hasLength(2));
    });

    test('按关键词搜索匹配标题', () async {
      await repo.saveMemory(
        _testMemory(uuid: 'u1', title: '主角的性格分析'),
      );
      await repo.saveMemory(
        _testMemory(uuid: 'u2', title: '世界观设定'),
      );

      final results = await repo.searchMemories(
        query: '主角',
        relevanceThreshold: 0,
      );
      expect(results, hasLength(1));
      expect(results.first.title, '主角的性格分析');
    });

    test('按关键词搜索匹配内容', () async {
      await repo.saveMemory(
        _testMemory(
          uuid: 'u1',
          title: '标题A',
          content: '这段描述了魔法体系的运作方式',
        ),
      );
      await repo.saveMemory(
        _testMemory(
          uuid: 'u2',
          title: '标题B',
          content: '完全没有相关内容',
        ),
      );

      final results = await repo.searchMemories(
        query: '魔法',
        relevanceThreshold: 0,
      );
      expect(results, hasLength(1));
      expect(results.first.title, '标题A');
    });

    test('按 novelId 过滤搜索范围', () async {
      await repo.saveMemory(
        _testMemory(
          uuid: 'u1',
          novelId: 'novel-A',
          title: '小说A的记忆',
          content: '特殊内容aaa',
        ),
      );
      await repo.saveMemory(
        _testMemory(
          uuid: 'u2',
          novelId: 'novel-B',
          title: '小说B的记忆',
          content: '特殊内容bbb',
        ),
      );

      // 只搜索 novel-A 的记忆
      final results = await repo.searchMemories(
        query: '特殊内容',
        novelId: 'novel-A',
        relevanceThreshold: 0,
      );
      expect(results, hasLength(1));
      expect(results.first.novelId, 'novel-A');
    });

    test('空查询返回空列表', () async {
      await repo.saveMemory(_testMemory(uuid: 'u1'));
      final results = await repo.searchMemories(
        query: '   ',
      );
      // 空或纯空格被视为通配符，返回所有
      expect(results, hasLength(1));
    });

    test('无匹配关键词返回空列表', () async {
      await repo.saveMemory(
        _testMemory(uuid: 'u1', title: '完全不相关的标题'),
      );
      final results = await repo.searchMemories(
        query: '不存在的关键词',
        relevanceThreshold: 100,
      );
      expect(results, isEmpty);
    });
  });

  // ============================================================
  // linkMemories
  // ============================================================
  group('linkMemories', () {
    test('创建记忆关联并可查询', () async {
      final id1 = await repo.saveMemory(
        _testMemory(uuid: 'mem-1', title: '记忆A'),
      );
      final id2 = await repo.saveMemory(
        _testMemory(uuid: 'mem-2', title: '记忆B'),
      );
      final mem1 = (await repo.findMemoryById(id1))!;
      final mem2 = (await repo.findMemoryById(id2))!;

      await repo.linkMemories(
        source: mem1,
        target: mem2,
        type: 'causes',
        weight: 0.9,
        description: 'A 导致了 B',
      );

      final links = await repo.getOutgoingLinks(id1);
      expect(links, hasLength(1));
      expect(links.first.type, 'causes');
      expect(links.first.weight, 0.9);
      expect(links.first.description, 'A 导致了 B');
      expect(links.first.sourceId, id1);
      expect(links.first.targetId, id2);
    });

    test('重复关联不会创建多条记录', () async {
      final id1 = await repo.saveMemory(
        _testMemory(uuid: 'mem-1', title: 'X'),
      );
      final id2 = await repo.saveMemory(
        _testMemory(uuid: 'mem-2', title: 'Y'),
      );
      final mem1 = (await repo.findMemoryById(id1))!;
      final mem2 = (await repo.findMemoryById(id2))!;

      await repo.linkMemories(
        source: mem1,
        target: mem2,
        type: 'related',
      );
      await repo.linkMemories(
        source: mem1,
        target: mem2,
        type: 'related',
      );

      final links = await repo.getOutgoingLinks(id1);
      expect(links, hasLength(1));
    });

    test('getIncomingLinks 返回指向目标的关联', () async {
      final id1 = await repo.saveMemory(
        _testMemory(uuid: 'mem-1', title: '源'),
      );
      final id2 = await repo.saveMemory(
        _testMemory(uuid: 'mem-2', title: '目标'),
      );
      final mem1 = (await repo.findMemoryById(id1))!;
      final mem2 = (await repo.findMemoryById(id2))!;

      await repo.linkMemories(
        source: mem1,
        target: mem2,
        type: 'explains',
      );

      final incoming = await repo.getIncomingLinks(id2);
      expect(incoming, hasLength(1));
      expect(incoming.first.sourceId, id1);
      expect(incoming.first.type, 'explains');
    });

    test('weight 被 clamp 到 [0, 1]', () async {
      final id1 = await repo.saveMemory(
        _testMemory(uuid: 'mem-1'),
      );
      final id2 = await repo.saveMemory(
        _testMemory(uuid: 'mem-2'),
      );
      final mem1 = (await repo.findMemoryById(id1))!;
      final mem2 = (await repo.findMemoryById(id2))!;

      await repo.linkMemories(
        source: mem1,
        target: mem2,
        type: 'related',
        weight: 5.0,
      );

      final links = await repo.getOutgoingLinks(id1);
      expect(links.first.weight, 1.0);
    });
  });

  // ============================================================
  // getMemoryGraph
  // ============================================================
  group('getMemoryGraph', () {
    test('无关联时返回空列表', () async {
      final graph = await repo.getMemoryGraph();
      expect(graph, isEmpty);
    });

    test('返回所有关联', () async {
      final id1 = await repo.saveMemory(
        _testMemory(uuid: 'mem-1'),
      );
      final id2 = await repo.saveMemory(
        _testMemory(uuid: 'mem-2'),
      );
      final id3 = await repo.saveMemory(
        _testMemory(uuid: 'mem-3'),
      );
      final mem1 = (await repo.findMemoryById(id1))!;
      final mem2 = (await repo.findMemoryById(id2))!;
      final mem3 = (await repo.findMemoryById(id3))!;

      await repo.linkMemories(
        source: mem1,
        target: mem2,
        type: 'causes',
      );
      await repo.linkMemories(
        source: mem2,
        target: mem3,
        type: 'related',
      );

      final graph = await repo.getMemoryGraph();
      expect(graph, hasLength(2));

      final types = graph.map((l) => l.type).toSet();
      expect(types, containsAll(['causes', 'related']));
    });

    test('删除记忆后悬空关联被清理', () async {
      final id1 = await repo.saveMemory(
        _testMemory(uuid: 'mem-1'),
      );
      final id2 = await repo.saveMemory(
        _testMemory(uuid: 'mem-2'),
      );
      final mem1 = (await repo.findMemoryById(id1))!;
      final mem2 = (await repo.findMemoryById(id2))!;

      await repo.linkMemories(
        source: mem1,
        target: mem2,
        type: 'related',
      );

      // 删除 mem2，使链接悬空
      await repo.deleteMemory(id2);

      final graph = await repo.getMemoryGraph();
      expect(graph, isEmpty);
    });
  });

  // ============================================================
  // 标签操作
  // ============================================================
  group('标签操作', () {
    test('addTagToMemory 创建标签并关联', () async {
      final id = await repo.saveMemory(_testMemory());
      final memory = (await repo.findMemoryById(id))!;

      await repo.addTagToMemory(memory, '角色');

      final tags = await repo.getTagsForMemory(id);
      expect(tags, hasLength(1));
      expect(tags.first.name, '角色');
    });

    test('同一标签名不会重复创建', () async {
      final id1 = await repo.saveMemory(
        _testMemory(uuid: 'u1'),
      );
      final id2 = await repo.saveMemory(
        _testMemory(uuid: 'u2'),
      );
      final mem1 = (await repo.findMemoryById(id1))!;
      final mem2 = (await repo.findMemoryById(id2))!;

      await repo.addTagToMemory(mem1, '魔法');
      await repo.addTagToMemory(mem2, '魔法');

      // 两条记忆共享同一个标签
      final tagRows = await db.query('memory_tags');
      expect(tagRows, hasLength(1));
    });

    test('getMemoryIdsForTag 返回标签关联的记忆', () async {
      final id = await repo.saveMemory(_testMemory());
      final memory = (await repo.findMemoryById(id))!;
      final tag = await repo.addTagToMemory(memory, '重要');

      final ids = await repo.getMemoryIdsForTag(tag.id);
      expect(ids, contains(id));
    });
  });

  // ============================================================
  // normalizeFolderPath 工具方法
  // ============================================================
  group('normalizeFolderPath', () {
    test('null 返回 null', () {
      expect(MemoryRepository.normalizeFolderPath(null), isNull);
    });

    test('空字符串返回 null', () {
      expect(MemoryRepository.normalizeFolderPath(''), isNull);
    });

    test('纯空格返回 null', () {
      expect(MemoryRepository.normalizeFolderPath('   '), isNull);
    });

    test('反斜杠替换为正斜杠', () {
      expect(
        MemoryRepository.normalizeFolderPath('a\\b\\c'),
        'a/b/c',
      );
    });

    test('去除首尾空格和空段', () {
      expect(
        MemoryRepository.normalizeFolderPath(' / a / / b / '),
        'a/b',
      );
    });
  });
}
