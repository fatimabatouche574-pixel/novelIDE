/// 搜索评分模式
enum MemoryScoreMode {
  /// 均衡模式：关键词、语义、边权重均衡使用
  balanced,

  /// 关键词优先：关键词权重放大，语义权重缩小
  keywordFirst,

  /// 语义优先：语义权重放大，关键词权重缩小
  semanticFirst,
}

/// 记忆搜索配置
///
/// 控制搜索时各维度的权重分配和评分策略。
class MemorySearchConfig {
  /// 评分模式
  final MemoryScoreMode scoreMode;

  /// 关键词权重
  final double keywordWeight;

  /// 标签权重
  final double tagWeight;

  /// 向量（语义）权重
  final double vectorWeight;

  /// 知识图谱边权重
  final double edgeWeight;

  const MemorySearchConfig({
    this.scoreMode = MemoryScoreMode.balanced,
    this.keywordWeight = 10.0,
    this.tagWeight = 0.0,
    this.vectorWeight = 0.0,
    this.edgeWeight = 0.4,
  });

  /// 创建一个副本，可选择性地覆盖部分字段
  MemorySearchConfig copyWith({
    MemoryScoreMode? scoreMode,
    double? keywordWeight,
    double? tagWeight,
    double? vectorWeight,
    double? edgeWeight,
  }) {
    return MemorySearchConfig(
      scoreMode: scoreMode ?? this.scoreMode,
      keywordWeight: keywordWeight ?? this.keywordWeight,
      tagWeight: tagWeight ?? this.tagWeight,
      vectorWeight: vectorWeight ?? this.vectorWeight,
      edgeWeight: edgeWeight ?? this.edgeWeight,
    );
  }

  /// 返回一个所有权重非负的归一化副本
  MemorySearchConfig normalized() {
    return copyWith(
      keywordWeight: keywordWeight < 0 ? 0.0 : keywordWeight,
      tagWeight: tagWeight < 0 ? 0.0 : tagWeight,
      vectorWeight: vectorWeight < 0 ? 0.0 : vectorWeight,
      edgeWeight: edgeWeight < 0 ? 0.0 : edgeWeight,
    );
  }

  /// 从 JSON 反序列化
  factory MemorySearchConfig.fromJson(Map<String, dynamic> json) {
    return MemorySearchConfig(
      scoreMode: _scoreModeFromString(
        json['score_mode'] as String? ?? 'balanced',
      ),
      keywordWeight:
          (json['keyword_weight'] as num?)?.toDouble() ?? 10.0,
      tagWeight: (json['tag_weight'] as num?)?.toDouble() ?? 0.0,
      vectorWeight:
          (json['vector_weight'] as num?)?.toDouble() ?? 0.0,
      edgeWeight: (json['edge_weight'] as num?)?.toDouble() ?? 0.4,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'score_mode': scoreMode.name,
      'keyword_weight': keywordWeight,
      'tag_weight': tagWeight,
      'vector_weight': vectorWeight,
      'edge_weight': edgeWeight,
    };
  }

  /// 根据评分模式获取关键词乘数
  double get keywordMultiplier {
    switch (scoreMode) {
      case MemoryScoreMode.balanced:
        return 1.0;
      case MemoryScoreMode.keywordFirst:
        return 1.3;
      case MemoryScoreMode.semanticFirst:
        return 0.8;
    }
  }

  /// 根据评分模式获取语义乘数
  double get semanticMultiplier {
    switch (scoreMode) {
      case MemoryScoreMode.balanced:
        return 1.0;
      case MemoryScoreMode.keywordFirst:
        return 0.8;
      case MemoryScoreMode.semanticFirst:
        return 1.3;
    }
  }

  /// 根据评分模式获取边权重乘数
  double get edgeMultiplier {
    switch (scoreMode) {
      case MemoryScoreMode.balanced:
        return 1.0;
      case MemoryScoreMode.keywordFirst:
        return 0.9;
      case MemoryScoreMode.semanticFirst:
        return 1.1;
    }
  }

  static MemoryScoreMode _scoreModeFromString(String value) {
    switch (value) {
      case 'keywordFirst':
        return MemoryScoreMode.keywordFirst;
      case 'semanticFirst':
        return MemoryScoreMode.semanticFirst;
      default:
        return MemoryScoreMode.balanced;
    }
  }
}
