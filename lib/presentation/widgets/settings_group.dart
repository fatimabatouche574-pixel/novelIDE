import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 分组卡片容器 — 标题行 + 子项列表
///
/// 使用 [UiTokens.surface] 背景、[UiTokens.groupRadius] 圆角、
/// [UiTokens.outlineVariant] 边框，底部 8px 外间距。
class SettingsGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const SettingsGroup({
    super.key,
    required this.label,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: UiTokens.surface,
          borderRadius: BorderRadius.circular(UiTokens.groupRadius),
          border: Border.all(color: UiTokens.outlineVariant),
        ),
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(3, 2, 2, 2),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: UiTokens.primary,
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// 单个设置项 — 图标 + 标题 + 副标题 + 右箭头
///
/// 图标使用 [UiTokens.iconSize] (14) / [UiTokens.primary]，
/// 标题使用 [UiTokens.bodyFS] (12) / w500，
/// 副标题 9.5sp / [UiTokens.onSurfaceVariant]。
/// hover 时背景为 black.withOpacity(0.03)。
class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.black.withOpacity(0.03),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Center(
                child: Icon(
                  icon,
                  size: UiTokens.iconSize,
                  color: UiTokens.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: UiTokens.bodyFS,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: UiTokens.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Opacity(
              opacity: 0.4,
              child: Icon(Icons.chevron_right, size: 12),
            ),
          ],
        ),
      ),
    );
  }
}
