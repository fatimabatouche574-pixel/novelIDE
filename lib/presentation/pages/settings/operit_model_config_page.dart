import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 模型参数配置页 — Temperature/TopP/MaxTokens等参数开关
class OperitModelConfigPage extends StatefulWidget {
  const OperitModelConfigPage({super.key});

  @override
  State<OperitModelConfigPage> createState() =>
      _OperitModelConfigPageState();
}

class _OperitModelConfigPageState extends State<OperitModelConfigPage> {
  final _params = <String, _ParamValue>{
    'Temperature': _ParamValue(0.7, 0.0, 2.0),
    'TopP': _ParamValue(0.9, 0.0, 1.0),
    'MaxTokens': _ParamValue(4096, 256, 32768),
    'FrequencyPenalty': _ParamValue(0.0, -2.0, 2.0),
    'PresencePenalty': _ParamValue(0.0, -2.0, 2.0),
  };

  bool _streamEnabled = true;
  bool _contextWindowAuto = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模型参数')),
      body: ListView(
        padding: EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildGroup(
            '推理参数',
            _params.entries.map((entry) {
              return _buildSliderTile(entry.key, entry.value);
            }).toList(),
          ),
          const SizedBox(height: UiTokens.sectionSpacing),
          _buildGroup('高级选项', [
            SwitchListTile(
              title: const Text('流式输出', style: TextStyle(fontSize: 14)),
              subtitle: const Text('启用流式传输响应'),
              value: _streamEnabled,
              onChanged: (v) => setState(() => _streamEnabled = v),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('自动上下文窗口', style: TextStyle(fontSize: 14)),
              subtitle: const Text('根据模型自动调整上下文窗口大小'),
              value: _contextWindowAuto,
              onChanged: (v) => setState(() => _contextWindowAuto = v),
              contentPadding: EdgeInsets.zero,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSliderTile(String label, _ParamValue param) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Slider(
              value: param.value,
              min: param.min,
              max: param.max,
              divisions: param.isInt ? null : 20,
              label: param.displayValue,
              onChanged: (v) {
                setState(() => param.value = v);
              },
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              param.displayValue,
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

class _ParamValue {
  double value;
  final double min;
  final double max;
  final bool isInt;

  _ParamValue(this.value, this.min, this.max) : isInt = max > 1000;

  String get displayValue {
    if (isInt) return '${value.toInt()}';
    return value.toStringAsFixed(2);
  }
}
