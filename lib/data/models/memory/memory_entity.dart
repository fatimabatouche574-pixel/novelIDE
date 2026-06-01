import 'embedding.dart';

/// 记忆单元 (Memory Unit)
/// 代表一个独立的知识片段、事件、概念或任何AI需要记住的东西。
class Memory {
  /// 数据库主键（SQLite 自增 ID）
  final int id;

  /// 全局唯一标识符
  final String uuid;

  /// 关联小说ID（null 或空 = 全局记忆）
  final String novelId;

  // --- 核心内容 ---

  /// 记忆的简短标题/摘要
  final String title;

  /// 详细内容（可以是文本、JSON、文件路径等）
  final String content;

  /// 内容类型（如 "text/plain", "application/json"）
  final String contentType;

  // --- 元数据 ---

  /// 来源（如 "user_input", "chat_summary", "auto_generated"）
  final String source;

  /// 可信度 (0.0 ~ 1.0)
  final double credibility;

  /// 重要性 (0.0 ~ 1.0)
  final double importance;

  /// 文档节点的路径/URI
  final String? documentPath;

  /// 标记此记忆是否代表一个外部文档
  final bool isDocumentNode;

  /// 文档节点的区块索引文件路径
  final String? chunkIndexFilePath;

  /// 文件夹路径，用于分类组织记忆（如 "角色/主角"）
  /// null 视为"未分类"
  final String? folderPath;

  /// 文本内容的向量嵌入
  final Embedding? embedding;

  // --- 关联关系（由 Repository 层填充） ---

  /// 标签列表
  final List<MemoryTag> tags;

  /// 键值对属性列表
  final List<MemoryProperty> properties;

  /// 从这个记忆出发的关联（正向链接）
  final List<MemoryLink> links;

  /// 这个记忆作为目标被哪些关联指向（反向链接）
  final List<MemoryLink> backlinks;

  // --- 时间戳 ---

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime updatedAt;

  /// 最后访问时间
  final DateTime lastAccessedAt;

  Memory({
    this.id = 0,
    required this.uuid,
    this.novelId = '',
    this.title = '',
    this.content = '',
    this.contentType = 'text/plain',
    this.source = 'unknown',
    this.credibility = 0.5,
    this.importance = 0.5,
    this.documentPath,
    this.isDocumentNode = false,
    this.chunkIndexFilePath,
    this.folderPath,
    this.embedding,
    this.tags = const [],
    this.properties = const [],
    this.links = const [],
    this.backlinks = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        lastAccessedAt = lastAccessedAt ?? DateTime.now();

  Memory copyWith({
    int? id,
    String? uuid,
    String? novelId,
    String? title,
    String? content,
    String? contentType,
    String? source,
    double? credibility,
    double? importance,
    String? documentPath,
    bool? isDocumentNode,
    String? chunkIndexFilePath,
    String? folderPath,
    Embedding? embedding,
    List<MemoryTag>? tags,
    List<MemoryProperty>? properties,
    List<MemoryLink>? links,
    List<MemoryLink>? backlinks,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
  }) {
    return Memory(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      novelId: novelId ?? this.novelId,
      title: title ?? this.title,
      content: content ?? this.content,
      contentType: contentType ?? this.contentType,
      source: source ?? this.source,
      credibility: credibility ?? this.credibility,
      importance: importance ?? this.importance,
      documentPath: documentPath ?? this.documentPath,
      isDocumentNode: isDocumentNode ?? this.isDocumentNode,
      chunkIndexFilePath:
          chunkIndexFilePath ?? this.chunkIndexFilePath,
      folderPath: folderPath ?? this.folderPath,
      embedding: embedding ?? this.embedding,
      tags: tags ?? this.tags,
      properties: properties ?? this.properties,
      links: links ?? this.links,
      backlinks: backlinks ?? this.backlinks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as int? ?? 0,
      uuid: json['uuid'] as String,
      novelId: json['novel_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      contentType:
          json['content_type'] as String? ?? 'text/plain',
      source: json['source'] as String? ?? 'unknown',
      credibility:
          (json['credibility'] as num?)?.toDouble() ?? 0.5,
      importance:
          (json['importance'] as num?)?.toDouble() ?? 0.5,
      documentPath: json['document_path'] as String?,
      isDocumentNode:
          json['is_document_node'] as bool? ?? false,
      chunkIndexFilePath:
          json['chunk_index_file_path'] as String?,
      folderPath: json['folder_path'] as String?,
      embedding: json['embedding'] != null
          ? Embedding.fromJson(json['embedding'] as List<dynamic>)
          : null,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) =>
                  MemoryTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      properties: (json['properties'] as List<dynamic>?)
              ?.map((e) => MemoryProperty.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      links: (json['links'] as List<dynamic>?)
              ?.map((e) => MemoryLink.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      backlinks: (json['backlinks'] as List<dynamic>?)
              ?.map((e) => MemoryLink.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      lastAccessedAt: json['last_accessed_at'] != null
          ? DateTime.parse(
              json['last_accessed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'novel_id': novelId,
      'title': title,
      'content': content,
      'content_type': contentType,
      'source': source,
      'credibility': credibility,
      'importance': importance,
      'document_path': documentPath,
      'is_document_node': isDocumentNode,
      'chunk_index_file_path': chunkIndexFilePath,
      'folder_path': folderPath,
      'embedding': embedding?.toJson(),
      'tags': tags.map((e) => e.toJson()).toList(),
      'properties':
          properties.map((e) => e.toJson()).toList(),
      'links': links.map((e) => e.toJson()).toList(),
      'backlinks':
          backlinks.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_accessed_at': lastAccessedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Memory && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}

/// 记忆标签 (Memory Tag)
/// 用于对记忆进行分类和组织，支持层级结构。
class MemoryTag {
  final int id;
  final String name;
  final int? parentId;
  final List<int> memoryIds;

  const MemoryTag({
    this.id = 0,
    this.name = '',
    this.parentId,
    this.memoryIds = const [],
  });

  MemoryTag copyWith({
    int? id,
    String? name,
    int? parentId,
    List<int>? memoryIds,
  }) {
    return MemoryTag(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      memoryIds: memoryIds ?? this.memoryIds,
    );
  }

  factory MemoryTag.fromJson(Map<String, dynamic> json) {
    return MemoryTag(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      parentId: json['parent_id'] as int?,
      memoryIds: (json['memory_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'memory_ids': memoryIds,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemoryTag &&
        other.id == id &&
        other.name == name;
  }

  @override
  int get hashCode => Object.hash(id, name);
}

/// 记忆关联 (Memory Link)
/// 定义记忆之间的关系。
class MemoryLink {
  final int id;
  final int sourceId;
  final int targetId;

  /// 关联类型（如 "causes", "explains", "part_of", "related"）
  final String type;

  /// 关联强度 (0.0 ~ 1.0)
  final double weight;

  /// 关联的详细描述
  final String description;

  const MemoryLink({
    this.id = 0,
    required this.sourceId,
    required this.targetId,
    this.type = 'related',
    this.weight = 1.0,
    this.description = '',
  });

  MemoryLink copyWith({
    int? id,
    int? sourceId,
    int? targetId,
    String? type,
    double? weight,
    String? description,
  }) {
    return MemoryLink(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      weight: weight ?? this.weight,
      description: description ?? this.description,
    );
  }

  factory MemoryLink.fromJson(Map<String, dynamic> json) {
    return MemoryLink(
      id: json['id'] as int? ?? 0,
      sourceId: json['source_id'] as int,
      targetId: json['target_id'] as int,
      type: json['type'] as String? ?? 'related',
      weight:
          (json['weight'] as num?)?.toDouble() ?? 1.0,
      description:
          json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_id': sourceId,
      'target_id': targetId,
      'type': type,
      'weight': weight,
      'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemoryLink && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 记忆属性 (Memory Property)
/// 灵活的键值对存储，用于扩展记忆的元数据。
class MemoryProperty {
  final int id;
  final String key;
  final String value;

  const MemoryProperty({
    this.id = 0,
    this.key = '',
    this.value = '',
  });

  MemoryProperty copyWith({
    int? id,
    String? key,
    String? value,
  }) {
    return MemoryProperty(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  factory MemoryProperty.fromJson(Map<String, dynamic> json) {
    return MemoryProperty(
      id: json['id'] as int? ?? 0,
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MemoryProperty && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
