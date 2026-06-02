import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 思考中指示器 — 可折叠卡片
///
/// 显示 "思考中" 并带动画省略号（...）。
/// 展开后显示内部思考内容（如有）。
class OperitThinkingIndicator extends StatefulWidget {
  const OperitThinkingIndicator({
    super.key,
    this.thinkingContent,
    this.defaultExpanded = false,
  });

  /// 展开后显示的思考内容
  final String? thinkingContent;

  /// 是否默认展开
  final bool defaultExpanded;

  @override
  State<OperitThinkingIndicator> createState() =>
      _OperitThinkingIndicatorState();
}

class _OperitThinkingIndicatorState extends State<OperitThinkingIndicator>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _expanded = widget.defaultExpanded;
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasContent =
        widget.thinkingContent != null && widget.thinkingContent!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 折叠头部
        InkWell(
          onTap: hasContent
              ? () => setState(() => _expanded = !_expanded)
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: UiTokens.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.psychology_outlined,
                  size: 16,
                  color: UiTokens.primary,
                ),
                const SizedBox(width: 6),
                const Text(
                  '思考中',
                  style: TextStyle(
                    fontSize: UiTokens.bodyFS,
                    fontWeight: FontWeight.w500,
                    color: UiTokens.primary,
                  ),
                ),
                const SizedBox(width: 2),
                AnimatedBuilder(
                  animation: _dotController,
                  builder: (context, child) {
                    final dots = '.' * ((_dotController.value * 3).floor() + 1);
                    return Text(
                      dots,
                      style: const TextStyle(
                        fontSize: UiTokens.bodyFS,
                        fontWeight: FontWeight.w700,
                        color: UiTokens.primary,
                      ),
                    );
                  },
                ),
                if (hasContent) ...[
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: UiTokens.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
        // 展开的思考内容
        if (_expanded && hasContent)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: UiTokens.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: UiTokens.outlineVariant),
            ),
            child: Text(
              widget.thinkingContent!,
              style: TextStyle(
                fontSize: UiTokens.bodyFS,
                color: UiTokens.onSurfaceVariant,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
