import 'package:flutter/material.dart';

/// 全屏角色选择器 — 底部弹出式面板，半透明背景点击关闭
class OperitCharacterSelector extends StatelessWidget {
  const OperitCharacterSelector({
    super.key,
    required this.onSelect,
  });

  final void Function(String character) onSelect;

  static const _defaultCharacters = [
    ('\u{1F916}', '通用助手'),
    ('\u{1F9D9}', '代码大师'),
    ('\u{1F4DA}', '写作顾问'),
    ('\u{1F393}', '学习伙伴'),
  ];

  /// 以 showModalBottomSheet 方式弹出
  static void show(
    BuildContext context, {
    required void Function(String character) onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OperitCharacterSelector(onSelect: onSelect),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '选择角色',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._defaultCharacters.map(
                  (c) => _CharacterTile(
                    emoji: c.$1,
                    name: c.$2,
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(c.$2);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterTile extends StatelessWidget {
  const _CharacterTile({
    required this.emoji,
    required this.name,
    required this.onTap,
  });

  final String emoji;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
