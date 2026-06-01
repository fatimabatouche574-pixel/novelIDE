// ============================================================
// 工具系统结构化定义
// 用途：工具参数schema、校验、Hook、调用追踪、XML反转义
// ============================================================

/// 工具参数结构化定义
class ToolParameterSchema {
  final String name;
  final String type; // "string", "boolean", "integer", "number"
  final String description;
  final bool required;
  final String? defaultValue;

  const ToolParameterSchema({
    required this.name,
    this.type = 'string',
    required this.description,
    this.required = true,
    this.defaultValue,
  });

  /// 从 JSON 构造
  factory ToolParameterSchema.fromJson(Map<String, dynamic> json) {
    return ToolParameterSchema(
      name: json['name'] as String,
      type: json['type'] as String? ?? 'string',
      description: json['description'] as String,
      required: json['required'] as bool? ?? true,
      defaultValue: json['defaultValue'] as String?,
    );
  }

  /// 转为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'description': description,
      'required': required,
      if (defaultValue != null) 'defaultValue': defaultValue,
    };
  }

  /// 复制并修改
  ToolParameterSchema copyWith({
    String? name,
    String? type,
    String? description,
    bool? required,
    String? defaultValue,
  }) {
    return ToolParameterSchema(
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      required: required ?? this.required,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  @override
  String toString() =>
      'ToolParameterSchema(name: $name, type: $type, required: $required)';
}

/// 工具参数校验结果
class ToolValidationResult {
  final bool valid;
  final String errorMessage;

  const ToolValidationResult({required this.valid, this.errorMessage = ''});

  factory ToolValidationResult.ok() => const ToolValidationResult(valid: true);

  factory ToolValidationResult.invalid(String message) =>
      ToolValidationResult(valid: false, errorMessage: message);

  @override
  String toString() =>
      'ToolValidationResult(valid: $valid, error: $errorMessage)';
}

/// 工具调用钩子接口
abstract class ToolHook {
  void onToolCallRequested(String toolName, Map<String, dynamic> args) {}
  void onToolExecutionStarted(String toolName) {}
  void onToolExecutionResult(String toolName, bool success) {}
  void onToolExecutionError(String toolName, Object error) {}
  void onToolExecutionFinished(String toolName) {}
}

/// 工具调用偏移量追踪
class ToolInvocation {
  final String toolName;
  final String rawText;
  final int startOffset;
  final int endOffset;

  const ToolInvocation({
    required this.toolName,
    required this.rawText,
    required this.startOffset,
    required this.endOffset,
  });

  @override
  String toString() =>
      'ToolInvocation(tool: $toolName, range: [$startOffset, $endOffset])';
}

/// XML反转义
String unescapeXml(String input) {
  var result = input;
  if (result.startsWith('<![CDATA[') && result.endsWith(']]>')) {
    result = result.substring(9, result.length - 3);
  }
  if (result.endsWith(']]>')) {
    result = result.substring(0, result.length - 3);
  }
  if (result.startsWith('<![CDATA[')) {
    result = result.substring(9);
  }
  return result
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");
}
