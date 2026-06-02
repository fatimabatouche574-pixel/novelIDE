import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

class OperitLogViewerPage extends StatelessWidget {
  const OperitLogViewerPage({super.key});

  static const _logs = <_LogEntry>[
    _LogEntry(level: 'I', time: '10:30:01', message: 'Operit 系统启动完成'),
    _LogEntry(level: 'I', time: '10:30:02', message: '加载配置文件: config.yaml'),
    _LogEntry(
      level: 'I',
      time: '10:30:03',
      message: '已连接数据库: operit.db (SQLite 3.42)',
    ),
    _LogEntry(level: 'W', time: '10:30:12', message: '内存使用率超过 80%，建议清理'),
    _LogEntry(
      level: 'I',
      time: '10:31:05',
      message: 'AutoGLM 模型加载完成 (耗时: 3.2s)',
    ),
    _LogEntry(
      level: 'W',
      time: '10:32:18',
      message: '网络连接超时: api.openai.com (重试中…)',
    ),
    _LogEntry(level: 'I', time: '10:32:20', message: '重连成功，延迟: 145ms'),
    _LogEntry(
      level: 'E',
      time: '10:35:44',
      message: '文件写入失败: /data/output/report.json (权限不足)',
    ),
    _LogEntry(
      level: 'I',
      time: '10:36:01',
      message: '工作流 "邮件摘要" 执行完成 (用时 12s)',
    ),
    _LogEntry(
      level: 'I',
      time: '10:38:30',
      message: 'Token 使用量更新: 1,204 / 10,000',
    ),
    _LogEntry(
      level: 'W',
      time: '10:40:12',
      message: 'Shell 执行器返回非零退出码: exit code 127',
    ),
    _LogEntry(
      level: 'E',
      time: '10:42:55',
      message: 'TTS 引擎崩溃: 语音模型未找到 (model: zh-CN-XiaoxiaoNeural)',
    ),
    _LogEntry(
      level: 'I',
      time: '10:43:10',
      message: 'TTS 引擎已重启，备用模型: zh-CN-YunxiNeural',
    ),
  ];

  Color _levelColor(String level) {
    switch (level) {
      case 'E':
        return UiTokens.error;
      case 'W':
        return const Color(0xFFF5A623);
      case 'I':
        return const Color(0xFF4A90D9);
      default:
        return UiTokens.sidebarText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiTokens.sidebarBg,
      appBar: AppBar(
        backgroundColor: UiTokens.sidebarBg,
        foregroundColor: UiTokens.sidebarText,
        title: const Text('日志查看器'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: UiTokens.quickIconSize,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('日志已清空'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: '清空日志',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: UiTokens.pagePadH,
          vertical: 8,
        ),
        itemCount: _logs.length,
        itemBuilder: (context, index) {
          final log = _logs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _levelColor(log.level).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    log.level,
                    style: TextStyle(
                      fontSize: UiTokens.tinyFS,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: _levelColor(log.level),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  log.time,
                  style: TextStyle(
                    fontSize: UiTokens.tinyFS,
                    fontFamily: 'monospace',
                    color: UiTokens.sidebarHover,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    log.message,
                    style: TextStyle(
                      fontSize: UiTokens.smallFS,
                      fontFamily: 'monospace',
                      color: UiTokens.sidebarText,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LogEntry {
  final String level;
  final String time;
  final String message;

  const _LogEntry({
    required this.level,
    required this.time,
    required this.message,
  });
}
