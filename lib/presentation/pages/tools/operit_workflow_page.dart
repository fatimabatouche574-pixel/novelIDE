import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

class OperitWorkflowPage extends StatelessWidget {
  const OperitWorkflowPage({super.key});

  static const _workflows = <_WorkflowData>[
    _WorkflowData(
      icon: Icons.sort,
      name: '自动通知排序',
      description: '根据优先级自动排列系统通知，确保重要消息不被遗漏',
      enabled: true,
      trigger: '新通知到达时触发',
      lastRun: '2分钟前',
    ),
    _WorkflowData(
      icon: Icons.email_outlined,
      name: '邮件摘要',
      description: '每日定时生成收件箱摘要，汇总未读邮件要点',
      enabled: true,
      trigger: '每日 08:00 自动执行',
      lastRun: '3小时前',
    ),
    _WorkflowData(
      icon: Icons.language,
      name: '网页爬虫',
      description: '定时抓取指定网页内容，检测更新并推送通知',
      enabled: false,
      trigger: '每6小时检查一次',
      lastRun: '从未运行',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('工作流管理'), centerTitle: true),
      body: ListView.separated(
        padding: const EdgeInsets.all(UiTokens.pagePadH),
        itemCount: _workflows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final wf = _workflows[index];
          return _WorkflowCard(workflow: wf);
        },
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({required this.workflow});

  final _WorkflowData workflow;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiTokens.cardRadius),
        side: BorderSide(color: UiTokens.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: workflow.enabled
                        ? UiTokens.greenSuccess.withValues(alpha: 0.1)
                        : UiTokens.onSurfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    workflow.icon,
                    size: UiTokens.quickIconSize + 4,
                    color: workflow.enabled
                        ? UiTokens.greenSuccess
                        : UiTokens.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              workflow.name,
                              style: TextStyle(
                                fontSize: UiTokens.titleFS,
                                fontWeight: FontWeight.w600,
                                color: UiTokens.onSurface,
                              ),
                            ),
                          ),
                          _StatusBadge(enabled: workflow.enabled),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workflow.description,
                        style: TextStyle(
                          fontSize: UiTokens.smallFS,
                          color: UiTokens.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              color: UiTokens.outlineVariant.withValues(alpha: 0.4),
              height: 1,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 13,
                  color: UiTokens.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  workflow.trigger,
                  style: TextStyle(
                    fontSize: UiTokens.microFS,
                    color: UiTokens.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  '上次: ${workflow.lastRun}',
                  style: TextStyle(
                    fontSize: UiTokens.tinyFS,
                    color: UiTokens.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: enabled
            ? UiTokens.greenSuccess.withValues(alpha: 0.1)
            : UiTokens.onSurfaceVariant.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? UiTokens.greenSuccess.withValues(alpha: 0.3)
              : UiTokens.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        enabled ? '已启用' : '已停用',
        style: TextStyle(
          fontSize: UiTokens.tinyFS,
          fontWeight: FontWeight.w600,
          color: enabled ? UiTokens.greenSuccess : UiTokens.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _WorkflowData {
  final IconData icon;
  final String name;
  final String description;
  final bool enabled;
  final String trigger;
  final String lastRun;

  const _WorkflowData({
    required this.icon,
    required this.name,
    required this.description,
    required this.enabled,
    required this.trigger,
    required this.lastRun,
  });
}
