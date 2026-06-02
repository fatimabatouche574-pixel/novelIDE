import 'package:flutter/material.dart';

/// 附件弹出面板 — 4列图标网格，拖拽指示条
class OperitAttachmentPopup extends StatelessWidget {
  const OperitAttachmentPopup({
    super.key,
    required this.onSelect,
  });

  final void Function(String attachmentType) onSelect;

  static const _items = [
    ('\u{1F4F7}', '照片'),
    ('\u{1F4F8}', '相机'),
    ('\u{1F9E0}', '记忆'),
    ('\u{1F4C1}', '文件'),
    ('\u{1F5A5}\u{FE0F}', '屏幕'),
    ('\u{1F514}', '通知'),
    ('\u{1F4CD}', '位置'),
    ('\u{2728}', '包'),
  ];

  /// 以底部弹出面板方式显示
  static void show(
    BuildContext context, {
    required void Function(String attachmentType) onSelect,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => OperitAttachmentPopup(onSelect: onSelect),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
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
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return _GridItem(
                icon: item.$1,
                label: item.$2,
                onTap: () {
                  Navigator.pop(context);
                  onSelect(item.$2);
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  const _GridItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
