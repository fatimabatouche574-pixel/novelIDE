/// 聊天组件共享数据模型
///
/// [OperitToolStatus] 和 [OperitToolCall] 跨多个聊天组件使用。

/// 工具调用状态枚举
enum OperitToolStatus {
  /// 执行中
  running,

  /// 成功
  success,

  /// 错误
  error,
}

/// 工具调用数据模型
///
/// 用于在 [OperitAiBubble] 中传递工具调用信息。
class OperitToolCall {
  const OperitToolCall({
    required this.toolName,
    this.toolParams,
    this.toolResult,
    this.status = OperitToolStatus.running,
  });

  final String toolName;
  final String? toolParams;
  final String? toolResult;
  final OperitToolStatus status;
}
