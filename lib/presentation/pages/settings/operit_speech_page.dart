import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 语音设置页 — TTS + STT 服务类型/语速/音调/音色
class OperitSpeechPage extends StatefulWidget {
  const OperitSpeechPage({super.key});

  @override
  State<OperitSpeechPage> createState() => _OperitSpeechPageState();
}

class _OperitSpeechPageState extends State<OperitSpeechPage> {
  String _ttsService = 'Azure';
  String _sttService = 'Whisper';
  double _speed = 1.0;
  double _pitch = 1.0;
  String _voice = 'zh-CN-XiaoxiaoNeural';

  static const _ttsOptions = ['Azure', 'Edge', 'System'];
  static const _sttOptions = ['Whisper', 'Azure', 'System'];
  static const _voiceOptions = [
    'zh-CN-XiaoxiaoNeural',
    'zh-CN-YunxiNeural',
    'zh-CN-XiaoyiNeural',
    'zh-TW-HsiaoChenNeural',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('语音设置')),
      body: ListView(
        padding: EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildGroup('语音合成 (TTS)', [
            _buildDropdownTile('服务类型', _ttsService, _ttsOptions, (v) {
              setState(() => _ttsService = v);
            }),
            _buildSliderTile('语速', _speed, 0.5, 2.0, (v) {
              setState(() => _speed = v);
            }),
            _buildSliderTile('音调', _pitch, 0.5, 2.0, (v) {
              setState(() => _pitch = v);
            }),
            _buildDropdownTile('音色', _voice, _voiceOptions, (v) {
              setState(() => _voice = v);
            }),
          ]),
          const SizedBox(height: UiTokens.sectionSpacing),
          _buildGroup('语音识别 (STT)', [
            _buildDropdownTile('识别引擎', _sttService, _sttOptions, (v) {
              setState(() => _sttService = v);
            }),
            SwitchListTile(
              title: const Text('自动检测语言', style: TextStyle(fontSize: 14)),
              value: true,
              onChanged: (_) {},
              contentPadding: EdgeInsets.zero,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String label,
    String value,
    List<String> options,
    void Function(String) onChanged,
  ) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        isDense: true,
        items:
            options
                .map((o) => DropdownMenuItem(
                  value: o,
                  child: Text(o, style: const TextStyle(fontSize: 12)),
                ))
                .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
      contentPadding: EdgeInsets.zero,
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
            width: 60,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 15,
              label: value.toStringAsFixed(1),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
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
