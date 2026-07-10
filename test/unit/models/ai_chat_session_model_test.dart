import 'package:flutter_test/flutter_test.dart';
import 'package:novel_ide/data/models/ai_chat_session_model.dart';

void main() {
  group('AiChatSessionModel', () {
    test('兼容缺少 updatedAt 的旧会话数据', () {
      final session = AiChatSessionModel.fromJson({
        'id': 'legacy-session',
        'title': '旧会话',
        'messages': [
          {'role': 'user', 'content': '之前的消息'},
        ],
        'createdAt': '2026-01-01T08:00:00.000',
      });

      expect(session.id, 'legacy-session');
      expect(session.messageCount, 1);
      expect(session.updatedAt, session.createdAt);
    });

    test('忽略损坏消息但保留可读取的历史', () {
      final session = AiChatSessionModel.fromJson({
        'id': 'mixed-session',
        'title': '混合数据',
        'messages': [
          {'role': 'user', 'content': '有效消息'},
          {'role': 'assistant'},
          'invalid',
        ],
      });

      expect(session.messages, [
        {'role': 'user', 'content': '有效消息'},
      ]);
    });

    test('copy 不与原会话共享消息列表', () {
      final original = AiChatSessionModel.create()
        ..addMessage({'role': 'user', 'content': '你好'});
      final copied = original.copy();

      copied.messages.first['content'] = '已修改';
      expect(original.messages.first['content'], '你好');
    });
  });
}
