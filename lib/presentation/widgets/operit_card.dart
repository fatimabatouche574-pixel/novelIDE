import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 统计卡片 —— 图标 + 大数字 + 标签（用于统计页面）
class OperitStatCard extends StatelessWidget {
  const OperitStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? UiTokens.onPrimaryContainer;
    final lc = c.withAlpha(179);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiTokens.cardRadius),
      ),
      color: UiTokens.primaryContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: c),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: UiTokens.smallFS, color: lc),
            ),
          ],
        ),
      ),
    );
  }
}

/// 工具卡片 —— Emoji 图标 + 名称，网格项，点击跳转
class OperitToolCard extends StatelessWidget {
  const OperitToolCard({
    super.key,
    required this.icon,
    required this.name,
    this.onTap,
  });

  final String icon;
  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UiTokens.cardRadius),
      child: Container(
        height: UiTokens.toolCardHeight,
        decoration: BoxDecoration(
          color: UiTokens.surface,
          borderRadius: BorderRadius.circular(UiTokens.cardRadius),
          border: Border.all(color: UiTokens.surfaceVariant, width: 0.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 10),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 包/插件卡片 —— 图标 + 标题 + 描述 + 徽章 + 操作按钮
class OperitPkgCard extends StatelessWidget {
  const OperitPkgCard({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.badge,
    this.badgeColor,
    this.actionIcon,
    this.onActionTap,
  });

  final String icon;
  final String title;
  final String? description;
  final String? badge;
  final Color? badgeColor;
  final IconData? actionIcon;
  final VoidCallback? onActionTap;

  static const _ts = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
  static const _ss = TextStyle(fontSize: 10);
  static const _bs = TextStyle(fontSize: 9, fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    final bc = badgeColor ?? UiTokens.tertiary;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiTokens.cardRadius),
      ),
      color: UiTokens.surface,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: UiTokens.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(title, style: _ts)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
                          decoration: BoxDecoration(
                            color: bc.withAlpha(38),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(badge!, style: _bs.copyWith(color: bc)),
                        ),
                      ],
                    ],
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: _ss,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (actionIcon != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onActionTap,
                icon: Icon(actionIcon, size: 20),
                color: UiTokens.primary,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
