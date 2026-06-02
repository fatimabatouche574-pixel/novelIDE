import 'package:novel_ide/data/models/memory/memory_entity.dart';
import 'package:novel_ide/data/models/memory/memory_repository.dart';

/// 记忆三阶段管线
///
/// 阶段一：语义边界分割 — 按语义切段（不是按字数硬切）
/// 阶段二：语义段处理 — 抽取结构化记录：实体/关系/置信度
/// 阶段三：记忆整合 — 实体消歧 + 时间聚合 + 合并知识图谱
class MemoryPipeline {
  final MemoryRepository _repository;

  MemoryPipeline({required MemoryRepository repository})
      : _repository = repository;

  // =================================================================
  // 阶段一：语义边界分割
  // =================================================================

  /// 将对话文本按语义切段
  ///
  /// 返回的每个段落是一个独立的语义单元，包含：
  /// - role: 发言角色
  /// - content: 发言内容
  /// - topicHint: 话题线索（从工具调用/关键词推断）
  List<SemanticSegment> segmentConversation(
    List<Map<String, String>> messages,
    List<String> toolCallNames,
  ) {
    final segments = <SemanticSegment>[];
    final buffer = StringBuffer();
    String currentTopic = 'general';
    String currentRole = 'user';

    for (int i = 0; i < messages.length; i++) {
      final role = messages[i]['role'] ?? 'user';
      final content = messages[i]['content'] ?? '';

      // 检测话题切换信号
      final newTopic = _detectTopic(content, role);
      if (newTopic != currentTopic && buffer.isNotEmpty) {
        segments.add(SemanticSegment(
          role: currentRole,
          content: buffer.toString().trim(),
          topicHint: currentTopic,
          startIndex: i,
        ));
        buffer.clear();
      }
      currentTopic = newTopic;
      currentRole = role;

      // 过滤工具结果消息（太长，不适合直接存为记忆）
      if (role == 'tool' && content.length > 300) {
        buffer.writeln('[工具结果摘要]');
      } else {
        buffer.writeln(content);
      }
    }

    // 最后一段
    if (buffer.isNotEmpty) {
      segments.add(SemanticSegment(
        role: currentRole,
        content: buffer.toString().trim(),
        topicHint: currentTopic,
        startIndex: messages.length,
      ));
    }

    return segments;
  }

  /// 从内容中推断话题
  String _detectTopic(String content, String role) {
    final lower = content.toLowerCase();

    // 写作相关话题
    if (_containsAny(lower, ['角色', '人物', '性格', '外貌', '背景'])) {
      return 'character';
    }
    if (_containsAny(lower, ['设定', '世界观', '体系', '规则'])) {
      return 'setting';
    }
    if (_containsAny(lower, ['剧情', '情节', '大纲', '走向', '发展'])) {
      return 'plot';
    }
    if (_containsAny(lower, ['伏笔', '悬念', '坑', '埋', '回收'])) {
      return 'hook';
    }
    if (_containsAny(lower, ['地点', '场景', '地图', '位置'])) {
      return 'location';
    }
    if (_containsAny(lower, ['势力', '组织', '门派', '阵营'])) {
      return 'faction';
    }
    if (_containsAny(lower, ['道具', '物品', '装备', '法宝'])) {
      return 'item';
    }
    if (_containsAny(lower, ['写', '章', '续', '润色', '扩写'])) {
      return 'writing';
    }

    return 'general';
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  // =================================================================
  // 阶段二：语义段处理 — 结构化抽取
  // =================================================================

  /// 从语义段中抽取结构化记忆记录
  ///
  /// 使用规则+模式匹配（不调用LLM，本地快速处理）
  List<ExtractedEntity> extractEntities(SemanticSegment segment) {
    final entities = <ExtractedEntity>[];

    // 根据话题类型提取不同实体
    switch (segment.topicHint) {
      case 'character':
        entities.addAll(_extractCharacters(segment.content));
        break;
      case 'setting':
        entities.add(ExtractedEntity(
          type: EntityType.setting,
          name: _extractTitle(segment.content),
          description: _extractDescription(segment.content),
          confidence: 0.6,
        ));
        break;
      case 'plot':
        entities.add(ExtractedEntity(
          type: EntityType.event,
          name: '剧情: ${_extractTitle(segment.content)}',
          description: _extractDescription(segment.content),
          confidence: 0.5,
        ));
        break;
      case 'hook':
        entities.add(ExtractedEntity(
          type: EntityType.event,
          name: '伏笔: ${_extractTitle(segment.content)}',
          description: _extractDescription(segment.content),
          confidence: 0.7,
        ));
        break;
      case 'location':
        entities.add(ExtractedEntity(
          type: EntityType.location,
          name: _extractTitle(segment.content),
          description: _extractDescription(segment.content),
          confidence: 0.6,
        ));
        break;
      case 'faction':
        entities.add(ExtractedEntity(
          type: EntityType.faction,
          name: _extractTitle(segment.content),
          description: _extractDescription(segment.content),
          confidence: 0.6,
        ));
        break;
      case 'item':
        entities.add(ExtractedEntity(
          type: EntityType.item,
          name: _extractTitle(segment.content),
          description: _extractDescription(segment.content),
          confidence: 0.5,
        ));
        break;
      default:
        // 通用：存为摘要记忆
        if (segment.content.length > 30) {
          entities.add(ExtractedEntity(
            type: EntityType.summary,
            name: _extractTitle(segment.content),
            description: _extractDescription(segment.content),
            confidence: 0.3,
          ));
        }
    }

    return entities;
  }

  /// 提取角色信息
  List<ExtractedEntity> _extractCharacters(String content) {
    final entities = <ExtractedEntity>[];

    // 模式：名字/角色名 + 描述
    final namePatterns = [
      RegExp(r'(?:叫|名叫|名字是|名为)\s*[「『]?(\S+?)[」』]?[,，。]'),
      RegExp(r'(?:角色|人物)[：:]\s*[「『]?(\S+?)[」』]?[,，。]'),
    ];

    for (final pattern in namePatterns) {
      for (final match in pattern.allMatches(content)) {
        final name = match.group(1);
        if (name != null && name.length >= 2 && name.length <= 10) {
          entities.add(ExtractedEntity(
            type: EntityType.character,
            name: name,
            description: _extractDescription(content),
            confidence: 0.7,
          ));
        }
      }
    }

    // 未匹配到具体名字时，存为通用角色记忆
    if (entities.isEmpty && content.length > 20) {
      entities.add(ExtractedEntity(
        type: EntityType.character,
        name: '角色讨论: ${_extractTitle(content)}',
        description: _extractDescription(content),
        confidence: 0.4,
      ));
    }

    return entities;
  }

  /// 提取标题（取前30字或第一个句号前）
  String _extractTitle(String content) {
    final firstSentence = content.split(RegExp(r'[。！？\n]')).first;
    if (firstSentence.length <= 30) return firstSentence.trim();
    return '${firstSentence.substring(0, 30).trim()}...';
  }

  /// 提取描述（取前200字）
  String _extractDescription(String content) {
    final clean = content.replaceAll(RegExp(r'\n+'), ' ').trim();
    if (clean.length <= 200) return clean;
    return '${clean.substring(0, 200).trim()}...';
  }

  // =================================================================
  // 阶段三：记忆整合 — 消歧 + 聚合 + 图谱
  // =================================================================

  /// 将抽取的实体整合到记忆系统
  ///
  /// 1. 实体消歧：同名/相似实体合并
  /// 2. 写入 memories 表
  /// 3. 建立 memory_links 关联
  Future<List<Memory>> integrateMemories({
    required List<ExtractedEntity> entities,
    required String novelId,
  }) async {
    final saved = <Memory>[];

    for (final entity in entities) {
      // 实体消歧：查找已有同名记忆
      final existing = await _findExistingMemory(entity.name, novelId);

      if (existing != null) {
        // 合并：更新内容（追加新信息，不覆盖旧的）
        final mergedContent = _mergeContent(
          existing.content,
          entity.description,
        );
        final updated = Memory(
          id: existing.id,
          uuid: existing.uuid,
          novelId: existing.novelId,
          title: existing.title,
          content: mergedContent,
          contentType: existing.contentType,
          source: 'pipeline_${entity.type.name}',
          credibility: _updateCredibility(
            existing.credibility,
            entity.confidence,
          ),
          importance: existing.importance,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
        );
        await _repository.saveMemory(updated);
        final refetched = await _repository.findMemoryById(updated.id);
        if (refetched != null) saved.add(refetched);
      } else {
        // 新建记忆
        final memory = await _repository.createMemory(
          title: entity.name,
          content: entity.description,
          source: 'pipeline_${entity.type.name}',
          folderPath: _entityTypeToFolder(entity.type),
          tags: [entity.type.name],
        );
        if (memory != null) saved.add(memory);
      }
    }

    // 建立关联：同类型实体之间自动建立 related 链接
    await _autoLinkEntities(saved);

    return saved;
  }

  /// 查找已有同名记忆（模糊匹配）
  Future<Memory?> _findExistingMemory(String name, String novelId) async {
    final results = await _repository.searchMemories(
      query: name,
      novelId: novelId,
    );
    // 精确匹配标题
    for (final m in results) {
      if (m.title == name || m.title.contains(name)) {
        return m;
      }
    }
    return null;
  }

  /// 合并内容（去重后追加）
  String _mergeContent(String existing, String newContent) {
    if (existing.contains(newContent)) return existing;
    if (newContent.contains(existing)) return newContent;
    return '$existing\n---\n$newContent';
  }

  /// 更新可信度（多次验证提升可信度）
  double _updateCredibility(double current, double newConfidence) {
    // 最高不超过 1.0，取加权平均
    final merged = (current * 0.7 + newConfidence * 0.3);
    return merged.clamp(0.0, 1.0);
  }

  /// 实体类型映射到文件夹路径
  String _entityTypeToFolder(EntityType type) {
    switch (type) {
      case EntityType.character:
        return '角色记忆';
      case EntityType.setting:
        return '设定记忆';
      case EntityType.location:
        return '地点记忆';
      case EntityType.faction:
        return '势力记忆';
      case EntityType.item:
        return '道具记忆';
      case EntityType.event:
        return '事件记忆';
      case EntityType.summary:
        return '对话摘要';
    }
  }

  /// 自动为同类型同批次的记忆建立关联
  Future<void> _autoLinkEntities(List<Memory> memories) async {
    for (int i = 0; i < memories.length; i++) {
      for (int j = i + 1; j < memories.length; j++) {
        final a = memories[i];
        final b = memories[j];
        // 同类型或相关类型建立关联
        if (_shouldLink(a, b)) {
          await _repository.linkMemories(
            source: a,
            target: b,
            type: 'related',
            weight: 0.5,
          );
        }
      }
    }
  }

  /// 判断两个记忆是否应该关联
  bool _shouldLink(Memory a, Memory b) {
    // 同标签
    final aTags = a.tags.map((t) => t.name).toSet();
    final bTags = b.tags.map((t) => t.name).toSet();
    if (aTags.intersection(bTags).isNotEmpty) return true;

    // 同文件夹
    if (a.folderPath != null &&
        a.folderPath == b.folderPath) return true;

    return false;
  }

  // =================================================================
  // 一站式执行：完整管线
  // =================================================================

  /// 执行完整的三阶段管线
  ///
  /// 输入：对话消息 + 工具调用记录 + novelId
  /// 输出：整合后的记忆列表
  Future<List<Memory>> run({
    required List<Map<String, String>> messages,
    required List<String> toolCallNames,
    required String novelId,
  }) async {
    // 阶段一：语义分割
    final segments = segmentConversation(messages, toolCallNames);
    if (segments.isEmpty) return [];

    // 阶段二：结构化抽取
    final allEntities = <ExtractedEntity>[];
    for (final segment in segments) {
      allEntities.addAll(extractEntities(segment));
    }
    if (allEntities.isEmpty) return [];

    // 阶段三：整合入库
    return integrateMemories(
      entities: allEntities,
      novelId: novelId,
    );
  }
}

// =================================================================
// 数据类型
// =================================================================

/// 语义段
class SemanticSegment {
  final String role;
  final String content;
  final String topicHint;
  final int startIndex;

  const SemanticSegment({
    required this.role,
    required this.content,
    required this.topicHint,
    required this.startIndex,
  });
}

/// 实体类型
enum EntityType {
  character, // 角色
  setting, // 设定
  location, // 地点
  faction, // 势力
  item, // 道具
  event, // 事件/伏笔
  summary, // 摘要
}

/// 抽取出的结构化实体
class ExtractedEntity {
  final EntityType type;
  final String name;
  final String description;
  final double confidence;

  const ExtractedEntity({
    required this.type,
    required this.name,
    required this.description,
    this.confidence = 0.5,
  });
}
