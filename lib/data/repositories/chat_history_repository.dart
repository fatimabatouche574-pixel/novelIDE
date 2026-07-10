import 'dart:async';
import 'dart:io';
import 'package:novel_ide/data/models/ai_chat_session_model.dart';
import 'package:novel_ide/data/datasources/public_storage_helper.dart';

/// AI 对话历史记录仓库
/// 将会话列表持久化到本地 JSON 文件
class ChatHistoryRepository {
  static const String _fileName = 'ai_chat_history.json';
  static const String _backupFileName = 'ai_chat_history.backup.json';
  static const int _maxSessions = 100; // 最多保存 100 个会话
  static const int _maxMessagesPerSession = 200; // 单个会话最多 200 条消息
  static Future<void> _writeQueue = Future<void>.value();

  Future<T> _serializeWrite<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  /// 获取存储文件路径
  Future<String> _getFilePath() async {
    final root = PublicStorageHelper.publicRoot;
    return '${root.path}/$_fileName';
  }

  Future<String> _getBackupFilePath() async {
    final root = PublicStorageHelper.publicRoot;
    return '${root.path}/$_backupFileName';
  }

  /// 确保目录存在
  Future<void> _ensureDirectory() async {
    // 公共目录由 PublicStorageHelper 统一管理，无需额外创建
  }

  /// 加载所有会话
  Future<List<AiChatSessionModel>> loadSessions() async {
    await _writeQueue;
    return _loadSessionsNow();
  }

  Future<List<AiChatSessionModel>> _loadSessionsNow() async {
    final filePath = await _getFilePath();
    final backupPath = await _getBackupFilePath();
    try {
      await _ensureDirectory();
      final file = File(filePath);

      if (!await file.exists()) {
        final backup = File(backupPath);
        if (!await backup.exists()) return [];
        return _decodeSessions(await backup.readAsString());
      }

      return _decodeSessions(await file.readAsString());
    } catch (e) {
      print('ChatHistoryRepository load error: $e');
      // 主文件异常时优先恢复上一份完整备份，避免下一次保存覆盖历史。
      try {
        final backup = File(backupPath);
        if (await backup.exists()) {
          final recovered = _decodeSessions(await backup.readAsString());
          final damaged = File(filePath);
          if (await damaged.exists()) {
            await damaged.rename(
              '$filePath.corrupt.${DateTime.now().millisecondsSinceEpoch}',
            );
          }
          await backup.copy(filePath);
          return recovered;
        }
      } catch (backupError) {
        print('ChatHistoryRepository backup load error: $backupError');
      }
      final damaged = File(filePath);
      if (await damaged.exists()) {
        await damaged.rename(
          '$filePath.corrupt.${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      rethrow;
    }
  }

  List<AiChatSessionModel> _decodeSessions(String jsonString) {
    final sessionList = AiChatSessionList.fromJsonString(jsonString);
    return List<AiChatSessionModel>.of(sessionList.sessions)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// 保存所有会话
  Future<void> saveSessions(List<AiChatSessionModel> sessions) {
    final snapshot = sessions.map((session) => session.copy()).toList();
    return _serializeWrite(() async {
      final existing = await _loadSessionsNow();
      final merged = <String, AiChatSessionModel>{
        for (final session in existing) session.id: session,
      };
      for (final session in snapshot) {
        merged[session.id] = session;
      }
      await _saveSessionsNow(merged.values.toList());
    });
  }

  Future<void> _saveSessionsNow(List<AiChatSessionModel> sessions) async {
    try {
      await _ensureDirectory();

      // 使用副本排序与裁剪，不能改乱调用方正在显示的会话顺序。
      final sortedSessions = sessions.map((session) => session.copy()).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final trimmedSessions = sortedSessions.take(_maxSessions).toList();

      // 限制每个会话的消息数量
      for (final session in trimmedSessions) {
        if (session.messages.length > _maxMessagesPerSession) {
          // 保留最新的消息
          session.messages = session.messages.sublist(
            session.messages.length - _maxMessagesPerSession,
          );
        }
      }

      final sessionList = AiChatSessionList(sessions: trimmedSessions);
      final filePath = await _getFilePath();
      final file = File(filePath);
      final backup = File(await _getBackupFilePath());
      final temporary = File('$filePath.tmp');

      await temporary.writeAsString(sessionList.toJsonString(), flush: true);
      if (await file.exists()) {
        await file.copy(backup.path);
        await file.delete();
      }
      await temporary.rename(filePath);
    } catch (e) {
      print('ChatHistoryRepository save error: $e');
      rethrow;
    }
  }

  /// 添加或更新单个会话
  Future<void> saveSession(AiChatSessionModel session) {
    final snapshot = session.copy();
    return _serializeWrite(() async {
      final sessions = await _loadSessionsNow();

      // 查找是否已存在
      final index = sessions.indexWhere((s) => s.id == snapshot.id);
      if (index >= 0) {
        sessions[index] = snapshot;
      } else {
        sessions.add(snapshot);
      }

      await _saveSessionsNow(sessions);
    });
  }

  /// 删除单个会话
  Future<void> deleteSession(String sessionId) {
    return _serializeWrite(() async {
      final sessions = await _loadSessionsNow();
      sessions.removeWhere((s) => s.id == sessionId);
      await _saveSessionsNow(sessions);
    });
  }

  /// 批量删除会话，只写入一次文件。
  Future<void> deleteSessions(Set<String> sessionIds) {
    if (sessionIds.isEmpty) return Future<void>.value();
    final ids = Set<String>.of(sessionIds);
    return _serializeWrite(() async {
      final sessions = await _loadSessionsNow();
      sessions.removeWhere((session) => ids.contains(session.id));
      await _saveSessionsNow(sessions);
    });
  }

  /// 清空所有会话
  Future<void> clearAllSessions() {
    return _serializeWrite(() async {
      try {
        final filePath = await _getFilePath();
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        final backup = File(await _getBackupFilePath());
        if (await backup.exists()) {
          await backup.delete();
        }
      } catch (e) {
        print('ChatHistoryRepository clear error: $e');
      }
    });
  }

  /// 获取会话数量
  Future<int> getSessionCount() async {
    final sessions = await loadSessions();
    return sessions.length;
  }

  /// 获取存储文件大小（字节）
  Future<int> getStorageSize() async {
    try {
      await _writeQueue;
      final filePath = await _getFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
