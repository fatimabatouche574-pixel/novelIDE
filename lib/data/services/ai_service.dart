import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/data/models/ai_config_model.dart';
import 'package:novel_ide/data/services/cost_tracker.dart';

/// Unified AI service with cost tracking.
/// 自适应兼容所有主流 API 厂商（OpenAI / Anthropic / 小米MiMo / DeepSeek / 通义千问 / Moonshot 等）
class AiService {
  final Dio _dio = Dio();
  final CostTracker _costTracker = CostTracker();

  AiService() {
    // 添加重试拦截器：网络波动自动重试
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          // 只对网络错误重试，不对4xx/5xx重试
          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            try {
              // 最多重试2次，间隔递增
              final retryCount =
                  error.requestOptions.extra['retryCount'] as int? ?? 0;
              if (retryCount < 2) {
                final delay = Duration(seconds: (retryCount + 1) * 2);
                await Future.delayed(delay);
                error.requestOptions.extra['retryCount'] = retryCount + 1;
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            } catch (_) {}
          }
          handler.next(error);
        },
      ),
    );
  }

  /// 智能补全 API 地址
  /// 兼容所有常见 URL 格式，自动补全为完整请求路径
  String _normalizeApiUrl(String url, ApiProtocol protocol) {
    url = url.trim();
    if (url.isEmpty) return url;

    // 已经是完整端点，直接返回
    if (url.contains('/chat/completions')) return url;
    if (url.contains('/v1/messages') || url.contains('/v1/messages/'))
      return url;

    // 去除末尾斜杠（但保留协议部分）
    url = url.replaceAll(RegExp(r'/+$'), '');

    // Anthropic 协议
    if (protocol == ApiProtocol.anthropic) {
      // https://api.anthropic.com → https://api.anthropic.com/v1/messages
      // https://xxx/v1 → https://xxx/v1/messages
      if (url.endsWith('/v1')) return '$url/messages';
      if (url.endsWith('/anthropic')) return '$url/v1/messages';
      return '$url/v1/messages';
    }

    // OpenAI 兼容协议（覆盖所有主流厂商）
    // https://api.openai.com → https://api.openai.com/v1/chat/completions
    // https://api.deepseek.com/v1 → https://api.deepseek.com/v1/chat/completions
    // https://api.example.com/api/v1 → https://api.example.com/api/v1/chat/completions
    // https://xxx/v1/openai → https://xxx/v1/openai/chat/completions
    if (url.endsWith('/v1')) return '$url/chat/completions';
    return '$url/v1/chat/completions';
  }

  /// Send a chat completion request. Tracks cost automatically.
  Future<String> chat(
    AiConfig config,
    List<Map<String, String>> messages, {
    String taskType = 'chat',
  }) async {
    final normalizedUrl = _normalizeApiUrl(config.apiUrl, config.protocol);

    try {
      final response = await _dio.post(
        normalizedUrl,
        options: Options(
          headers: _buildHeaders(config),
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 120),
        ),
        data: _buildPayload(config, messages),
      );

      final parsed = _parseResponse(config, response);

      // Track usage
      final usage = response.data['usage'];
      final tokenCount =
          (usage?['total_tokens'] as int?) ?? parsed.content.length ~/ 2;
      _costTracker.recordUsage(
        configId: config.id,
        model: config.modelName,
        taskType: taskType,
        tokenCount: tokenCount,
      );

      return parsed.content;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final respBody = e.response?.data?.toString() ?? '';
      if (statusCode == 401) {
        throw Exception('API Key 无效或认证失败 (401)，请检查API Key是否正确');
      }
      if (statusCode == 403) {
        throw Exception('API Key 无权限访问该资源 (403)');
      }
      if (statusCode == 404) {
        throw Exception('API地址错误 (404)，请检查URL配置');
      }
      if (statusCode == 429) {
        throw Exception('请求频率超限 (429)，请稍后再试');
      }
      if (statusCode == 402) {
        throw Exception('API 余额不足 (402)，请充值后重试');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('连接超时，请检查网络或API地址');
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('服务器响应超时，可能是max_tokens过大或模型负载高');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('无法连接到服务器，请检查API地址和网络');
      }
      // 尝试从 response body 提取更具体的错误信息
      if (respBody.isNotEmpty && respBody.length < 500) {
        throw Exception('API错误 ($statusCode): $respBody');
      }
      if (statusCode != null) {
        throw Exception('请求失败: HTTP $statusCode');
      }
      throw Exception('网络错误: ${e.message ?? "连接异常"}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('未知错误: $e');
    }
  }

  /// 构建认证头
  /// 同时发送多种认证头，兼容所有主流 API 厂商：
  /// - Authorization: Bearer xxx  → OpenAI / DeepSeek / 通义千问 / Moonshot 等
  /// - api-key: xxx             → 小米 MiMo / 部分国内厂商
  /// - x-api-key: xxx           → Anthropic Claude
  /// 服务端只会识别自己需要的头，其他头会被忽略
  Map<String, String> _buildHeaders(AiConfig config) {
    // 获取API Key
    String apiKey = config.apiKey ?? '';
    if (apiKey.isEmpty) {
      // API Key 为空，后续请求会返回 401
      print('警告: API Key 为空，请在设置中配置');
    }

    final headers = <String, String>{'Content-Type': 'application/json'};

    if (config.protocol == ApiProtocol.anthropic) {
      headers['x-api-key'] = apiKey;
      headers['anthropic-version'] = '2023-06-01';
    } else {
      // OpenAI 兼容协议：同时发送 Bearer 和 api-key，兼容所有厂商
      headers['Authorization'] = 'Bearer $apiKey';
      headers['api-key'] = apiKey;
    }

    return headers;
  }

  Map<String, dynamic> _buildPayload(
    AiConfig config,
    List<Map<String, String>> messages,
  ) {
    // 所有协议统一：从 messages 中提取 system 消息，作为单独字段传递
    String? systemContent;
    final nonSystemMessages = <Map<String, String>>[];

    for (final msg in messages) {
      if (msg['role'] == 'system' && systemContent == null) {
        systemContent = msg['content'];
      } else {
        nonSystemMessages.add(msg);
      }
    }

    // OpenAI 兼容协议
    final payload = <String, dynamic>{
      'model': config.modelName,
      'messages': nonSystemMessages,
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
    };

    if (systemContent != null && systemContent.isNotEmpty) {
      if (config.protocol == ApiProtocol.anthropic) {
        payload['system'] = systemContent;
      } else {
        // OpenAI 兼容：系统提示作为第一条 system message
        payload['messages'] = [
          {'role': 'system', 'content': systemContent},
          ...nonSystemMessages,
        ];
      }
    }

    return payload;
  }

  ({String content, String? thinkingContent}) _parseResponse(
    AiConfig config,
    dynamic response,
  ) {
    if (config.protocol == ApiProtocol.anthropic) {
      final content = response.data['content'];
      if (content is List && content.isNotEmpty) {
        return (
          content: content[0]['text'] ?? '生成失败',
          thinkingContent: content[0]['thinking'] as String?,
        );
      }
      return (content: '生成失败，请检查API配置', thinkingContent: null);
    }
    final message = response.data['choices']?[0]?['message'];
    final thinkingContent =
        message?['reasoning_content'] as String? ??
        message?['thinking'] as String?;
    return (
      content: message?['content'] ?? '生成失败，请检查API配置',
      thinkingContent: thinkingContent,
    );
  }

  /// Convenience: send with system prompt + user message.
  Future<String> send({
    required AiConfig config,
    required String systemPrompt,
    required String userMessage,
    String taskType = 'chat',
  }) async {
    return chat(config, [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userMessage},
    ], taskType: taskType);
  }

  /// Send chat with function calling (OpenAI compatible).
  /// Returns parsed response with optional tool_calls.
  Future<ToolChatResponse> chatWithTools({
    required AiConfig config,
    required List<Map<String, dynamic>> messages,
    List<dynamic>? tools,
    String taskType = 'agent',
  }) async {
    final normalizedUrl = _normalizeApiUrl(config.apiUrl, config.protocol);
    // 判断是否发送 tools（先尝试发送）
    final bool shouldSendTools =
        config.protocol != ApiProtocol.anthropic &&
        tools != null &&
        tools.isNotEmpty;

    Future<ToolChatResponse> doRequest({required bool withTools}) async {
      final payload = <String, dynamic>{
        'model': config.modelName,
        'messages': messages,
        'temperature': config.temperature,
        'max_tokens': config.maxTokens,
      };
      if (withTools) {
        payload['tools'] = tools;
      }

      final response = await _dio.post(
        normalizedUrl,
        options: Options(
          headers: _buildHeaders(config),
          receiveTimeout: const Duration(seconds: 120),
        ),
        data: payload,
      );

      // Track usage
      final usage = response.data['usage'];
      final tokenCount = (usage?['total_tokens'] as int?) ?? 0;
      _costTracker.recordUsage(
        configId: config.id,
        model: config.modelName,
        taskType: taskType,
        tokenCount: tokenCount > 0 ? tokenCount : 100,
      );

      // Parse response
      final choice = response.data['choices']?[0];
      final message = choice?['message'];
      final content = message?['content'] as String?;

      // Extract thinking content (DeepSeek reasoning_content, etc.)
      final thinkingContent =
          message?['reasoning_content'] as String? ??
          message?['thinking'] as String?;

      // Parse tool_calls
      List<ToolCallInfo>? toolCalls;
      if (withTools) {
        final rawToolCalls = message?['tool_calls'];
        if (rawToolCalls != null &&
            rawToolCalls is List &&
            rawToolCalls.isNotEmpty) {
          toolCalls = rawToolCalls
              .map(
                (tc) => ToolCallInfo(
                  id: tc['id'] as String? ?? '',
                  functionName: tc['function']?['name'] as String? ?? '',
                  arguments: tc['function']?['arguments'] ?? '{}',
                ),
              )
              .toList();
        }
      }

      return ToolChatResponse(
        content: content,
        toolCalls: toolCalls,
        thinkingContent: thinkingContent,
      );
    }

    try {
      return await doRequest(withTools: shouldSendTools);
    } on DioException catch (e) {
      // 如果带 tools 失败（MiMo等不支持tools的API），去掉 tools 重试
      if (shouldSendTools &&
          (e.response?.statusCode == 400 || e.response?.statusCode == 422)) {
        try {
          return await doRequest(withTools: false);
        } on DioException catch (fallbackError) {
          // 降级也失败，返回清晰错误而不是原始 Dio 错误
          final code = fallbackError.response?.statusCode ?? 0;
          if (code == 401) throw Exception('API Key 无效或认证失败 (401)，请检查配置');
          if (code == 403) throw Exception('API Key 无权限访问该资源 (403)');
          if (code == 404) throw Exception('API地址错误 (404)，请检查URL配置');
          if (code == 429) throw Exception('请求频率超限 (429)，请稍后再试');
          throw Exception('API请求失败 ($code)，请检查模型配置或网络');
        }
      }

      final statusCode = e.response?.statusCode;
      final respBody = e.response?.data?.toString() ?? '';
      if (statusCode == 401) throw Exception('API Key 无效或认证失败 (401)');
      if (statusCode == 403) throw Exception('API Key 无权限访问该资源 (403)');
      if (statusCode == 404) throw Exception('API地址错误 (404)');
      if (statusCode == 429) throw Exception('请求频率超限 (429)，请稍后再试');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('连接超时，请检查网络或API地址');
      }
      if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('服务器响应超时，可能是max_tokens过大或模型负载高');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('无法连接到服务器，请检查API地址和网络');
      }
      if (respBody.isNotEmpty && respBody.length < 300) {
        throw Exception('请求失败 ($statusCode): $respBody');
      }
      throw Exception('请求失败: ${e.message ?? e.type.name}');
    } catch (e) {
      // 兜底：非DioException的错误（如响应解析TypeError、NoSuchMethodError）
      throw Exception('API响应解析失败: $e');
    }
  }

  /// 测试API连接 — 发送最小请求验证连通性
  Future<Map<String, dynamic>> testConnection(AiConfig config) async {
    final stopwatch = Stopwatch()..start();
    try {
      final normalizedUrl = _normalizeApiUrl(config.apiUrl, config.protocol);
      await _dio.post(
        normalizedUrl,
        options: Options(
          headers: _buildHeaders(config),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: _buildPayload(config, [
          {'role': 'user', 'content': 'hi'},
        ]),
      );
      stopwatch.stop();
      return {
        'success': true,
        'message': '连接成功！模型「${config.modelName}」响应正常',
        'latency_ms': stopwatch.elapsedMilliseconds,
      };
    } on DioException catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'message': _formatDioError(e),
        'latency_ms': stopwatch.elapsedMilliseconds,
        'status_code': e.response?.statusCode,
      };
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'message': '未知错误: $e',
        'latency_ms': stopwatch.elapsedMilliseconds,
      };
    }
  }

  /// 获取模型列表 — 兼容 OpenAI /v1/models 格式
  Future<List<String>> fetchModels(AiConfig config) async {
    try {
      String modelsUrl = _buildModelsUrl(config.apiUrl.trim());
      final response = await _dio.get(
        modelsUrl,
        options: Options(
          headers: _buildHeaders(config),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      return _parseModels(response.data);
    } on DioException catch (e) {
      throw Exception(_formatDioError(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('获取模型列表失败: $e');
    }
  }

  /// 构造 models 列表端点 URL
  String _buildModelsUrl(String url) {
    if (url.contains('/models')) return url;
    url = url.replaceAll(RegExp(r'/+$'), '');
    if (url.contains('/chat/completions')) {
      return url.replaceAll('/chat/completions', '/models');
    }
    if (url.endsWith('/v1/messages')) {
      return '${url.substring(0, url.length - '/v1/messages'.length)}/v1/models';
    }
    if (url.endsWith('/v1')) return '$url/models';
    return '$url/v1/models';
  }

  /// 解析模型列表响应
  List<String> _parseModels(dynamic data) {
    final models = <String>[];
    if (data is Map<String, dynamic>) {
      final dataList = data['data'];
      if (dataList is List) {
        for (final item in dataList) {
          if (item is Map<String, dynamic>) {
            final id = item['id'] as String?;
            if (id != null && id.isNotEmpty) models.add(id);
          }
        }
      }
      final modelsList = data['models'];
      if (modelsList is List && models.isEmpty) {
        for (final item in modelsList) {
          if (item is String) {
            models.add(item);
          } else if (item is Map<String, dynamic>) {
            final id = item['id'] as String? ?? item['name'] as String?;
            if (id != null && id.isNotEmpty) models.add(id);
          }
        }
      }
    } else if (data is List) {
      for (final item in data) {
        if (item is String) {
          models.add(item);
        } else if (item is Map<String, dynamic>) {
          final id = item['id'] as String? ?? item['name'] as String?;
          if (id != null && id.isNotEmpty) models.add(id);
        }
      }
    }
    models.sort();
    return models;
  }

  /// 统一格式化 DioException 错误信息
  String _formatDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final respBody = e.response?.data?.toString() ?? '';
    if (statusCode == 401) return 'API Key 无效或认证失败 (401)';
    if (statusCode == 403) return 'API Key 无权限 (403)';
    if (statusCode == 404) return 'API 地址错误 (404)，请检查 URL';
    if (statusCode == 429) return '请求频率超限 (429)，请稍后再试';
    if (statusCode == 402) return 'API 余额不足 (402)';
    if (statusCode == 500) return '服务器内部错误 (500)';
    if (statusCode == 502) return '网关错误 (502)，服务可能在维护';
    if (statusCode == 503) return '服务暂不可用 (503)';
    if (e.type == DioExceptionType.connectionTimeout) return '连接超时，请检查网络和API地址';
    if (e.type == DioExceptionType.sendTimeout) return '发送超时，请检查网络';
    if (e.type == DioExceptionType.receiveTimeout) return '响应超时，服务器处理时间过长';
    if (e.type == DioExceptionType.connectionError)
      return '无法连接到服务器，请检查 API 地址和网络';
    if (respBody.isNotEmpty && respBody.length < 500)
      return '错误 ($statusCode): $respBody';
    if (statusCode != null) return '请求失败: HTTP $statusCode';
    return '网络错误: ${e.message ?? "连接异常"}';
  }
}

/// Tool calling response
class ToolChatResponse {
  final String? content;
  final List<ToolCallInfo>? toolCalls;
  final String? thinkingContent;

  const ToolChatResponse({this.content, this.toolCalls, this.thinkingContent});
}

/// Tool call info parsed from API response
class ToolCallInfo {
  final String id;
  final String functionName;
  final dynamic arguments;

  const ToolCallInfo({
    required this.id,
    required this.functionName,
    required this.arguments,
  });
}

final aiServiceProvider = Provider((ref) => AiService());
