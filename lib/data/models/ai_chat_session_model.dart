import 'dart:convert';

/// AI 对话会话数据模型（支持 JSON 序列化）
class AiChatSessionModel {
  final String id;
  String title;
  List<Map<String, String>> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  AiChatSessionModel({
    required this.id,
    required this.title,
    List<Map<String, String>>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : messages = messages != null ? List.from(messages) : [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// 创建一个可立即持久化的新会话。
  factory AiChatSessionModel.create({String? title}) {
    final now = DateTime.now();
    return AiChatSessionModel(
      id: now.microsecondsSinceEpoch.toString(),
      title: title ?? '新对话',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 从 JSON 构造
  factory AiChatSessionModel.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final rawMessages = json['messages'];
    final messages = <Map<String, String>>[];
    if (rawMessages is List) {
      for (final rawMessage in rawMessages) {
        if (rawMessage is! Map) continue;
        final role = rawMessage['role']?.toString();
        final content = rawMessage['content']?.toString();
        if (role == null || content == null) continue;
        messages.add({'role': role, 'content': content});
      }
    }

    final createdAt = _parseDateTime(json['createdAt']) ?? now;
    return AiChatSessionModel(
      id: json['id']?.toString() ?? now.microsecondsSinceEpoch.toString(),
      title: json['title']?.toString().trim().isNotEmpty == true
          ? json['title'].toString()
          : '未命名对话',
      messages: messages,
      createdAt: createdAt,
      // 兼容早期没有 updatedAt 的历史文件。
      updatedAt: _parseDateTime(json['updatedAt']) ?? createdAt,
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  /// 转为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 转为 JSON 字符串
  String toJsonString() => jsonEncode(toJson());

  /// 从 JSON 字符串构造
  static AiChatSessionModel fromJsonString(String jsonString) {
    return AiChatSessionModel.fromJson(jsonDecode(jsonString));
  }

  /// 更新消息并刷新更新时间
  void updateMessages(List<Map<String, String>> newMessages) {
    messages = List.from(newMessages);
    touch();
  }

  /// 添加消息
  void addMessage(Map<String, String> message) {
    messages.add(message);
    touch();
  }

  /// 标记会话内容或标题刚刚发生了变化。
  void touch() {
    updatedAt = DateTime.now();
  }

  AiChatSessionModel copy() {
    return AiChatSessionModel(
      id: id,
      title: title,
      messages: messages.map(Map<String, String>.from).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// 获取消息数量
  int get messageCount => messages.length;

  /// 获取最后一条消息预览
  String get lastMessagePreview {
    if (messages.isEmpty) return '';
    final last = messages.last;
    final content = (last['content'] ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
    return content.length > 30 ? '${content.substring(0, 30)}...' : content;
  }
}

/// 会话列表包装类
class AiChatSessionList {
  final List<AiChatSessionModel> sessions;

  AiChatSessionList({required this.sessions});

  factory AiChatSessionList.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'];
    return AiChatSessionList(
      sessions: rawSessions is List
          ? rawSessions
                .whereType<Map>()
                .map(
                  (s) => AiChatSessionModel.fromJson(
                    Map<String, dynamic>.from(s),
                  ),
                )
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': 2,
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  static AiChatSessionList fromJsonString(String jsonString) {
    return AiChatSessionList.fromJson(jsonDecode(jsonString));
  }
}
