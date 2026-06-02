import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// Operit 风格的自定义开关组件
///
/// Material You 风格：开启时紫色（primary），关闭时灰色。
/// 宽度 ~44px，高度 ~24px，带动画过渡。
class OperitToggleSwitch extends StatelessWidget {
  const OperitToggleSwitch({super.key, required this.value, this.onChanged});

  /// 当前开关状态
  final bool value;

  /// 状态变化回调
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value ? UiTokens.primary : UiTokens.outlineVariant,
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
