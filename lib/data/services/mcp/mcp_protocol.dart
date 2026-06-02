/// MCP (Model Context Protocol) 工具抽象层
///
/// 定义工具提供者的统一接口，支持多种工具来源：
/// - 内置工具（WorkspaceAgent）
/// - JSON 插件（文件系统加载）
/// - HTTP 远程工具（未来扩展）

/// MCP 工具定义
class McpTool {
  const McpTool({
    required this.name,
    required this.description,
    required this.providerId,
    this.parameters = const {},
    this.category = 'general',
  });

  /// 工具名称（全局唯一标识）
  final String name;

  /// 工具描述
  final String description;

  /// 所属提供者 ID
  final String providerId;

  /// 参数 schema（JSON Schema 格式的 properties）
  final Map<String, dynamic> parameters;

  /// 工具分类
  final String category;

  /// 转换为 OpenAI function calling 格式
  Map<String, dynamic> toOpenAiFormat() {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': parameters,
          if (parameters.isNotEmpty)
            'required': parameters.keys
                .where((k) => parameters[k]?['required'] == true)
                .toList(),
        },
      },
    };
  }
}

/// MCP 工具执行结果
class McpResult {
  const McpResult({
    required this.toolName,
    required this.success,
    required this.message,
    this.data,
  });

  /// 创建成功结果
  const McpResult.success({
    required this.toolName,
    required this.message,
    this.data,
  }) : success = true;

  /// 创建失败结果
  const McpResult.failure({
    required this.toolName,
    required this.message,
    this.data,
  }) : success = false;

  final String toolName;
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
}

/// MCP 工具提供者抽象接口
///
/// 每个提供者负责一类工具的管理和执行。
/// 多个提供者可共存，由 McpRegistry 统一调度。
abstract interface class McpToolProvider {
  /// 提供者唯一标识
  String get id;

  /// 提供者显示名称
  String get name;

  /// 是否启用
  bool get isEnabled;

  /// 获取该提供者管理的所有工具
  Future<List<McpTool>> getTools();

  /// 执行指定工具
  Future<McpResult> execute(String toolName, Map<String, dynamic> args);

  /// 释放资源
  Future<void> dispose() async {}
}

/// MCP 中央注册中心
///
/// 管理所有 McpToolProvider，合并工具列表，
/// 按注册顺序查找并执行工具。
class McpRegistry {
  final Map<String, McpToolProvider> _providers = {};

  /// 已缓存的工具列表
  List<McpTool>? _cachedTools;

  /// 注册一个工具提供者
  void register(McpToolProvider provider) {
    _providers[provider.id] = provider;
    _cachedTools = null; // 使缓存失效
  }

  /// 注销一个工具提供者
  void unregister(String providerId) {
    _providers.remove(providerId);
    _cachedTools = null;
  }

  /// 获取所有已注册的提供者
  List<McpToolProvider> get providers =>
      List.unmodifiable(_providers.values);

  /// 获取所有工具（带缓存）
  Future<List<McpTool>> getAllTools() async {
    if (_cachedTools != null) return _cachedTools!;
    final allTools = <McpTool>[];
    for (final provider in _providers.values) {
      if (!provider.isEnabled) continue;
      try {
        final tools = await provider.getTools();
        allTools.addAll(tools);
      } catch (_) {
        // 单个 provider 失败不影响其他
      }
    }
    _cachedTools = allTools;
    return allTools;
  }

  /// 强制刷新工具缓存
  void invalidateCache() {
    _cachedTools = null;
  }

  /// 执行工具 — 按注册顺序查找第一个匹配的提供者
  Future<McpResult> execute(
    String toolName,
    Map<String, dynamic> args,
  ) async {
    for (final provider in _providers.values) {
      if (!provider.isEnabled) continue;
      try {
        final tools = await provider.getTools();
        final match = tools.where((t) => t.name == toolName).firstOrNull;
        if (match != null) {
          return provider.execute(toolName, args);
        }
      } catch (_) {
        continue;
      }
    }
    return McpResult.failure(
      toolName: toolName,
      message: 'MCP 工具 $toolName 未在任何提供者中找到',
    );
  }

  /// 释放所有提供者
  Future<void> disposeAll() async {
    for (final provider in _providers.values) {
      await provider.dispose();
    }
    _providers.clear();
    _cachedTools = null;
  }
}
