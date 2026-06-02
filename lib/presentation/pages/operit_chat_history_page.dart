import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// Chat history management page.
class OperitChatHistoryPage extends StatefulWidget {
  const OperitChatHistoryPage({super.key});

  @override
  State<OperitChatHistoryPage> createState() =>
      _OperitChatHistoryPageState();
}

class _OperitChatHistoryPageState extends State<OperitChatHistoryPage> {
  final Set<int> _selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('对话历史'),
        actions: [
          if (_selectedIndices.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '删除选中',
              onPressed: _deleteSelected,
            ),
          TextButton(
            onPressed: () {
              setState(() {
                if (_selectedIndices.length == _mockCharacters.length) {
                  _selectedIndices.clear();
                } else {
                  _selectedIndices.addAll(
                    List.generate(_mockCharacters.length, (i) => i),
                  );
                }
              });
            },
            child: Text(
              _selectedIndices.length == _mockCharacters.length
                  ? '取消全选'
                  : '全选',
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(UiTokens.pagePadH),
        children: [
          // Stats overview
          _buildStatsOverview(),
          const SizedBox(height: 16),
          // Character stats
          _buildSectionTitle('角色统计'),
          ..._mockCharacters.asMap().entries.map((entry) {
            final index = entry.key;
            final char = entry.value;
            return _buildCharacterCard(index, char);
          }),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '总体统计',
              style: TextStyle(
                fontSize: UiTokens.titleFS,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem('对话数', '1,248'),
                _buildStatItem('消息数', '12,847'),
                _buildStatItem('Token', '8.4M'),
                _buildStatItem('费用', '¥52.18'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: UiTokens.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: UiTokens.smallFS,
              color: UiTokens.onSurfaceVariant,
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

  Widget _buildCharacterCard(int index, _CharacterStats char) {
    final selected = _selectedIndices.contains(index);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected ? UiTokens.primaryContainer : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: UiTokens.primary,
          child: Text(
            char.name[0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(char.name),
        subtitle: Text(
          '${char.conversations} 对话  ·  ${char.messages} 消息  ·  ${char.tokens} Token',
          style: const TextStyle(fontSize: UiTokens.smallFS),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              char.cost,
              style: const TextStyle(
                fontSize: UiTokens.bodyFS,
                color: UiTokens.onSurfaceVariant,
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedIndices.add(index);
                  } else {
                    _selectedIndices.remove(index);
                  }
                });
              },
            ),
          ],
        ),
        onTap: () {
          setState(() {
            if (selected) {
              _selectedIndices.remove(index);
            } else {
              _selectedIndices.add(index);
            }
          });
        },
      ),
    );
  }

  void _deleteSelected() {
    if (_selectedIndices.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除对话历史'),
        content: Text('确定要删除选中的 ${_selectedIndices.length} 条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: UiTokens.error),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _selectedIndices.clear());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已删除选中记录')),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _CharacterStats {
  final String name;
  final int conversations;
  final int messages;
  final String tokens;
  final String cost;

  const _CharacterStats({
    required this.name,
    required this.conversations,
    required this.messages,
    required this.tokens,
    required this.cost,
  });
}

const _mockCharacters = [
  _CharacterStats(
    name: '写作助手',
    conversations: 586,
    messages: 5200,
    tokens: '2.3M',
    cost: '¥18.42',
  ),
  _CharacterStats(
    name: '大纲生成器',
    conversations: 312,
    messages: 3800,
    tokens: '1.8M',
    cost: '¥14.56',
  ),
  _CharacterStats(
    name: '校对助手',
    conversations: 200,
    messages: 2200,
    tokens: '0.9M',
    cost: '¥7.20',
  ),
  _CharacterStats(
    name: '角色设计师',
    conversations: 150,
    messages: 1647,
    tokens: '0.6M',
    cost: '¥4.80',
  ),
];
