import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 18个工具的网格页面
class OperitToolboxPage extends StatelessWidget {
  const OperitToolboxPage({super.key});

  static const _tools = <_ToolItem>[
    _ToolItem(emoji: '🧪', name: '工具测试中心'),
    _ToolItem(emoji: '📁', name: '文件管理器'),
    _ToolItem(emoji: '🔊', name: 'TTS'),
    _ToolItem(emoji: '🎤', name: '语音识别'),
    _ToolItem(emoji: '🔐', name: '权限管理'),
    _ToolItem(emoji: '📋', name: '用户协议'),
    _ToolItem(emoji: '🤖', name: '默认助手引导'),
    _ToolItem(emoji: '💻', name: '终端'),
    _ToolItem(emoji: '🐛', name: 'UI调试'),
    _ToolItem(emoji: '🎬', name: 'FFmpeg工具箱'),
    _ToolItem(emoji: '⚡', name: 'Shell执行器'),
    _ToolItem(emoji: '📜', name: '日志查看器'),
    _ToolItem(emoji: '🗄️', name: 'SQL查看器'),
    _ToolItem(emoji: '🔑', name: 'Token配置'),
    _ToolItem(emoji: '🔓', name: '进程限制解锁'),
    _ToolItem(emoji: '📦', name: 'HTML打包器'),
    _ToolItem(emoji: '🚀', name: 'AutoGLM一键'),
    _ToolItem(emoji: '🛠️', name: 'AutoGLM工具'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operit 工具箱'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(UiTokens.pagePadH),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
          ),
          itemCount: _tools.length,
          itemBuilder: (context, index) => _ToolCard(tool: _tools[index]),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});

  final _ToolItem tool;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiTokens.cardRadius),
        side: BorderSide(color: UiTokens.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(UiTokens.cardRadius),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('打开: ${tool.name}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tool.emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              Text(
                tool.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: UiTokens.bodyFS,
                  fontWeight: FontWeight.w500,
                  color: UiTokens.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolItem {
  final String emoji;
  final String name;

  const _ToolItem({required this.emoji, required this.name});
}
