import 'dart:developer' as developer;

import 'package:novel_ide/data/services/mcp/mcp_protocol.dart';
import 'package:novel_ide/data/services/workspace_agent.dart';

/// 将 WorkspaceAgent 现有工具系统包装为 MCP 提供者
///
/// 纯适配层，零修改现有代码。
/// 读取 WorkspaceAgent 的静态工具列表，过滤已注册执行器的工具，
/// 转换为统一的 McpTool 格式。
class BuiltinToolProvider implements McpToolProvider {
  const BuiltinToolProvider(this._agent);

  final WorkspaceAgent _agent;

  @override
  String get id => 'builtin';

  @override
  String get name => '内置工具';

  @override
  bool get isEnabled => true;

  @override
  Future<List<McpTool>> getTools() async {
    final result = <McpTool>[];
    for (final tool in WorkspaceAgent.tools) {
      // 仅暴露已注册执行器的工具
      final executor = _agent.getExecutor(tool.name);
      if (executor == null) continue;

      final openAiFormat = tool.toOpenAiFormat();
      final functionDef =
          openAiFormat['function'] as Map<String, dynamic>? ?? {};
      final params =
          functionDef['parameters'] as Map<String, dynamic>? ?? {};
      final properties =
          params['properties'] as Map<String, dynamic>? ?? {};

      result.add(McpTool(
        name: tool.name,
        description: tool.description.split('\n').first,
        providerId: id,
        parameters: properties,
        category: tool.category,
      ));
    }
    return result;
  }

  @override
  Future<McpResult> execute(
    String toolName,
    Map<String, dynamic> args,
  ) async {
    final executor = _agent.getExecutor(toolName);
    if (executor == null) {
      return McpResult.failure(
        toolName: toolName,
        message: '工具 "$toolName" 未注册执行器',
      );
    }

    try {
      final toolResult = await executor(args);
      if (toolResult.success) {
        return McpResult.success(
          toolName: toolName,
          message: toolResult.message,
          data: toolResult.data,
        );
      }
      return McpResult.failure(
        toolName: toolName,
        message: toolResult.error ?? toolResult.message,
        data: toolResult.data,
      );
    } on Exception catch (e) {
      developer.log(
        '执行工具 "$toolName" 异常: $e',
        name: 'BuiltinToolProvider',
      );
      return McpResult.failure(
        toolName: toolName,
        message: '执行异常: $e',
      );
    }
  }
}
