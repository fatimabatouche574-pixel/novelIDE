import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/app_themes.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 主题外观设置页 — 皮肤/背景色/气泡样式
class OperitThemePage extends ConsumerWidget {
  const OperitThemePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSkin = ref.watch(skinThemeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('主题外观')),
      body: ListView(
        padding: EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildGroup('主题皮肤', [
            _buildSkinGrid(context, ref, currentSkin),
          ]),
          const SizedBox(height: UiTokens.sectionSpacing),
          _buildGroup('背景颜色', [
            _buildColorSwatches(context, theme),
          ]),
          const SizedBox(height: UiTokens.sectionSpacing),
          _buildGroup('气泡样式', [
            _buildBubbleSettings(context, theme),
          ]),
        ],
      ),
    );
  }

  Widget _buildGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: UiTokens.titleFS,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSkinGrid(
    BuildContext context,
    WidgetRef ref,
    SkinTheme currentSkin,
  ) {
    // 使用6个皮肤: white, black, blue, yellow, green, red
    const displaySkins = [
      AppSkins.white,
      AppSkins.black,
      AppSkins.blue,
      AppSkins.yellow,
      AppSkins.green,
      AppSkins.red,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.6,
      ),
      itemCount: displaySkins.length,
      itemBuilder: (context, index) {
        final skin = displaySkins[index];
        final isSelected = currentSkin.type == skin.type;

        return GestureDetector(
          onTap: () {
            ref.read(skinThemeProvider.notifier).setSkin(skin.type);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: skin.surface,
              borderRadius: BorderRadius.circular(UiTokens.cardRadius),
              border: Border.all(
                color: isSelected ? skin.primary : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  skin.type.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: skin.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  skin.type.desc,
                  style: TextStyle(fontSize: 11, color: skin.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorSwatches(BuildContext context, ThemeData theme) {
    const colors = [
      Colors.white,
      Colors.black,
      Color(0xFFEDF3FA),
      Color(0xFFFFF8EE),
      Color(0xFFF1F8E9),
      Color(0xFFFDE8EF),
      Color(0xFFF5F0E8),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            colors.map((color) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildBubbleSettings(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('圆角气泡', style: TextStyle(fontSize: 14)),
          subtitle: const Text('使用较大的气泡边角圆角'),
          value: true,
          onChanged: (_) {},
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        _buildColorPickerTile('AI 气泡颜色', const Color(0xFF7C4DFF)),
        _buildColorPickerTile('用户气泡颜色', const Color(0xFFE8DEF8)),
      ],
    );
  }

  Widget _buildColorPickerTile(String label, Color defaultColor) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: defaultColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
      contentPadding: EdgeInsets.zero,
      onTap: () {},
    );
  }
}
