import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';
import 'package:novel_ide/presentation/widgets/chat/operit_chat_models.dart';

/// 工具调用卡片组件
///
/// 当 AI 进行工具调用时内联显示。
/// 包含工具图标、名称、参数摘要及折叠的详细信息区域。
class OperitToolCard extends StatefulWidget {
  const OperitToolCard({
    super.key,
    required this.toolName,
    this.toolParams,
    this.toolResult,
    this.status = OperitToolStatus.running,
    this.onTap,
    this.defaultExpanded = false,
  });

  /// 工具名称，如 "read_file"、"web_search"
  final String toolName;

  /// 工具参数字符串
  final String? toolParams;

  /// 工具返回结果字符串
  final String? toolResult;

  /// 工具执行状态
  final OperitToolStatus status;

  /// 点击卡片回调
  final VoidCallback? onTap;

  /// 是否默认展开详情
  final bool defaultExpanded;

  @override
  State<OperitToolCard> createState() => _OperitToolCardState();
}

class _OperitToolCardState extends State<OperitToolCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.defaultExpanded;
  }

  IconData _iconForTool(String name) {
    switch (name) {
      case 'read_file':
        return Icons.description_outlined;
      case 'write_file':
        return Icons.edit_note;
      case 'search':
      case 'web_search':
        return Icons.search;
      case 'execute':
      case 'run_command':
        return Icons.terminal;
      case 'browser':
        return Icons.language;
      default:
        return Icons.build_outlined;
    }
  }

  String _summaryForTool(String name) {
    switch (name) {
      case 'read_file':
        return '读取文件';
      case 'write_file':
        return '写入文件';
      case 'search':
      case 'web_search':
        return '搜索';
      case 'execute':
      case 'run_command':
        return '执行命令';
      case 'browser':
        return '浏览器操作';
      default:
        return name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: UiTokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: UiTokens.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 折叠头部
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: 8),
                  Icon(
                    _iconForTool(widget.toolName),
                    size: 16,
                    color: UiTokens.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _summaryForTool(widget.toolName),
                      style: const TextStyle(
                        fontSize: UiTokens.smallFS,
                        fontWeight: FontWeight.w500,
                        color: UiTokens.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 参数摘要
                  if (widget.toolParams != null)
                    Flexible(
                      child: Text(
                        widget.toolParams!,
                        style: TextStyle(
                          fontSize: UiTokens.microFS,
                          color: UiTokens.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: UiTokens.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          // 展开详情
          if (_expanded) ...[
            const Divider(height: 1, color: UiTokens.outlineVariant),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.toolParams != null) ...[
                    const Text(
                      '参数',
                      style: TextStyle(
                        fontSize: UiTokens.smallFS,
                        fontWeight: FontWeight.w600,
                        color: UiTokens.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: UiTokens.surfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.toolParams!,
                        style: const TextStyle(
                          fontSize: UiTokens.smallFS,
                          fontFamily: 'monospace',
                          color: UiTokens.onSurface,
                        ),
                      ),
                    ),
                  ],
                  if (widget.toolResult != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '结果',
                      style: TextStyle(
                        fontSize: UiTokens.smallFS,
                        fontWeight: FontWeight.w600,
                        color: UiTokens.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: UiTokens.surfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.toolResult!,
                        style: const TextStyle(
                          fontSize: UiTokens.smallFS,
                          fontFamily: 'monospace',
                          color: UiTokens.onSurface,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    return switch (widget.status) {
      OperitToolStatus.running => const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(UiTokens.primary),
        ),
      ),
      OperitToolStatus.success => const Icon(
        Icons.check_circle,
        size: 14,
        color: UiTokens.greenSuccess,
      ),
      OperitToolStatus.error => const Icon(
        Icons.cancel,
        size: 14,
        color: UiTokens.error,
      ),
    };
  }
}
