import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// Operit 风格的自定义 Tab 栏
///
/// 水平可滚动的标签按钮行。
/// 选中的标签底部有主题色强调线（primary，2px），未选中的标签使用灰色文字。
class OperitTabBar extends StatelessWidget {
  const OperitTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  /// 标签名称列表
  final List<String> tabs;

  /// 当前选中的索引
  final int selectedIndex;

  /// 标签切换回调
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: UiTokens.surface,
        border: Border(
          bottom: BorderSide(
            color: UiTokens.outlineVariant.withValues(alpha: 0.4),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(index),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: UiTokens.bodyFS,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? UiTokens.primary
                            : UiTokens.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(height: 2, color: UiTokens.primary),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
