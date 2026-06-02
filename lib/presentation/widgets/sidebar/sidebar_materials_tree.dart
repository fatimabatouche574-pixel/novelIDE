import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';
import 'package:novel_ide/presentation/state/app_providers.dart';

/// 侧边栏资料库可折叠树
///
/// 展示 7 个资料分类及条目数，点击回调通知父组件导航。
class SidebarMaterialsTree extends ConsumerStatefulWidget {
  const SidebarMaterialsTree({
    super.key,
    required this.textColor,
    required this.activeColor,
    required this.bg,
    required this.currentRoute,
    required this.onCategoryTap,
  });

  final Color textColor;
  final Color activeColor;
  final Color bg;
  final String currentRoute;
  final void Function(String categoryType) onCategoryTap;

  @override
  ConsumerState<SidebarMaterialsTree> createState() =>
      _SidebarMaterialsTreeState();
}

class _SidebarMaterialsTreeState extends ConsumerState<SidebarMaterialsTree> {
  bool _expanded = true;

  // categoryType -> (emoji + label, icon)
  static const _categories = <_CategoryDef>[
    _CategoryDef('character', '\u{1F464} 角色', Icons.person),
    _CategoryDef('setting', '⚙️ 设定', Icons.settings),
    _CategoryDef('location', '\u{1F4CD} 地点', Icons.location_on),
    _CategoryDef('faction', '\u{1F3F0} 势力', Icons.account_balance),
    _CategoryDef('hook', '\u{1F517} 伏笔', Icons.lightbulb_outline),
    _CategoryDef('item', '\u{1F4E6} 道具', Icons.inventory_2),
    _CategoryDef('reference', '\u{1F4DA} 参考', Icons.book),
  ];

  @override
  Widget build(BuildContext context) {
    final novel = ref.watch(selectedNovelProvider);
    final isMaterials = widget.currentRoute == 'materials';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(UiTokens.cardRadius),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
            child: Row(
              children: [
                Text(
                  '资料库',
                  style: TextStyle(
                    fontSize: UiTokens.microFS + 1,
                    fontWeight: FontWeight.w600,
                    color: isMaterials
                        ? widget.activeColor
                        : widget.textColor.withValues(alpha: 0.55),
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: widget.textColor.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Category items
        if (_expanded)
          if (novel == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                '请先选择作品',
                style: TextStyle(
                  fontSize: UiTokens.smallFS,
                  color: widget.textColor.withValues(alpha: 0.35),
                ),
              ),
            )
          else
            ..._categories.map((cat) => _buildCategoryTile(cat, novel.id)),
      ],
    );
  }

  Widget _buildCategoryTile(_CategoryDef cat, String novelId) {
    final count = _getCount(cat.type, novelId);

    return InkWell(
      onTap: () => widget.onCategoryTap(cat.type),
      borderRadius: BorderRadius.circular(UiTokens.cardRadius),
      child: Container(
        height: UiTokens.navItemHeight - 4,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Row(
          children: [
            Text(
              cat.emoji,
              style: const TextStyle(fontSize: UiTokens.iconSize - 1),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cat.label,
                style: TextStyle(
                  fontSize: UiTokens.bodyFS - 1,
                  color: widget.textColor,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: UiTokens.microFS + 1,
                color: widget.textColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCount(String type, String novelId) {
    switch (type) {
      case 'character':
        return ref.watch(charactersProvider(novelId)).length;
      case 'setting':
        return ref.watch(settingCardsProvider(novelId)).length;
      case 'location':
        return ref.watch(locationsProvider(novelId)).length;
      case 'faction':
        return ref.watch(factionsProvider(novelId)).length;
      case 'hook':
        return ref.watch(plotHooksProvider(novelId)).length;
      case 'item':
        return ref.watch(itemsProvider(novelId)).length;
      case 'reference':
        return ref.watch(referencesProvider(novelId)).length;
      default:
        return 0;
    }
  }
}

// ── Private model ──────────────────────────────────────────

class _CategoryDef {
  const _CategoryDef(this.type, this.emoji, this.icon);

  final String type;
  final String emoji;
  final IconData icon;
}
