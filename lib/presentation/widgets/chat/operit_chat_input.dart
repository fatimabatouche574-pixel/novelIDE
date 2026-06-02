import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// Operit Agent 风格输入区域
///
/// 包含多行文本输入框、模型选择器、设置按钮、附件按钮和发送按钮。
/// 发送按钮仅在文本非空时启用。
class OperitChatInput extends StatefulWidget {
  const OperitChatInput({
    super.key,
    required this.onSend,
    this.onModelTap,
    this.onSettingsTap,
    this.onAttachTap,
    this.modelName = 'GPT-4o',
    this.hintText = '输入消息...',
  });

  /// 发送回调，传递输入文本
  final ValueChanged<String> onSend;

  /// 模型选择器点击回调
  final VoidCallback? onModelTap;

  /// 设置按钮点击回调
  final VoidCallback? onSettingsTap;

  /// 附件按钮点击回调
  final VoidCallback? onAttachTap;

  /// 当前模型名称，默认 "GPT-4o"
  final String modelName;

  /// 输入框占位文本
  final String hintText;

  @override
  State<OperitChatInput> createState() => _OperitChatInputState();
}

class _OperitChatInputState extends State<OperitChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    if ((text.isNotEmpty) != _hasText) {
      setState(() => _hasText = text.isNotEmpty);
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: UiTokens.surface,
        border: Border(
          top: BorderSide(color: UiTokens.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 输入框卡片
          Container(
            decoration: BoxDecoration(
              color: UiTokens.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: UiTokens.outlineVariant),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(
                fontSize: UiTokens.bodyFS,
                color: UiTokens.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: UiTokens.bodyFS,
                  color: UiTokens.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 底部工具栏
          Row(
            children: [
              // 模型选择器胶囊
              _ModelPill(modelName: widget.modelName, onTap: widget.onModelTap),
              const Spacer(),
              // 设置按钮
              _ToolBtn(
                icon: Icons.settings_outlined,
                onTap: widget.onSettingsTap,
              ),
              const SizedBox(width: 4),
              // 附件按钮
              _ToolBtn(icon: Icons.add, onTap: widget.onAttachTap),
              const SizedBox(width: 8),
              // 发送按钮
              _SendBtn(hasText: _hasText, onSend: _handleSend),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelPill extends StatelessWidget {
  const _ModelPill({required this.modelName, this.onTap});

  final String modelName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: UiTokens.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              modelName,
              style: const TextStyle(
                fontSize: UiTokens.smallFS,
                fontWeight: FontWeight.w600,
                color: UiTokens.primary,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: UiTokens.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  const _ToolBtn({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        color: UiTokens.onSurfaceVariant,
        padding: EdgeInsets.zero,
        splashRadius: 16,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _SendBtn extends StatelessWidget {
  const _SendBtn({required this.hasText, required this.onSend});

  final bool hasText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: FloatingActionButton(
        onPressed: hasText ? onSend : null,
        elevation: 0,
        backgroundColor: hasText ? UiTokens.primary : UiTokens.surfaceVariant,
        shape: const CircleBorder(),
        child: const Icon(Icons.arrow_upward, size: 20, color: Colors.white),
      ),
    );
  }
}
