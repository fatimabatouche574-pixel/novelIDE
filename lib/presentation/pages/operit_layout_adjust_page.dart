import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// Layout adjustment settings page.
class OperitLayoutAdjustPage extends StatefulWidget {
  const OperitLayoutAdjustPage({super.key});

  @override
  State<OperitLayoutAdjustPage> createState() =>
      _OperitLayoutAdjustPageState();
}

class _OperitLayoutAdjustPageState
    extends State<OperitLayoutAdjustPage> {
  String _marginSize = '16';
  double _fontSizePercent = 100;
  String _lineHeight = '1.6';
  double _bubbleMaxWidth = 80;
  String _inputStyle = '圆角';

  static const _marginOptions = ['8', '12', '16', '20', '24'];
  static const _lineHeightOptions = ['1.2', '1.4', '1.6', '1.8', '2.0'];
  static const _inputStyles = ['圆角', '方角', '下划线', '填充'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('界面布局调整')),
      body: ListView(
        padding: const EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildSectionTitle('间距'),
          _buildDropdownTile(
            icon: Icons.space_bar,
            title: '边距大小',
            value: '$_marginSize px',
            onTap: () => _showOptionSheet(
              '边距大小',
              _marginOptions,
              _marginSize,
              (v) => setState(() => _marginSize = v),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),

          _buildSectionTitle('字体'),
          _buildSliderTile(
            icon: Icons.format_size,
            title: '字号比例',
            value: '${_fontSizePercent.toInt()}%',
            child: Slider(
              value: _fontSizePercent,
              min: 80,
              max: 150,
              divisions: 14,
              label: '${_fontSizePercent.toInt()}%',
              onChanged: (v) => setState(() => _fontSizePercent = v),
            ),
          ),
          _buildDropdownTile(
            icon: Icons.format_line_spacing,
            title: '行高',
            value: _lineHeight,
            onTap: () => _showOptionSheet(
              '行高',
              _lineHeightOptions,
              _lineHeight,
              (v) => setState(() => _lineHeight = v),
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 16),

          _buildSectionTitle('气泡'),
          _buildSliderTile(
            icon: Icons.chat_bubble_outline,
            title: '气泡最大宽度',
            value: '${_bubbleMaxWidth.toInt()}%',
            child: Slider(
              value: _bubbleMaxWidth,
              min: 50,
              max: 100,
              divisions: 10,
              label: '${_bubbleMaxWidth.toInt()}%',
              onChanged: (v) => setState(() => _bubbleMaxWidth = v),
            ),
          ),
          _buildDropdownTile(
            icon: Icons.edit,
            title: '输入框样式',
            value: _inputStyle,
            onTap: () => _showOptionSheet(
              '输入框样式',
              _inputStyles,
              _inputStyle,
              (v) => setState(() => _inputStyle = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: UiTokens.smallFS,
          fontWeight: FontWeight.bold,
          color: UiTokens.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: UiTokens.bodyFS,
              color: UiTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required String value,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Text(
            value,
            style: const TextStyle(
              fontSize: UiTokens.bodyFS,
              color: UiTokens.onSurfaceVariant,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ],
    );
  }

  void _showOptionSheet(
    String title,
    List<String> options,
    String current,
    ValueChanged<String> onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: UiTokens.titleFS,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...options.map((option) {
              final selected = option == current;
              return ListTile(
                title: Text(option),
                trailing: selected
                    ? const Icon(Icons.check, color: UiTokens.primary)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  onSelected(option);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
