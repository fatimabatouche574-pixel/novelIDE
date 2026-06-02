import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

class OperitSkillDetailPage extends StatelessWidget {
  const OperitSkillDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('技能详情'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bookmark_border,
              size: UiTokens.quickIconSize,
            ),
            onPressed: () {},
            tooltip: '收藏',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(UiTokens.pagePadH),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildStatsRow(),
            const SizedBox(height: 20),
            _buildDescription(),
            const SizedBox(height: 20),
            _buildMetadataSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: UiTokens.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Icon(Icons.auto_awesome, size: 28, color: UiTokens.primary),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '文本智能总结',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: UiTokens.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '由 Operit Team 发布',
                style: TextStyle(
                  fontSize: UiTokens.smallFS,
                  color: UiTokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            // Install action
          },
          icon: const Icon(Icons.download, size: 16),
          label: const Text('安装'),
          style: FilledButton.styleFrom(
            backgroundColor: UiTokens.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UiTokens.cardRadius),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatItem(icon: Icons.download, label: '下载', value: '12.4K'),
        const SizedBox(width: 24),
        _StatItem(icon: Icons.thumb_up_outlined, label: '点赞', value: '856'),
        const SizedBox(width: 24),
        _StatItem(icon: Icons.star_outline, label: '评分', value: '4.8'),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '简介',
          style: TextStyle(
            fontSize: UiTokens.titleFS,
            fontWeight: FontWeight.w700,
            color: UiTokens.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '基于先进AI模型的文本智能总结技能。支持长文本摘要、'
          '要点提炼、多语言总结等多种模式。能够自动识别文本结构，'
          '生成结构化摘要，保留关键信息的同时大幅压缩文本长度。'
          '适用于文档处理、会议记录、新闻摘要等场景。',
          style: TextStyle(
            fontSize: UiTokens.bodyFS,
            color: UiTokens.onSurfaceVariant,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataSection() {
    return Card(
      elevation: 0,
      color: UiTokens.surfaceVariant.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiTokens.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '元数据',
              style: TextStyle(
                fontSize: UiTokens.titleFS,
                fontWeight: FontWeight.w700,
                color: UiTokens.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            _MetaRow(label: '版本', value: 'v2.1.0'),
            _MetaRow(label: '大小', value: '1.8 MB'),
            _MetaRow(label: '许可证', value: 'MIT'),
            _MetaRow(label: '兼容', value: 'Operit >= 2.0'),
            _MetaRow(label: '语言', value: 'Python 3.10+'),
            _MetaRow(label: '最后更新', value: '2026-05-28'),
            _MetaRow(label: '依赖', value: 'transformers, torch, numpy'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: UiTokens.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: UiTokens.smallFS,
            color: UiTokens.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: UiTokens.smallFS,
            fontWeight: FontWeight.w600,
            color: UiTokens.onSurface,
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: UiTokens.smallFS,
                color: UiTokens.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: UiTokens.smallFS,
                fontWeight: FontWeight.w500,
                color: UiTokens.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
