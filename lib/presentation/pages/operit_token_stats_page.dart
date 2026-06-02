import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// Token usage statistics page.
class OperitTokenStatsPage extends StatelessWidget {
  const OperitTokenStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Token 统计')),
      body: ListView(
        padding: const EdgeInsets.all(UiTokens.pagePadH),
        children: [
          // Top stat cards
          _buildStatCardsRow(),
          const SizedBox(height: 16),

          // Model distribution bar
          _buildSectionTitle('模型分布'),
          _buildModelDistribution(),
          const SizedBox(height: 16),

          // Detailed model cards
          _buildSectionTitle('模型详情'),
          ..._modelDetails.map(_buildModelDetailCard),
        ],
      ),
    );
  }

  Widget _buildStatCardsRow() {
    return Row(
      children: [
        _buildStatCard('对话数', '128', Icons.chat_bubble_outline, UiTokens.primary),
        const SizedBox(width: 8),
        _buildStatCard('消息数', '1,847', Icons.message_outlined, UiTokens.secondary),
        const SizedBox(width: 8),
        _buildStatCard('Token', '2.4M', Icons.token, UiTokens.tertiary),
        const SizedBox(width: 8),
        _buildStatCard('费用', '¥18.56', Icons.attach_money, UiTokens.greenSuccess),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: UiTokens.microFS,
                  color: UiTokens.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildModelDistribution() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 20,
                child: Row(
                  children: [
                    _buildBarSegment(0.55, const Color(0xFF6C5CE7)),
                    _buildBarSegment(0.25, const Color(0xFF00B894)),
                    _buildBarSegment(0.12, const Color(0xFF0984E3)),
                    _buildBarSegment(0.08, Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildLegendItem(
              'Claude-4-Sonnet',
              '55%',
              const Color(0xFF6C5CE7),
            ),
            _buildLegendItem('GPT-4o', '25%', const Color(0xFF00B894)),
            _buildLegendItem('Gemini-2.5', '12%', const Color(0xFF0984E3)),
            _buildLegendItem('其他', '8%', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBarSegment(double fraction, Color color) {
    return Expanded(flex: (fraction * 100).round(), child: Container(color: color));
  }

  Widget _buildLegendItem(String label, String percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: UiTokens.bodyFS)),
          ),
          Text(
            percent,
            style: const TextStyle(
              fontSize: UiTokens.bodyFS,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelDetailCard(_ModelDetail detail) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: detail.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detail.name,
                    style: const TextStyle(
                      fontSize: UiTokens.bodyFS,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  detail.percent,
                  style: TextStyle(
                    fontSize: UiTokens.smallFS,
                    color: detail.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                _buildDetailItem('调用次数', detail.callCount),
                _buildDetailItem('输入Token', detail.inputTokens),
                _buildDetailItem('输出Token', detail.outputTokens),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDetailItem('累计费用', detail.cost),
                _buildDetailItem('平均响应', detail.avgResponse),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: UiTokens.microFS,
              color: UiTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: UiTokens.bodyFS,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelDetail {
  final String name;
  final String percent;
  final Color color;
  final String callCount;
  final String inputTokens;
  final String outputTokens;
  final String cost;
  final String avgResponse;

  const _ModelDetail({
    required this.name,
    required this.percent,
    required this.color,
    required this.callCount,
    required this.inputTokens,
    required this.outputTokens,
    required this.cost,
    required this.avgResponse,
  });
}

const _modelDetails = [
  _ModelDetail(name: 'Claude-4-Sonnet', percent: '55%', color: Color(0xFF6C5CE7), callCount: '1,024', inputTokens: '1.2M', outputTokens: '0.8M', cost: '¥10.20', avgResponse: '1.8s'),
  _ModelDetail(name: 'GPT-4o', percent: '25%', color: Color(0xFF00B894), callCount: '468', inputTokens: '0.6M', outputTokens: '0.4M', cost: '¥5.68', avgResponse: '2.1s'),
  _ModelDetail(name: 'Gemini-2.5', percent: '12%', color: Color(0xFF0984E3), callCount: '220', inputTokens: '0.3M', outputTokens: '0.15M', cost: '¥2.20', avgResponse: '2.5s'),
  _ModelDetail(name: '其他模型', percent: '8%', color: Colors.grey, callCount: '135', inputTokens: '0.15M', outputTokens: '0.08M', cost: '¥0.48', avgResponse: '3.2s'),
];
