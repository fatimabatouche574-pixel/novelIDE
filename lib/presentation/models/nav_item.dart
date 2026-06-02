import 'package:flutter/material.dart';

/// NovelIDE 侧边栏导航项定义
class NavItem {
  final String route;
  final String title;
  final IconData icon;

  const NavItem({
    required this.route,
    required this.title,
    required this.icon,
  });

  // ── 写作功能区 ──
  static const writing = NavItem(route: 'writing', title: '写作', icon: Icons.edit_note);
  static const workspace = NavItem(route: 'workspace', title: '工作树', icon: Icons.explore_outlined);
  static const materials = NavItem(route: 'materials', title: '资料库', icon: Icons.folder_outlined);
  static const globalSearch = NavItem(route: 'global_search', title: '全局搜索', icon: Icons.search);

  // ── AI 功能区 ──
  static const aiChat = NavItem(route: 'ai_chat', title: 'AI 对话', icon: Icons.chat_bubble_outline);
  static const memory = NavItem(route: 'memory', title: '记忆库', icon: Icons.psychology);
  static const skills = NavItem(route: 'skills', title: '技能管理', icon: Icons.auto_awesome);
  static const agentMarket = NavItem(route: 'agent_market', title: 'Agent 市场', icon: Icons.store);

  // ── 系统 ──
  static const settings = NavItem(route: 'settings', title: '设置', icon: Icons.settings);
  static const profile = NavItem(route: 'profile', title: '个人配置', icon: Icons.person);
  static const about = NavItem(route: 'about', title: '关于', icon: Icons.info_outline);

  // ── 写作功能分组 ──
  static const writeGroup = [writing, workspace, materials, globalSearch];
  // ── AI 功能分组 ──
  static const aiGroup = [aiChat, memory, skills, agentMarket];
  // ── 系统分组 ──
  static const systemGroup = [settings, profile, about];

  // ── 快捷操作数据 ──
  static const quickActions = [
    _QuickAction(Icons.edit, '写作进度', '5章'),
    _QuickAction(Icons.psychology, '记忆库', '32条'),
    _QuickAction(Icons.book, '作品', '3部'),
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NavItem && route == other.route;

  @override
  int get hashCode => route.hashCode;
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String badge;
  const _QuickAction(this.icon, this.label, this.badge);
}
