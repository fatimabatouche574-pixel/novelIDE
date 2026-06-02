import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 语言选择页 — 5种语言单项选择
class OperitLanguagePage extends StatefulWidget {
  const OperitLanguagePage({super.key});

  @override
  State<OperitLanguagePage> createState() => _OperitLanguagePageState();
}

class _OperitLanguagePageState extends State<OperitLanguagePage> {
  String _selected = '中文';

  static const _languages = [
    ('中文', '\u{1F1E8}\u{1F1F3}'),
    ('English', '\u{1F1FA}\u{1F1F8}'),
    ('\u{65E5}\u{672C}\u{8A9E}', '\u{1F1EF}\u{1F1F5}'),
    ('\u{D55C}\u{AD6D}\u{C5B4}', '\u{1F1F0}\u{1F1F7}'),
    ('\u{7E41}\u{9AD4}', '\u{1F1ED}\u{1F1F0}'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('语言')),
      body: ListView(
        padding: EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildGroup(
            '界面语言',
            _languages.map((lang) {
              final isSelected = _selected == lang.$1;
              return ListTile(
                leading: Text(lang.$2, style: const TextStyle(fontSize: 20)),
                title: Text(lang.$1, style: const TextStyle(fontSize: 14)),
                trailing: isSelected
                    ? const Icon(Icons.check, color: UiTokens.primary)
                    : null,
                onTap: () {
                  setState(() => _selected = lang.$1);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: UiTokens.titleFS,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}
