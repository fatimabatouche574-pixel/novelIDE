import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/presentation/models/nav_item.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/core/theme/app_themes.dart';
import 'package:novel_ide/presentation/widgets/sidebar/sidebar_work_tree.dart';
import 'package:novel_ide/presentation/widgets/sidebar/sidebar_materials_tree.dart';

/// Operit 风格抽屉侧边栏
///
/// 结构：
/// - 品牌标题 "NovelIDE"
/// - 网络状态药丸
/// - 3 个快捷操作卡片
/// - AI功能区 分组导航
/// - 作品树（可折叠）
/// - 资料库（可折叠）
/// - 底部快捷（导入/导出/设置）
class SidebarPanel extends ConsumerWidget {
  const SidebarPanel({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    this.onChapterTap,
    this.onCreateNovel,
    this.onMaterialCategoryTap,
    this.onImport,
    this.onExport,
  });

  /// 当前路由
  final String currentRoute;

  /// 导航回调
  final void Function(NavItem item) onNavigate;

  /// 作品树 - 章节点击回调
  final void Function(String chapterId, String chapterTitle)? onChapterTap;

  /// 作品树 - 创建作品回调
  final VoidCallback? onCreateNovel;

  /// 资料库 - 分类点击回调
  final void Function(String categoryType)? onMaterialCategoryTap;

  /// 导入回调
  final VoidCallback? onImport;

  /// 导出回调
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinThemeProvider);

    // 当前是暗色皮肤时，侧边栏使用暗色方案
    final isDarkDrawer =
        skin.type == SkinType.operitPurple ||
        skin.brightness == Brightness.dark;

    final bg = isDarkDrawer ? UiTokens.sidebarBg : skin.surface;
    final textColor = isDarkDrawer ? UiTokens.sidebarText : skin.textPrimary;
    final activeColor = isDarkDrawer ? UiTokens.sidebarActive : skin.primary;

    return Container(
      color: bg,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BrandHeader(textColor: textColor),
                  const SizedBox(height: 2),
                  _NetworkPill(textColor: textColor),
                  const SizedBox(height: 10),
                  _QuickActionRow(
                    textColor: textColor,
                    bg: bg,
                    onNavigate: onNavigate,
                  ),
                  const SizedBox(height: 12),
                  _NavGroupSection(
                    label: 'AI 功能区',
                    items: NavItem.aiGroup,
                    currentRoute: currentRoute,
                    onNavigate: onNavigate,
                    textColor: textColor,
                    activeColor: activeColor,
                    bg: bg,
                  ),
                  const SizedBox(height: 8),
                  _DividerLine(textColor: textColor),
                  // 作品树
                  SidebarWorkTree(
                    textColor: textColor,
                    activeColor: activeColor,
                    bg: bg,
                    onChapterTap: onChapterTap ?? (id, title) {},
                    onCreateNovel: onCreateNovel ?? () {},
                  ),
                  _DividerLine(textColor: textColor),
                  // 资料库
                  SidebarMaterialsTree(
                    textColor: textColor,
                    activeColor: activeColor,
                    bg: bg,
                    currentRoute: currentRoute,
                    onCategoryTap: onMaterialCategoryTap ?? (_) {},
                  ),
                ],
              ),
            ),
          ),
          _DividerLine(textColor: textColor),
          _BottomShortcutRow(
            shortcuts: NavItem.bottomShortcuts,
            textColor: textColor,
            onNavigate: onNavigate,
            onImport: onImport,
            onExport: onExport,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 品牌标题
// ════════════════════════════════════════════════════════════════

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        'NovelIDE',
        style: TextStyle(
          fontSize: UiTokens.brandFS,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 网络状态药丸
// ════════════════════════════════════════════════════════════════

class _NetworkPill extends StatelessWidget {
  const _NetworkPill({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
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
            style: TextStyle(fontSize: UiTokens.microFS + 1, color: textColor),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 快捷操作卡片行
// ════════════════════════════════════════════════════════════════

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.textColor,
    required this.bg,
    required this.onNavigate,
  });

  final Color textColor;
  final Color bg;
  final void Function(NavItem item) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: NavItem.quickActions
            .map(
              (a) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _QuickActionCard(
                    icon: a.icon,
                    label: a.label,
                    badge: a.badge,
                    textColor: textColor,
                    bg: bg,
                    onTap: () => onNavigate(a.toNavItem()),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.badge,
    required this.textColor,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String badge;
  final Color textColor;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  Icon(icon, size: UiTokens.quickIconSize, color: textColor),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: UiTokens.microFS,
                      color: textColor,
                    ),
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
                  style: const TextStyle(
                    fontSize: 7,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 导航分组
// ════════════════════════════════════════════════════════════════

class _NavGroupSection extends StatelessWidget {
  const _NavGroupSection({
    required this.label,
    required this.items,
    required this.currentRoute,
    required this.onNavigate,
    required this.textColor,
    required this.activeColor,
    required this.bg,
  });

  final String label;
  final List<NavItem> items;
  final String currentRoute;
  final void Function(NavItem item) onNavigate;
  final Color textColor;
  final Color activeColor;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: label, textColor: textColor),
        ...items.map(
          (item) => _NavItemTile(
            item: item,
            selected: currentRoute == item.route,
            onTap: () => onNavigate(item),
            textColor: textColor,
            activeColor: activeColor,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.textColor});

  final String label;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 3),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: UiTokens.microFS,
          fontWeight: FontWeight.w600,
          color: textColor.withValues(alpha: 0.4),
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// 导航项 - 选中时有紫色左边框 + 高亮背景
class _NavItemTile extends StatelessWidget {
  const _NavItemTile({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.textColor,
    required this.activeColor,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final Color textColor;
  final Color activeColor;

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
                border: Border(left: BorderSide(color: activeColor, width: 3)),
              )
            : null,
        child: Row(
          children: [
            Opacity(
              opacity: selected ? 1.0 : 0.6,
              child: Icon(
                item.icon,
                size: UiTokens.navIconSize,
                color: selected ? activeColor : textColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.label,
              style: TextStyle(
                fontSize: UiTokens.bodyFS,
                color: selected ? activeColor : textColor,
                fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 底部快捷
// ════════════════════════════════════════════════════════════════

class _BottomShortcutRow extends StatelessWidget {
  const _BottomShortcutRow({
    required this.shortcuts,
    required this.textColor,
    required this.onNavigate,
    this.onImport,
    this.onExport,
  });

  final List<_BottomShortcut> shortcuts;
  final Color textColor;
  final void Function(NavItem item) onNavigate;
  final VoidCallback? onImport;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: shortcuts
            .map(
              (s) => Expanded(
                child: _BottomBtn(
                  icon: s.icon,
                  label: s.label,
                  textColor: textColor,
                  onTap: () {
                    // 优先使用专用回调
                    if (s.route == 'import' && onImport != null) {
                      onImport!();
                    } else if (s.route == 'export' && onExport != null) {
                      onExport!();
                    } else {
                      onNavigate(s.toNavItem());
                    }
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  const _BottomBtn({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          height: UiTokens.bottomBtnHeight,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: UiTokens.iconSize,
                  color: textColor.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: UiTokens.tinyFS + 1,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 分隔线
// ════════════════════════════════════════════════════════════════

class _DividerLine extends StatelessWidget {
  const _DividerLine({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Divider(height: 0.5, color: textColor.withValues(alpha: 0.1));
  }
}

