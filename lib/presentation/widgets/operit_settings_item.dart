import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 可复用的设置列表项 —— 使用频率最高的组件
///
/// 支持 4 种变体，通过 [trailing] 自动检测：
/// - Arrow: 箭头 → 跳转子页面
/// - Toggle: 开关 → 开/关设置
/// - Value: 文本 → 当前值展示（如 "中文", "100%"）
/// - None: 无尾部 → 仅展示
class OperitSettingsItem extends StatelessWidget {
  const OperitSettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  /// Emoji 字符串图标
  final String icon;

  /// 标题文本
  final String title;

  /// 可选的副标题文本
  final String? subtitle;

  /// 尾部组件：箭头图标、ToggleSwitch 或文本值
  final Widget? trailing;

  /// 点击回调（用于导航变体）
  final VoidCallback? onTap;

  /// 是否显示底部分隔线
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isArrow =
        trailing is Icon && (trailing as Icon).icon == Icons.chevron_right;
    final showTrailing = trailing != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isArrow ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildIconContainer(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: UiTokens.bodyFS,
                          fontWeight: FontWeight.w500,
                          color: UiTokens.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: UiTokens.smallFS,
                            color: UiTokens.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showTrailing) ...[const SizedBox(width: 8), trailing!],
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 0.5,
            indent: 16 + 32 + 14,
            color: UiTokens.outlineVariant.withValues(alpha: 0.4),
          ),
      ],
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: UiTokens.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(icon, style: const TextStyle(fontSize: 16)),
    );
  }
}
