import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 可复用的设置分组容器
///
/// 渲染带有可选标题头的 Card，使用 [UiTokens.groupRadius] 圆角、
/// [UiTokens.surfaceVariant] 边框、白色背景。
class OperitSettingsGroup extends StatelessWidget {
  const OperitSettingsGroup({super.key, this.title, required this.children});

  /// 可选的标题文本，显示在卡片顶部
  final String? title;

  /// 设置项列表
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: UiTokens.pagePadH,
        vertical: 4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiTokens.groupRadius),
        side: BorderSide(color: UiTokens.surfaceVariant, width: 0.5),
      ),
      color: UiTokens.surface,
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [if (title != null) _buildHeader(context), ...children],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        title!,
        style: TextStyle(
          fontSize: UiTokens.titleFS,
          fontWeight: FontWeight.w600,
          color: UiTokens.onSurface,
        ),
      ),
    );
  }
}
