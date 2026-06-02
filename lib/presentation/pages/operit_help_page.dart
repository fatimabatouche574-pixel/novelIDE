import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// Simple help page with centered icon and text.
class OperitHelpPage extends StatelessWidget {
  const OperitHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('帮助')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline,
                size: 80,
                color: UiTokens.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 24),
              const Text(
                '帮助中心',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '如需帮助，请查阅以下资源：',
                style: TextStyle(
                  fontSize: UiTokens.bodyFS,
                  color: UiTokens.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _buildHelpItem(Icons.menu_book, '使用手册', '查看完整的功能使用指南'),
              const SizedBox(height: 8),
              _buildHelpItem(Icons.videocam, '视频教程', '观看操作演示视频'),
              const SizedBox(height: 8),
              _buildHelpItem(Icons.question_answer, '常见问题', 'FAQ 常见问题解答'),
              const SizedBox(height: 8),
              _buildHelpItem(Icons.mail_outline, '联系支持', '发送邮件至 support@novelide.com'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String subtitle) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon, color: UiTokens.primary),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: UiTokens.smallFS),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () {},
      ),
    );
  }
}
