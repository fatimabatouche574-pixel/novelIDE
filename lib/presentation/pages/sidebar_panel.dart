import 'package:flutter/material.dart';
import 'package:novel_ide/presentation/models/nav_item.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 抽屉式侧边栏面板 — 宽度由 Drawer 控制，自适应手机屏幕
class SidebarPanel extends StatefulWidget {
  final NavItem currentItem;
  final void Function(NavItem item) onNavigate;

  const SidebarPanel({
    super.key,
    required this.currentItem,
    required this.onNavigate,
  });

  @override
  State<SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends State<SidebarPanel> {
  @override
  Widget build(BuildContext context) {
    // 宽度由 Drawer 控制（通常为 240dp），填满抽屉即可
    return Container(
      color: UiTokens.sidebarBg,
      child: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrand(),
                const SizedBox(height: 2),
                _buildNetworkPill(),
                const SizedBox(height: 10),
                _buildQuickCards(),
                const SizedBox(height: 12),
                _buildNavGroup('写作功能区', NavItem.writeGroup),
                _buildNavGroup('AI 功能区', NavItem.aiGroup),
                _buildNavGroup('系统', NavItem.systemGroup),
              ],
            ),
          ),
        ),
        // 分隔线
        Divider(height: 0.5, color: Colors.white.withValues(alpha: 0.1)),
        // 底部快捷
        _buildBottomShortcuts(),
      ]),
    );
  }

  // ── 品牌 ──
  Widget _buildBrand() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        'NovelIDE',
        style: TextStyle(
          fontSize: UiTokens.brandFS,
          fontWeight: FontWeight.w700,
          color: UiTokens.sidebarText,
        ),
      ),
    );
  }

  // ── 网络状态药丸 ──
  Widget _buildNetworkPill() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFA6E3A1).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFFA6E3A1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '已连接',
            style: TextStyle(
              fontSize: UiTokens.microFS + 1,
              color: UiTokens.sidebarText,
            ),
          ),
        ],
      ),
    );
  }

  // ── 快速操作卡片 ──
  Widget _buildQuickCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: NavItem.quickActions.map((a) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _QuickActionCard(icon: a.icon, label: a.label, badge: a.badge),
          ),
        )).toList(),
      ),
    );
  }

  // ── 导航分组 ──
  Widget _buildNavGroup(String label, List<NavItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: label),
        ...items.map((item) => _NavItemWidget(
          item: item,
          selected: widget.currentItem == item,
          onTap: () => widget.onNavigate(item),
        )),
      ],
    );
  }

  // ── 底部快捷 ──
  Widget _buildBottomShortcuts() {
    const shortcuts = [
      (Icons.lightbulb_outline, '提示'),
      (Icons.help_outline, '帮助'),
      (Icons.settings, '设置'),
    ];
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: shortcuts.map((s) => Expanded(
          child: _BottomBtn(icon: s.$1, label: s.$2),
        )).toList(),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 子组件
// ════════════════════════════════════════════════════════════════

/// 快速操作卡片
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String badge;

  const _QuickActionCard({required this.icon, required this.label, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: UiTokens.quickCardHeight,
      decoration: BoxDecoration(
        color: UiTokens.sidebarItemBg,
        borderRadius: BorderRadius.circular(UiTokens.cardRadius),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: UiTokens.quickIconSize, color: UiTokens.sidebarText),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: UiTokens.microFS, color: UiTokens.sidebarText),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: UiTokens.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: UiTokens.tinyFS,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 分组标签
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 3),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: UiTokens.microFS,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.4),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// 导航项
class _NavItemWidget extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItemWidget({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UiTokens.cardRadius),
      child: Container(
        height: UiTokens.navItemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: selected
            ? BoxDecoration(
                color: UiTokens.sidebarActiveBg,
                borderRadius: BorderRadius.circular(UiTokens.cardRadius),
              )
            : null,
        child: Row(
          children: [
            Opacity(
              opacity: selected ? 1.0 : 0.6,
              child: Icon(
                item.icon,
                size: UiTokens.navIconSize,
                color: selected ? UiTokens.sidebarActive : UiTokens.sidebarText,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.title,
              style: TextStyle(
                fontSize: UiTokens.bodyFS,
                color: selected ? UiTokens.sidebarActive : UiTokens.sidebarText,
                fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 底部快捷按钮
class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomBtn({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Container(
        height: UiTokens.bottomBtnHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(UiTokens.cardRadius),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: UiTokens.iconSize, color: UiTokens.sidebarText.withValues(alpha: 0.5)),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: UiTokens.tinyFS + 1,
                  color: UiTokens.sidebarText.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
