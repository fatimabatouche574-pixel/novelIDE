import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 上下文摘要设置页 — 上下文长度/摘要开关/阈值/历史保留
class OperitContextSummaryPage extends StatefulWidget {
  const OperitContextSummaryPage({super.key});

  @override
  State<OperitContextSummaryPage> createState() =>
      _OperitContextSummaryPageState();
}

class _OperitContextSummaryPageState
    extends State<OperitContextSummaryPage> {
  bool _summaryEnabled = true;
  bool _autoSummarize = true;
  double _contextLength = 32000;
  int _threshold = 80;
  int _historyRetention = 30;
  bool _compressImages = true;
  bool _removeCodeBlocks = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('上下文摘要')),
      body: ListView(
        padding: EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildGroup('上下文长度', [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text('最大Token数', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: _contextLength,
                      min: 4096,
                      max: 131072,
                      divisions: 31,
                      label: '${_contextLength.toInt()}',
                      onChanged: (v) {
                        setState(() => _contextLength = v);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${_contextLength.toInt()}',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: UiTokens.sectionSpacing),
          _buildGroup('摘要设置', [
            SwitchListTile(
              title: const Text('启用摘要', style: TextStyle(fontSize: 14)),
              subtitle: const Text('自动对超长上下文进行摘要压缩'),
              value: _summaryEnabled,
              onChanged: (v) => setState(() => _summaryEnabled = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_summaryEnabled) ...[
              SwitchListTile(
                title: const Text('自动摘要', style: TextStyle(fontSize: 14)),
                subtitle: const Text('达到阈值时自动触发摘要'),
                value: _autoSummarize,
                onChanged: (v) => setState(() => _autoSummarize = v),
                contentPadding: EdgeInsets.zero,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const Text('触发阈值', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Slider(
                        value: _threshold.toDouble(),
                        min: 50,
                        max: 95,
                        divisions: 9,
                        label: '$_threshold%',
                        onChanged: (v) {
                          setState(() => _threshold = v.toInt());
                        },
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$_threshold%',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ]),
          const SizedBox(height: UiTokens.sectionSpacing),
          _buildGroup('历史保留', [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Text('保留天数', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: _historyRetention.toDouble(),
                      min: 7,
                      max: 90,
                      divisions: 15,
                      label: '$_historyRetention天',
                      onChanged: (v) {
                        setState(() => _historyRetention = v.toInt());
                      },
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '$_historyRetention天',
                      style: const TextStyle(fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: UiTokens.sectionSpacing),
          _buildGroup('内容压缩', [
            SwitchListTile(
              title: const Text('压缩图片', style: TextStyle(fontSize: 14)),
              subtitle: const Text('摘要时移除或压缩图片引用'),
              value: _compressImages,
              onChanged: (v) => setState(() => _compressImages = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('移除代码块', style: TextStyle(fontSize: 14)),
              subtitle: const Text('摘要时移除代码块以减少Token'),
              value: _removeCodeBlocks,
              onChanged: (v) => setState(() => _removeCodeBlocks = v),
              contentPadding: EdgeInsets.zero,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildGroup(String title, List<Widget> children) {
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
        ...children,
      ],
    );
  }
}
