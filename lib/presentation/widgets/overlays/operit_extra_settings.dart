import 'package:flutter/material.dart';

/// 额外设置弹出面板 — 记忆偏好 / 工具权限 / 行为开关 / 插件
class OperitExtraSettings extends StatefulWidget {
  const OperitExtraSettings({
    super.key,
    this.memoryPreference = '自动关联',
    this.toolPermission = '询问',
    this.streamingDisabled = false,
    this.autoReadEnabled = true,
    this.pluginsEnabled = 3,
    this.pluginsTotal = 5,
    required this.onMemoryPrefChanged,
    required this.onToolPermChanged,
    required this.onStreamingChanged,
    required this.onAutoReadChanged,
  });

  final String memoryPreference;
  final String toolPermission;
  final bool streamingDisabled;
  final bool autoReadEnabled;
  final int pluginsEnabled;
  final int pluginsTotal;
  final void Function(String) onMemoryPrefChanged;
  final void Function(String) onToolPermChanged;
  final void Function(bool) onStreamingChanged;
  final void Function(bool) onAutoReadChanged;

  static void show(
    BuildContext context, {
    String memoryPreference = '自动关联',
    String toolPermission = '询问',
    bool streamingDisabled = false,
    bool autoReadEnabled = true,
    int pluginsEnabled = 3,
    int pluginsTotal = 5,
    required void Function(String) onMemoryPrefChanged,
    required void Function(String) onToolPermChanged,
    required void Function(bool) onStreamingChanged,
    required void Function(bool) onAutoReadChanged,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OperitExtraSettings(
        memoryPreference: memoryPreference,
        toolPermission: toolPermission,
        streamingDisabled: streamingDisabled,
        autoReadEnabled: autoReadEnabled,
        pluginsEnabled: pluginsEnabled,
        pluginsTotal: pluginsTotal,
        onMemoryPrefChanged: onMemoryPrefChanged,
        onToolPermChanged: onToolPermChanged,
        onStreamingChanged: onStreamingChanged,
        onAutoReadChanged: onAutoReadChanged,
      ),
    );
  }

  @override
  State<OperitExtraSettings> createState() => _OperitExtraSettingsState();
}

class _OperitExtraSettingsState extends State<OperitExtraSettings> {
  late String _memoryPref;
  late String _toolPermission;
  late bool _streamingDisabled;
  late bool _autoRead;

  static const _memoryOptions = ['关闭', '手动关联', '自动关联'];
  static const _toolPermOptions = ['拒绝', '询问', '允许'];

  @override
  void initState() {
    super.initState();
    _memoryPref = widget.memoryPreference;
    _toolPermission = widget.toolPermission;
    _streamingDisabled = widget.streamingDisabled;
    _autoRead = widget.autoReadEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '额外设置',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            // 记忆偏好
            _buildDropdownSection('记忆偏好', _memoryPref, _memoryOptions, (
              v,
            ) {
              setState(() => _memoryPref = v);
              widget.onMemoryPrefChanged(v);
            }),
            const Divider(indent: 20, endIndent: 20),
            // 工具权限
            _buildRadioSection('工具权限', _toolPermission, _toolPermOptions, (
              v,
            ) {
              setState(() => _toolPermission = v);
              widget.onToolPermChanged(v);
            }),
            const Divider(indent: 20, endIndent: 20),
            // 行为开关
            _buildToggleSection('禁用流式输出', _streamingDisabled, (v) {
              setState(() => _streamingDisabled = v);
              widget.onStreamingChanged(v);
            }),
            _buildToggleSection('自动阅读', _autoRead, (v) {
              setState(() => _autoRead = v);
              widget.onAutoReadChanged(v);
            }),
            const Divider(indent: 20, endIndent: 20),
            // 插件
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.extension, size: 20),
                  const SizedBox(width: 12),
                  const Text('插件', style: TextStyle(fontSize: 15)),
                  const Spacer(),
                  Text(
                    '${widget.pluginsEnabled}/${widget.pluginsTotal} 已启用',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSection(
    String title,
    String value,
    List<String> options,
    void Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            items:
                options
                    .map(
                      (o) => DropdownMenuItem(value: o, child: Text(o)),
                    )
                    .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRadioSection(
    String title,
    String value,
    List<String> options,
    void Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 4),
          Row(
            children:
                options.map((o) {
                  return Row(
                    children: [
                      Radio<String>(
                        value: o,
                        groupValue: value,
                        onChanged: (v) {
                          if (v != null) onChanged(v);
                        },
                      ),
                      Text(o, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                    ],
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSection(
    String title,
    bool value,
    void Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
