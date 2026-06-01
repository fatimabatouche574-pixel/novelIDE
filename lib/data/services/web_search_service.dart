import 'package:dio/dio.dart';

/// 网络搜索结果
class WebSearchResult {
  final String title;
  final String url;
  final String snippet;

  const WebSearchResult({
    required this.title,
    required this.url,
    required this.snippet,
  });

  @override
  String toString() => '[$title]($url)\n$snippet';
}

/// 联网搜索服务，使用 DuckDuckGo Instant Answer API
class WebSearchService {
  static const String _baseUrl = 'https://api.duckduckgo.com/';

  /// 搜索网络并返回结果列表
  static Future<List<WebSearchResult>> search(String query) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await dio.get(
        _baseUrl,
        queryParameters: {
          'q': query,
          'format': 'json',
          'no_html': '1',
          'skip_disambig': '1',
        },
      );

      final results = <WebSearchResult>[];

      // 解析 AbstractText
      final abstractText = response.data['AbstractText'] as String? ?? '';
      final abstractUrl = response.data['AbstractURL'] as String? ?? '';
      final abstractSource = response.data['AbstractSource'] as String? ?? '';
      if (abstractText.isNotEmpty) {
        results.add(
          WebSearchResult(
            title: abstractSource.isNotEmpty ? abstractSource : 'Abstract',
            url: abstractUrl.isNotEmpty ? abstractUrl : '',
            snippet: abstractText,
          ),
        );
      }

      // 解析 RelatedTopics
      final relatedTopics =
          response.data['RelatedTopics'] as List<dynamic>? ?? [];
      for (final topic in relatedTopics) {
        if (topic is Map<String, dynamic>) {
          final text = topic['Text'] as String? ?? '';
          final url = topic['FirstURL'] as String? ?? '';
          if (text.isNotEmpty) {
            // 分离标题和内容
            final parts = text.split(' - ');
            final title = parts.isNotEmpty ? parts.first : text;
            final snippet = parts.length > 1
                ? parts.sublist(1).join(' - ')
                : '';

            results.add(
              WebSearchResult(
                title: title,
                url: url,
                snippet: snippet.isNotEmpty ? snippet : text,
              ),
            );
          }
        }
      }

      return results;
    } on DioException {
      // 网络错误时返回空列表，不崩溃
      return [];
    } catch (_) {
      return [];
    }
  }
}
