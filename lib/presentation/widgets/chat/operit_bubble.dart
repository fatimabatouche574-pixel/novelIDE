import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';
import 'package:novel_ide/presentation/widgets/chat/operit_chat_models.dart';
import 'package:novel_ide/presentation/widgets/chat/operit_thinking_indicator.dart';
import 'package:novel_ide/presentation/widgets/chat/operit_tool_card.dart';

/// AI 消息气泡 — 左对齐
///
/// 头像圆 + 名称在上方，消息内容带 [UiTokens.surfaceVariant] 边框，
/// 内联 [OperitToolCard] 列表，可折叠的思考中指示器，底部 token / 时间脚注。
class OperitAiBubble extends StatelessWidget {
  const OperitAiBubble({
    super.key,
    required this.message,
    this.avatar,
    this.name = 'AI 助手',
    this.timestamp,
    this.toolCalls,
    this.isThinking = false,
    this.tokenCount,
  });

  /// 消息文本
  final String message;

  /// 头像 URL
  final String? avatar;

  /// 显示名称
  final String name;

  /// 时间戳文本，如 "14:32"
  final String? timestamp;

  /// 内联工具调用列表
  final List<OperitToolCall>? toolCalls;

  /// 是否显示思考中状态
  final bool isThinking;

  /// Token 消耗文本，如 "1.2k tokens"
  final String? tokenCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头像
          _AiAvatar(name: name, avatarUrl: avatar),
          const SizedBox(width: 10),
          // 内容区
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 名称
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: UiTokens.smallFS,
                    fontWeight: FontWeight.w600,
                    color: UiTokens.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                // 思考中指示器
                if (isThinking) const OperitThinkingIndicator(),
                // 消息容器
                Container(
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  decoration: BoxDecoration(
                    color: UiTokens.surface,
                    borderRadius: BorderRadius.circular(UiTokens.bubbleRadius),
                    border: Border.all(color: UiTokens.surfaceVariant),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        message,
                        style: const TextStyle(
                          fontSize: UiTokens.bodyFS,
                          color: UiTokens.onSurface,
                          height: 1.5,
                        ),
                      ),
                      // 内联工具调用卡片
                      if (toolCalls != null && toolCalls!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...toolCalls!.map(
                          (tc) => OperitToolCard(
                            toolName: tc.toolName,
                            toolParams: tc.toolParams,
                            toolResult: tc.toolResult,
                            status: tc.status,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // 底部信息：token + 时间
                _BubbleFooter(tokenCount: tokenCount, timestamp: timestamp),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 用户消息气泡 — 右对齐
///
/// 紫色 [UiTokens.primary] 背景容器，白色文字，右对齐布局。
class OperitUserBubble extends StatelessWidget {
  const OperitUserBubble({super.key, required this.message, this.timestamp});

  /// 消息文本
  final String message;

  /// 时间戳文本
  final String? timestamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  decoration: BoxDecoration(
                    color: UiTokens.primary,
                    borderRadius: BorderRadius.circular(UiTokens.bubbleRadius),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    message,
                    style: const TextStyle(
                      fontSize: UiTokens.bodyFS,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                if (timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, right: 4),
                    child: Text(
                      timestamp!,
                      style: TextStyle(
                        fontSize: UiTokens.microFS,
                        color: UiTokens.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiAvatar extends StatelessWidget {
  const _AiAvatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: UiTokens.primaryContainer,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              name.characters.isNotEmpty ? name.characters.first : 'A',
              style: const TextStyle(
                fontSize: UiTokens.smallFS,
                fontWeight: FontWeight.w700,
                color: UiTokens.primary,
              ),
            )
          : null,
    );
  }
}

class _BubbleFooter extends StatelessWidget {
  const _BubbleFooter({this.tokenCount, this.timestamp});

  final String? tokenCount;
  final String? timestamp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (tokenCount != null)
            Text(
              tokenCount!,
              style: TextStyle(
                fontSize: UiTokens.microFS,
                color: UiTokens.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          if (tokenCount != null && timestamp != null)
            const Text(
              '  ·  ',
              style: TextStyle(
                fontSize: UiTokens.microFS,
                color: UiTokens.onSurfaceVariant,
              ),
            ),
          if (timestamp != null)
            Text(
              timestamp!,
              style: TextStyle(
                fontSize: UiTokens.microFS,
                color: UiTokens.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }
}
