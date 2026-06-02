import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:novel_ide/data/services/mcp/mcp_protocol.dart';

/// Connects to a remote MCP Server via HTTP
/// Supports JSON-RPC 2.0 protocol for tools/list and tools/call
class RemoteMcpProvider implements McpToolProvider {
  RemoteMcpProvider({
    required this.serverId,
    required this.serverName,
    required this.serverUrl,
    this.headers = const {},
    Duration? timeout,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: serverUrl,
           connectTimeout: timeout ?? const Duration(seconds: 10),
           receiveTimeout: timeout ?? const Duration(seconds: 30),
           headers: headers,
         ),
       );

  final String serverId;
  final String serverName;
  final String serverUrl;
  final Map<String, String> headers;
  final Dio _dio;

  @override
  String get id => serverId;

  @override
  String get name => serverName;

  @override
  bool get isEnabled => true;

  int _requestId = 0;

  /// Cached tools list (populated on first getTools call)
  List<McpTool>? _cachedTools;

  /// Build a JSON-RPC 2.0 request body
  Map<String, dynamic> _buildRequest({
    required String method,
    Map<String, dynamic>? params,
  }) {
    _requestId++;
    return {
      'jsonrpc': '2.0',
      'id': _requestId,
      'method': method,
      if (params != null) 'params': params,
    };
  }

  @override
  Future<List<McpTool>> getTools() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '',
        data: _buildRequest(method: 'tools/list'),
      );

      final data = response.data;
      if (data == null) {
        _cachedTools = [];
        return _cachedTools!;
      }

      // Check for JSON-RPC error
      if (data.containsKey('error')) {
        final error = data['error'] as Map<String, dynamic>;
        developer.log(
          'tools/list error: ${error['message']}',
          name: 'RemoteMcpProvider',
        );
        _cachedTools = [];
        return _cachedTools!;
      }

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) {
        _cachedTools = [];
        return _cachedTools!;
      }

      final toolsList = result['tools'] as List<dynamic>? ?? [];
      _cachedTools = toolsList.map((t) {
        final tool = t as Map<String, dynamic>;
        final inputSchema =
            tool['inputSchema'] as Map<String, dynamic>? ?? {};
        final properties =
            inputSchema['properties'] as Map<String, dynamic>? ?? {};
        return McpTool(
          name: tool['name'] as String,
          description: tool['description'] as String? ?? '',
          providerId: serverId,
          parameters: properties,
        );
      }).toList();

      return _cachedTools!;
    } on DioException catch (e) {
      developer.log(
        'connection error: ${e.message}',
        name: 'RemoteMcpProvider',
      );
      _cachedTools ??= [];
      return _cachedTools!;
    } catch (e) {
      developer.log('getTools error: $e', name: 'RemoteMcpProvider');
      _cachedTools ??= [];
      return _cachedTools!;
    }
  }

  @override
  Future<McpResult> execute(
    String toolName,
    Map<String, dynamic> args,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '',
        data: _buildRequest(
          method: 'tools/call',
          params: {'name': toolName, 'arguments': args},
        ),
      );

      final data = response.data;
      if (data == null) {
        return McpResult.failure(
          toolName: toolName,
          message: '空响应',
        );
      }

      // Check for JSON-RPC error
      if (data.containsKey('error')) {
        final error = data['error'] as Map<String, dynamic>;
        return McpResult.failure(
          toolName: toolName,
          message: error['message'] as String? ?? 'Unknown error',
        );
      }

      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) {
        return McpResult.failure(
          toolName: toolName,
          message: '无结果',
        );
      }

      // MCP tools/call result: { content: [{type, text}], isError? }
      final isError = result['isError'] as bool? ?? false;
      final content = result['content'] as List<dynamic>? ?? [];

      // Extract text from content array
      final textParts = content
          .where((c) => c is Map<String, dynamic>)
          .map((c) => (c as Map<String, dynamic>)['text'] as String? ?? '')
          .where((t) => t.isNotEmpty)
          .join('\n');

      final message =
          textParts.isNotEmpty ? textParts : '执行完成（无文本输出）';

      if (isError) {
        return McpResult.failure(
          toolName: toolName,
          message: message,
        );
      }

      return McpResult.success(
        toolName: toolName,
        message: message,
      );
    } on DioException catch (e) {
      return McpResult.failure(
        toolName: toolName,
        message: '连接失败: ${e.message}',
      );
    } catch (e) {
      return McpResult.failure(
        toolName: toolName,
        message: '执行失败: $e',
      );
    }
  }

  /// Test connection to the server
  Future<bool> testConnection() async {
    try {
      await getTools();
      return true;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
