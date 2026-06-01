/// XML 工具调用信息
class ToolCallInfo {
  final String name;
  final Map<String, dynamic> arguments;
  final String rawXml;
  final int startOffset;
  final int endOffset;

  const ToolCallInfo({
    required this.name,
    required this.arguments,
    required this.rawXml,
    required this.startOffset,
    required this.endOffset,
  });
}

/// XML 工具调用解析器
///
/// 解析 AI 回复中的 XML 格式工具调用，用于不支持 function calling 的模型降级。
///
/// 支持的格式：
/// ```xml
/// <tool name="get_characters"></tool>
/// <tool name="add_character">
///   <param name="name">张三</param>
///   <param name="role">主角</param>
/// </tool>
/// ```
class XmlToolCallParser {
  static final _toolPattern = RegExp(
    r'<tool\s+name="([^"]+)">(.*?)</tool>',
    dotAll: true,
  );

  static final _paramPattern = RegExp(
    r'<param\s+name="([^"]+)">(.*?)</param>',
    dotAll: true,
  );

  /// 解析文本中的 XML 工具调用
  ///
  /// 返回解析到的工具调用列表，空列表表示没有找到工具调用。
  static List<ToolCallInfo> parse(String text) {
    if (text.isEmpty) return const [];

    final calls = <ToolCallInfo>[];

    for (final match in _toolPattern.allMatches(text)) {
      final toolName = match.group(1)!;
      final innerContent = match.group(2)!;

      // 解析参数
      final args = <String, dynamic>{};
      for (final paramMatch
          in _paramPattern.allMatches(innerContent)) {
        final paramName = paramMatch.group(1)!;
        final paramValue =
            unescapeXml(paramMatch.group(2)!);
        args[paramName] = paramValue;
      }

      calls.add(ToolCallInfo(
        name: toolName,
        arguments: args,
        rawXml: match.group(0)!,
        startOffset: match.start,
        endOffset: match.end,
      ));
    }

    return calls;
  }

  /// 检查文本中是否包含 XML 工具调用
  static bool hasToolCalls(String text) {
    return _toolPattern.hasMatch(text);
  }

  /// 从文本中移除所有 XML 工具调用标签，返回纯文本
  static String stripToolCalls(String text) {
    return text
        .replaceAll(_toolPattern, '')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}

/// XML 实体反转义
String unescapeXml(String input) {
  var result = input;
  if (result.startsWith('<![CDATA[') &&
      result.endsWith(']]>')) {
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
