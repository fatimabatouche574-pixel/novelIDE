import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:novel_ide/data/services/mcp/mcp_protocol.dart';

/// JSON 插件中的单个工具条目
class _PluginTool {
  const _PluginTool({
    required this.name,
    required this.description,
    required this.type,
    this.parameters = const {},
    this.url,
  });
  final String name;
  final String description;
  final String type; // 'local' 或 'http'
  final Map<String, dynamic> parameters;
  final String? url;
}

/// JSON 插件定义（一个文件可包含多个工具）
class _JsonPlugin {
  const _JsonPlugin({
    required this.name,
    required this.version,
    required this.tools,
  });
  final String name;
  final String version;
  final List<_PluginTool> tools;
}

/// 从文件系统加载 JSON 插件的 MCP 提供者
///
/// 扫描指定目录下的所有 .json 文件，每个文件定义一个或多个工具。
/// 支持 'local'（委托内置执行器）和 'http'（HTTP POST）两种执行类型。
class JsonPluginProvider implements McpToolProvider {
  JsonPluginProvider({
    required this.directory,
    required this.onExecuteBuiltin,
  });

  final String directory;
  final Future<McpResult> Function(
    String toolName,
    Map<String, dynamic> args,
  ) onExecuteBuiltin;

  final List<_JsonPlugin> _plugins = [];

  @override
  String get id => 'json_plugin';
  @override
  String get name => 'JSON 插件';
  @override
  bool get isEnabled => true;

  int get pluginCount => _plugins.length;

  /// 扫描目录并加载所有 .json 插件文件
  Future<void> loadPlugins() async {
    _plugins.clear();
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      developer.log('插件目录不存在: $directory', name: 'JsonPluginProvider');
      return;
    }
    final files = dir.listSync().whereType<File>()
        .where((f) => f.path.endsWith('.json'));
    for (final file in files) {
      try {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final plugin = _parsePlugin(json);
        if (plugin != null) {
          _plugins.add(plugin);
          developer.log(
            '已加载插件: ${plugin.name} (${plugin.tools.length} 个工具)',
            name: 'JsonPluginProvider',
          );
        }
      } on FormatException catch (e) {
        developer.log('JSON 解析失败: ${file.path} - $e',
            name: 'JsonPluginProvider');
      } on FileSystemException catch (e) {
        developer.log('文件读取失败: ${file.path} - $e',
            name: 'JsonPluginProvider');
      }
    }
  }

  _JsonPlugin? _parsePlugin(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final toolsJson = json['tools'] as List<dynamic>?;
    if (name == null || toolsJson == null || toolsJson.isEmpty) {
      developer.log('插件格式无效: 缺少 name 或 tools 字段',
          name: 'JsonPluginProvider');
      return null;
    }

    final tools = <_PluginTool>[];
    for (final item in toolsJson) {
      if (item is! Map<String, dynamic>) continue;
      final toolName = item['name'] as String?;
      if (toolName == null) {
        developer.log('跳过无名工具定义 (插件: $name)',
            name: 'JsonPluginProvider');
        continue;
      }
      tools.add(_PluginTool(
        name: toolName,
        description: item['description'] as String? ?? '',
        type: item['type'] as String? ?? 'local',
        parameters: _extractParameters(
          item['parameters'] as Map<String, dynamic>?,
        ),
        url: item['url'] as String?,
      ));
    }
    if (tools.isEmpty) return null;
    return _JsonPlugin(
      name: name,
      version: json['version'] as String? ?? '0.0',
      tools: tools,
    );
  }

  Map<String, dynamic> _extractParameters(Map<String, dynamic>? schema) {
    if (schema == null) return const {};
    return schema['properties'] as Map<String, dynamic>? ?? const {};
  }

  @override
  Future<List<McpTool>> getTools() async => [
        for (final plugin in _plugins)
          for (final tool in plugin.tools)
            McpTool(
              name: tool.name,
              description: tool.description,
              providerId: id,
              parameters: tool.parameters,
            ),
      ];

  @override
  Future<void> dispose() async {
    _plugins.clear();
  }

  @override
  Future<McpResult> execute(
    String toolName,
    Map<String, dynamic> args,
  ) async {
    final tool = _findTool(toolName);
    if (tool == null) {
      return McpResult.failure(
        toolName: toolName, message: 'JSON 插件中未找到工具: $toolName',
      );
    }
    try {
      return switch (tool.type) {
        'local' => await onExecuteBuiltin(toolName, args),
        'http' => await _executeHttp(tool, args),
        _ => McpResult.failure(
            toolName: toolName, message: '不支持的执行类型: ${tool.type}',
          ),
      };
    } on Exception catch (e) {
      developer.log('执行插件工具 "$toolName" 异常: $e',
          name: 'JsonPluginProvider');
      return McpResult.failure(
        toolName: toolName, message: '执行异常: $e',
      );
    }
  }

  _PluginTool? _findTool(String toolName) {
    for (final plugin in _plugins) {
      for (final tool in plugin.tools) {
        if (tool.name == toolName) return tool;
      }
    }
    return null;
  }

  /// 通过 HTTP POST 调用远程工具
  Future<McpResult> _executeHttp(
    _PluginTool tool,
    Map<String, dynamic> args,
  ) async {
    final url = tool.url;
    if (url == null || url.isEmpty) {
      return McpResult.failure(
        toolName: tool.name, message: 'HTTP 工具缺少 url 配置',
      );
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return McpResult.failure(
        toolName: tool.name, message: 'HTTP url 格式无效: $url',
      );
    }

    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(args));
      final response =
          await request.close().timeout(const Duration(seconds: 30));
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != HttpStatus.ok) {
        return McpResult.failure(
          toolName: tool.name,
          message: 'HTTP ${response.statusCode}: $body',
        );
      }
      return _parseHttpResponse(tool.name, body);
    } on SocketException catch (e) {
      return McpResult.failure(
        toolName: tool.name, message: '网络连接失败: ${e.message}',
      );
    } on HttpException catch (e) {
      return McpResult.failure(
        toolName: tool.name, message: 'HTTP 异常: ${e.message}',
      );
    } on TimeoutException {
      return McpResult.failure(
        toolName: tool.name, message: 'HTTP 请求超时 (30s)',
      );
    } finally {
      client.close();
    }
  }

  McpResult _parseHttpResponse(String toolName, String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map<String, dynamic>) {
        return McpResult.success(
          toolName: toolName,
          message: json['message'] as String? ?? '执行成功',
          data: json['data'] as Map<String, dynamic>?,
        );
      }
    } on FormatException {
      // 非 JSON 响应，作为纯文本返回
    }
    return McpResult.success(toolName: toolName, message: body);
  }
}
