import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 系统提示词页 — 角色卡/标签/群组 Tab
class OperitPromptsPage extends StatefulWidget {
  const OperitPromptsPage({super.key});

  @override
  State<OperitPromptsPage> createState() => _OperitPromptsPageState();
}

class _OperitPromptsPageState extends State<OperitPromptsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['角色卡', '标签', '群组'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('系统提示词'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPersonasTab(),
          _buildTagsTab(),
          _buildGroupsTab(),
        ],
      ),
    );
  }

  Widget _buildPersonasTab() {
    return ListView(
      padding: EdgeInsets.all(UiTokens.pagePadH),
      children: [
        _buildPersonaCard(
          icon: '\u{1F916}',
          name: '通用助手',
          desc: '友好、乐于助人的AI助手',
          active: true,
        ),
        _buildPersonaCard(
          icon: '\u{1F9D9}',
          name: '代码大师',
          desc: '精通各种编程语言的技术专家',
          active: false,
        ),
        _buildPersonaCard(
          icon: '\u{1F4DA}',
          name: '写作顾问',
          desc: '帮助润色和优化文字表达',
          active: false,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text('添加角色卡'),
        ),
      ],
    );
  }

  Widget _buildPersonaCard({
    required String icon,
    required String name,
    required String desc,
    required bool active,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiTokens.cardRadius),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active
                ? UiTokens.primary.withValues(alpha: 0.1)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 22)),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: Switch(value: active, onChanged: (_) {}),
      ),
    );
  }

  Widget _buildTagsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.label_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('标签管理', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text('群组管理', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}
