import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// Global display settings page.
class OperitGlobalDisplayPage extends StatefulWidget {
  const OperitGlobalDisplayPage({super.key});

  @override
  State<OperitGlobalDisplayPage> createState() =>
      _OperitGlobalDisplayPageState();
}

class _OperitGlobalDisplayPageState
    extends State<OperitGlobalDisplayPage> {
  bool _notificationsEnabled = true;
  bool _animationsEnabled = true;
  bool _screenOn = false;
  bool _vibrationEnabled = true;
  bool _darkFollowSystem = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('显示设置')),
      body: ListView(
        padding: const EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildSectionTitle('通知与显示'),
          SwitchListTile(
            title: const Text('通知提醒'),
            subtitle: const Text('接收写作目标提醒和系统通知'),
            value: _notificationsEnabled,
            onChanged: (v) => setState(() => _notificationsEnabled = v),
          ),
          const Divider(height: 1),

          SwitchListTile(
            title: const Text('动画效果'),
            subtitle: const Text('启用界面过渡和交互动画'),
            value: _animationsEnabled,
            onChanged: (v) => setState(() => _animationsEnabled = v),
          ),
          const Divider(height: 1),

          SwitchListTile(
            title: const Text('保持屏幕常亮'),
            subtitle: const Text('写作时防止屏幕自动关闭'),
            value: _screenOn,
            onChanged: (v) => setState(() => _screenOn = v),
          ),
          const Divider(height: 1),

          SwitchListTile(
            title: const Text('振动反馈'),
            subtitle: const Text('按键和操作时的触觉反馈'),
            value: _vibrationEnabled,
            onChanged: (v) => setState(() => _vibrationEnabled = v),
          ),
          const Divider(height: 1),

          const SizedBox(height: 16),
          _buildSectionTitle('主题'),
          SwitchListTile(
            title: const Text('深色模式跟随系统'),
            subtitle: const Text('自动根据系统设置切换深色/浅色模式'),
            value: _darkFollowSystem,
            onChanged: (v) => setState(() => _darkFollowSystem = v),
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
}
