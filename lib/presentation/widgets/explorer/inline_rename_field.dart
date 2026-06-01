import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';

/// 内联重命名组件
///
/// 替换节点为 TextField，自动聚焦、全选。
/// 点空白处确认，验证：文件名不为空、不重复。
class InlineRenameField extends ConsumerStatefulWidget {
  const InlineRenameField({
    super.key,
    required this.initialName,
    required this.onConfirm,
    this.onCancel,
    this.existingNames = const [],
  });
  final String initialName;
  final void Function(String newName) onConfirm;
  final VoidCallback? onCancel;

  /// 已存在的名称列表（用于重复检测）
  final List<String> existingNames;

  @override
  ConsumerState<InlineRenameField> createState() => _InlineRenameFieldState();
}

class _InlineRenameFieldState extends ConsumerState<InlineRenameField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinThemeProvider);
    return GestureDetector(
      onTap: _confirmRename,
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: TextStyle(fontSize: 13, color: skin.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            errorText: _errorText,
            errorStyle: const TextStyle(fontSize: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: skin.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: skin.primary, width: 2),
            ),
          ),
          onSubmitted: (_) => _confirmRename(),
          onTapOutside: (_) => _confirmRename(),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[\/\:*?"<>|]')),
          ],
        ),
      ),
    );
  }

  void _confirmRename() {
    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      setState(() => _errorText = '名称不能为空');
      return;
    }
    if (newName == widget.initialName) {
      widget.onCancel?.call();
      return;
    }
    final duplicate = widget.existingNames.any(
      (n) => n.toLowerCase() == newName.toLowerCase(),
    );
    if (duplicate) {
      setState(() => _errorText = '名称已存在');
      return;
    }
    HapticFeedback.lightImpact();
    widget.onConfirm(newName);
  }
}
