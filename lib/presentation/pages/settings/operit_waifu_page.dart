import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// Waifu模式设置页 — 开关/延迟/自定义提示词
class OperitWaifuPage extends StatefulWidget {
  const OperitWaifuPage({super.key});

  @override
  State<OperitWaifuPage> createState() => _OperitWaifuPageState();
}

class _OperitWaifuPageState extends State<OperitWaifuPage> {
  bool _waifuEnabled = false;
  double _replyDelay = 1.2;
  final _promptCtrl = TextEditingController(
    text: '你是一个可爱的二次元角色，请以温柔可爱的语气回复。',
  );

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waifu 模式')),
      body: ListView(
        padding: EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildGroup('基础设置', [
            SwitchListTile(
              title: const Text('启用 Waifu 模式', style: TextStyle(fontSize: 14)),
              subtitle: const Text('AI将以二次元角色的风格进行回复'),
              value: _waifuEnabled,
              onChanged: (v) => setState(() => _waifuEnabled = v),
              contentPadding: EdgeInsets.zero,
            ),
          ]),
          if (_waifuEnabled) ...[
            const SizedBox(height: UiTokens.sectionSpacing),
            _buildGroup('回复设置', [
              _buildSliderTile('回复延迟', _replyDelay, 0.5, 3.0, (v) {
                setState(() => _replyDelay = v);
              }),
            ]),
            const SizedBox(height: UiTokens.sectionSpacing),
            _buildGroup('自定义提示词', [
              const SizedBox(height: 4),
              TextField(
                controller: _promptCtrl,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: '输入自定义系统提示词...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(UiTokens.cardRadius),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(UiTokens.cardRadius),
                    borderSide: const BorderSide(color: UiTokens.primary),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ]),
          ],
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

  Widget _buildSliderTile(
    String label,
    double value,
    double min,
    double max,
    void Function(double) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 25,
              label: '${value.toStringAsFixed(1)}秒',
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${value.toStringAsFixed(1)}秒',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
