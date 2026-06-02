import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';
import 'package:novel_ide/presentation/widgets/chat/operit_token_ring.dart';

/// Operit 风格聊天顶部栏
///
/// 左侧：历史按钮 + PiP 按钮
/// 中央：角色选择胶囊（头像圆圈+名称+下拉箭头）
/// 右侧：Token 用量环形指示器
class OperitChatHeader extends StatelessWidget {
  const OperitChatHeader({
    super.key,
    this.onHistoryTap,
    this.onCharacterTap,
    this.onPiPTap,
    required this.tokenPercent,
    required this.characterName,
    this.characterAvatar,
  });

  /// 历史按钮回调
  final VoidCallback? onHistoryTap;

  /// 角色选择器回调
  final VoidCallback? onCharacterTap;

  /// 画中画按钮回调
  final VoidCallback? onPiPTap;

  /// Token 用量百分比 0.0-1.0
  final double tokenPercent;

  /// 角色名称
  final String characterName;

  /// 角色头像 URL，null 时显示首字母
  final String? characterAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: UiTokens.topBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: UiTokens.surface,
        border: Border(
          bottom: BorderSide(color: UiTokens.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          // 左侧按钮组
          _IconBtn(icon: Icons.history, onTap: onHistoryTap),
          const SizedBox(width: 2),
          _IconBtn(icon: Icons.picture_in_picture_outlined, onTap: onPiPTap),
          // 中央角色选择器
          Expanded(
            child: GestureDetector(
              onTap: onCharacterTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(),
                  _CharacterAvatar(
                    name: characterName,
                    avatarUrl: characterAvatar,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      characterName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: UiTokens.bodyFS,
                        fontWeight: FontWeight.w600,
                        color: UiTokens.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: UiTokens.onSurfaceVariant,
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          // Token 用量环
          OperitTokenRing(percent: tokenPercent, size: 36),
          const SizedBox(width: 2),
          // 百分比文字
          SizedBox(
            width: 34,
            child: Text(
              '${(tokenPercent * 100).round()}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: UiTokens.microFS,
                fontWeight: FontWeight.w600,
                color: UiTokens.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        color: UiTokens.onSurfaceVariant,
        padding: EdgeInsets.zero,
        splashRadius: 14,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _CharacterAvatar extends StatelessWidget {
  const _CharacterAvatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: UiTokens.primaryContainer,
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
      child: avatarUrl == null
          ? Text(
              name.characters.isNotEmpty ? name.characters.first : '?',
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
