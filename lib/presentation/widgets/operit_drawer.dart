import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 可复用的抽屉包装器
///
/// 使用 Operit 暗色主题样式包装侧边栏面板：
/// - 暗色背景 (#1E1E2E → [UiTokens.sidebarBg])
/// - 浅色文字 (#CDD6F4 → [UiTokens.sidebarText])
/// - 宽度 280px（来自 [UiTokens.drawerW]）
class OperitDrawer extends StatelessWidget {
  const OperitDrawer({super.key, required this.child, this.width});

  /// 抽屉内的子组件（通常为 SidebarPanel 或类似组件）
  final Widget child;

  /// 抽屉宽度，默认使用 [UiTokens.drawerW]（280px）
  final double? width;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? UiTokens.drawerW;

    return Container(
      width: effectiveWidth,
      color: UiTokens.sidebarBg,
      child: SafeArea(child: child),
    );
  }
}
