import 'package:flutter/material.dart';

/// 模型选择器 — 思维设置 + 模型列表 + 管理配置链接
class OperitModelSelector extends StatefulWidget {
  const OperitModelSelector({
    super.key,
    this.selectedModel = 'Claude-4-Sonnet',
    required this.onModelChanged,
  });

  final String selectedModel;
  final void Function(String model) onModelChanged;

  /// 以对话框形式显示
  static void show(
    BuildContext context, {
    String selectedModel = 'Claude-4-Sonnet',
    required void Function(String model) onModelChanged,
  }) {
    showDialog<void>(
      context: context,
      builder:
          (_) => OperitModelSelector(
            selectedModel: selectedModel,
            onModelChanged: onModelChanged,
          ),
    );
  }

  @override
  State<OperitModelSelector> createState() => _OperitModelSelectorState();
}

class _OperitModelSelectorState extends State<OperitModelSelector> {
  late String _selected;
  bool _thinkingEnabled = true;
  double _quality = 0.8;

  static const _models = [
    'Claude-4-Sonnet',
    'GPT-4o',
    'Gemini-2.5',
    'DeepSeek-V3',
    'Local MNN',
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedModel;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  const Text(
                    '模型设置',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // 思维设置
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '思维设置',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('扩展思考', style: TextStyle(fontSize: 14)),
                      const Spacer(),
                      Switch(
                        value: _thinkingEnabled,
                        onChanged: (v) => setState(() => _thinkingEnabled = v),
                      ),
                    ],
                  ),
                  if (_thinkingEnabled) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('思考质量', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Slider(
                            value: _quality,
                            min: 0.1,
                            max: 1.0,
                            divisions: 9,
                            label: '${(_quality * 100).toInt()}%',
                            onChanged: (
                              v,
                            ) => setState(() => _quality = v),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '${(_quality * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),
            // 模型列表
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '选择模型',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            ..._models.map(
              (model) => RadioListTile<String>(
                title: Text(model, style: const TextStyle(fontSize: 14)),
                value: model,
                groupValue: _selected,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                dense: true,
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selected = v);
                    widget.onModelChanged(v);
                  }
                },
              ),
            ),
            // 管理配置链接
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings, size: 16, color: Colors.blue),
                    SizedBox(width: 6),
                    Text(
                      '管理配置',
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
