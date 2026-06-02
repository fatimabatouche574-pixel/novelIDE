import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// About page with version info and links.
class OperitAboutPage extends StatelessWidget {
  const OperitAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        padding: const EdgeInsets.all(UiTokens.pagePadH),
        children: [
          // Logo & app name
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: UiTokens.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'O',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'NovelIDE',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'v2.4.0 (Build 240)',
                  style: TextStyle(
                    fontSize: UiTokens.bodyFS,
                    color: UiTokens.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '面向网络小说作者的全流程单机写作工具',
                  style: TextStyle(
                    fontSize: UiTokens.smallFS,
                    color: UiTokens.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Settings items
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: '版本信息',
            subtitle: 'v2.4.0 (Build 240) — Flutter 3.x',
          ),
          _buildSettingsItem(
            icon: Icons.system_update,
            title: '检查更新',
            subtitle: '当前已是最新版本',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已是最新版本')),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.history,
            title: '更新历史',
            subtitle: '查看版本更新记录',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.code,
            title: 'GitHub',
            subtitle: 'github.com/novelide/novelide',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.group,
            title: '社区',
            subtitle: '加入用户交流群',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.gavel,
            title: '开源协议',
            subtitle: 'Apache 2.0',
            onTap: () {},
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Made with Flutter & Dart',
              style: TextStyle(
                fontSize: UiTokens.microFS,
                color: UiTokens.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: UiTokens.primary),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: UiTokens.smallFS),
      ),
      trailing: onTap != null ? const Icon(Icons.chevron_right, size: 20) : null,
      onTap: onTap,
    );
  }
}
