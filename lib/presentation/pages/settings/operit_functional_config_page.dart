import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 功能模型分配页 — 8个功能卡片，每个可独立选择模型
class OperitFunctionalConfigPage extends StatefulWidget {
  const OperitFunctionalConfigPage({super.key});

  @override
  State<OperitFunctionalConfigPage> createState() =>
      _OperitFunctionalConfigPageState();
}

class _OperitFunctionalConfigPageState
    extends State<OperitFunctionalConfigPage> {
  static const _functions = [
    ('\u{1F4AC}', '聊天', '对话生成模型'),
    ('\u{1F4DD}', '摘要', '文本摘要模型'),
    ('\u{1F9E0}', '记忆', '记忆管理模型'),
    ('\u{1F39B}\u{FE0F}', 'UI控制', '界面控制模型'),
    ('\u{1F310}', '翻译', '翻译模型'),
    ('\u{1F50D}', '搜索', '联网搜索模型'),
    ('\u{1F5BC}\u{FE0F}', '图像识别', '图像识别模型'),
    ('\u{1F399}\u{FE0F}', '语音识别', '语音识别模型'),
  ];

  final _assigned = <String, String>{
    '聊天': 'Claude-4-Sonnet',
    '摘要': 'Claude-4-Sonnet',
    '记忆': 'GPT-4o',
    'UI控制': 'Haiku',
    '翻译': 'DeepSeek-V3',
    '搜索': 'GPT-4o',
    '图像识别': 'GPT-4o',
    '语音识别': 'Gemini-2.5',
  };

  static const _availableModels = [
    'Claude-4-Sonnet',
    'GPT-4o',
    'Gemini-2.5',
    'DeepSeek-V3',
    'Haiku',
    'Local MNN',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('功能模型分配')),
      body: ListView(
        padding: EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildGroup(
            '为不同功能分配模型',
            _functions.map((func) {
              return _buildFunctionCard(
                icon: func.$1,
                name: func.$2,
                desc: func.$3,
                model: _assigned[func.$2] ?? 'Claude-4-Sonnet',
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionCard({
    required String icon,
    required String name,
    required String desc,
    required String model,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiTokens.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            DropdownButton<String>(
              value: model,
              underline: const SizedBox.shrink(),
              isDense: true,
              items:
                  _availableModels.map((m) {
                    return DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)));
                  }).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _assigned[name] = v);
                }
              },
            ),
          ],
        ),
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
