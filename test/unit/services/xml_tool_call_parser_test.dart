import 'package:flutter_test/flutter_test.dart';
import 'package:novel_ide/data/services/chat/xml_tool_call_parser.dart';

void main() {
  group('XmlToolCallParser.parse', () {
    test('empty string returns empty list', () {
      final result = XmlToolCallParser.parse('');
      expect(result, isEmpty);
    });

    test('text without tool calls returns empty list', () {
      final result = XmlToolCallParser.parse('这是一段普通文本，没有工具调用。');
      expect(result, isEmpty);
    });

    test('single tool call with no parameters', () {
      final result = XmlToolCallParser.parse(
        '<tool name="get_characters"></tool>',
      );

      expect(result, hasLength(1));
      expect(result.first.name, 'get_characters');
      expect(result.first.arguments, isEmpty);
      expect(result.first.rawXml, '<tool name="get_characters"></tool>');
    });

    test('single tool call with parameters', () {
      final result = XmlToolCallParser.parse(
        '<tool name="add_character">'
        '<param name="name">张三</param>'
        '<param name="role">主角</param>'
        '</tool>',
      );

      expect(result, hasLength(1));
      expect(result.first.name, 'add_character');
      expect(result.first.arguments, {'name': '张三', 'role': '主角'});
    });

    test('multiple tool calls', () {
      final input =
          '一些文本'
          '<tool name="get_characters"></tool>'
          '中间文本'
          '<tool name="add_character">'
          '<param name="name">李四</param>'
          '</tool>'
          '结尾文本';

      final result = XmlToolCallParser.parse(input);

      expect(result, hasLength(2));
      expect(result[0].name, 'get_characters');
      expect(result[1].name, 'add_character');
      expect(result[1].arguments, {'name': '李四'});
    });

    test('parameters with XML special characters are unescaped', () {
      final result = XmlToolCallParser.parse(
        '<tool name="test">'
        '<param name="code">if (a &lt; b &amp;&amp; c &gt; d)</param>'
        '</tool>',
      );

      expect(result, hasLength(1));
      expect(result.first.arguments['code'], 'if (a < b && c > d)');
    });

    test('parameters with CDATA', () {
      final result = XmlToolCallParser.parse(
        '<tool name="test">'
        '<param name="content"><![CDATA[<div>hello & welcome</div>]]></param>'
        '</tool>',
      );

      expect(result, hasLength(1));
      expect(result.first.arguments['content'], '<div>hello & welcome</div>');
    });

    test('tool call embedded in surrounding text', () {
      const input =
          'AI 说：你好，我来帮你查一下角色。'
          '<tool name="get_characters"></tool>'
          '以上是查询结果。';

      final result = XmlToolCallParser.parse(input);

      expect(result, hasLength(1));
      expect(result.first.name, 'get_characters');
      expect(result.first.startOffset, greaterThan(0));
      expect(result.first.endOffset, lessThan(input.length));
    });

    test('startOffset and endOffset are correct', () {
      const prefix = 'prefix_';
      const toolXml = '<tool name="foo"></tool>';
      const input = '$prefix$toolXml';

      final result = XmlToolCallParser.parse(input);

      expect(result, hasLength(1));
      expect(result.first.startOffset, prefix.length);
      expect(result.first.endOffset, prefix.length + toolXml.length);
      expect(result.first.rawXml, toolXml);
    });
  });

  group('XmlToolCallParser.hasToolCalls', () {
    test('returns true when text contains tool calls', () {
      expect(
        XmlToolCallParser.hasToolCalls('<tool name="foo"></tool>'),
        isTrue,
      );
    });

    test('returns false when text has no tool calls', () {
      expect(XmlToolCallParser.hasToolCalls('普通文本'), isFalse);
    });

    test('returns false for empty string', () {
      expect(XmlToolCallParser.hasToolCalls(''), isFalse);
    });
  });

  group('XmlToolCallParser.stripToolCalls', () {
    test('removes tool tags and preserves surrounding text', () {
      const input = '开头文本\n<tool name="get_characters"></tool>\n结尾文本';
      final result = XmlToolCallParser.stripToolCalls(input);
      // Two newlines around the removed tag become \n\n (only 3+ collapsed)
      expect(result, '开头文本\n\n结尾文本');
    });

    test('removes multiple tool calls and collapses excess newlines', () {
      const input =
          'A\n'
          '<tool name="foo"></tool>\n'
          '\n'
          '<tool name="bar"><param name="x">1</param></tool>\n'
          'B';
      final result = XmlToolCallParser.stripToolCalls(input);
      expect(result, contains('A'));
      expect(result, contains('B'));
      expect(result, isNot(contains('<tool')));
      // 3+ consecutive newlines should be collapsed to 2
      expect(result.contains('\n\n\n'), isFalse);
    });

    test('returns empty string when input is only a tool call', () {
      final result = XmlToolCallParser.stripToolCalls(
        '<tool name="foo"></tool>',
      );
      expect(result, isEmpty);
    });

    test('handles multiline tool content', () {
      const input =
          'before\n'
          '<tool name="test">\n'
          '  <param name="key">value</param>\n'
          '</tool>\n'
          'after';
      final result = XmlToolCallParser.stripToolCalls(input);
      // Tag removal leaves \n\n between "before" and "after" (only 3+ collapsed)
      expect(result, 'before\n\nafter');
    });
  });

  group('unescapeXml', () {
    test('unescapes &lt; &gt; &amp; &quot; &apos;', () {
      expect(unescapeXml('&lt;'), '<');
      expect(unescapeXml('&gt;'), '>');
      expect(unescapeXml('&amp;'), '&');
      expect(unescapeXml('&quot;'), '"');
      expect(unescapeXml("&apos;"), "'");
    });

    test('unescapes mixed entities', () {
      expect(unescapeXml('a &lt; b &amp; c &gt; d'), 'a < b & c > d');
    });

    test('strips CDATA wrapper', () {
      expect(
        unescapeXml('<![CDATA[raw <content> & stuff]]>'),
        'raw <content> & stuff',
      );
    });

    test('strips leading CDATA marker', () {
      expect(unescapeXml('<![CDATA[hello'), 'hello');
    });

    test('strips trailing CDATA marker', () {
      expect(unescapeXml('hello]]>'), 'hello');
    });

    test('plain string passes through unchanged', () {
      expect(unescapeXml('hello world'), 'hello world');
    });
  });
}
