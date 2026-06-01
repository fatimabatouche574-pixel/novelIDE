import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_config_model.freezed.dart';
part 'ai_config_model.g.dart';

/// API protocol types.
enum ApiProtocol {
  openaiCompatible, // OpenAI / DeepSeek / 通义千问 / Moonshot 等
  anthropic, // Claude API
}

/// 模型类型
enum ModelType {
  text, // 文本对话模型
  tts, // 语音合成模型
  stt, // 语音识别模型
  multimodal, // 多模态模型
}

@freezed
class AiConfig with _$AiConfig {
  factory AiConfig({
    required String id,
    required String name,
    required String apiUrl,
    required String modelName,
    String? apiKey,
    @Default(1.0) double temperature,
    @Default(4096) int maxTokens,
    @Default(false) bool isLocal,
    @Default(ApiProtocol.openaiCompatible) ApiProtocol protocol,
    @Default(ModelType.text) ModelType modelType,
    // ---- 采样参数 ----
    @Default(1.0) double topP,
    @Default(0) int topK,
    // ---- 重复控制 ----
    @Default(0.0) double presencePenalty,
    @Default(0.0) double frequencyPenalty,
    // ---- 参数启用开关 ----
    @Default(false) bool topPEnabled,
    @Default(false) bool topKEnabled,
    @Default(false) bool presencePenaltyEnabled,
    @Default(false) bool frequencyPenaltyEnabled,
    // ---- 上下文配置 ----
    @Default(64.0) double contextLength,
    @Default(0.7) double summaryTokenThreshold,
    @Default(true) bool enableSummary,
    // ---- 高级功能 ----
    @Default(false) bool enableToolCall,
    @Default(false) bool enableClaude1hPromptCache,
    @Default(false) bool enableGoogleSearch,
    @Default(0) int requestLimitPerMinute,
    @Default(0) int maxConcurrentRequests,
    // ---- 自定义请求头 ----
    @Default('{}') String customHeaders,
  }) = _AiConfig;

  factory AiConfig.fromJson(Map<String, dynamic> json) =>
      _$AiConfigFromJson(json);
}
