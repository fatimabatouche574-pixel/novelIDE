import 'package:flutter/material.dart';

/// 导航分组枚举
enum NavGroup {
  writing('写作功能区'),
  ai('AI功能区'),
  system('系统');

  final String label;
  const NavGroup(this.label);
}

/// NovelIDE 侧边栏导航项定义 - Operit 风格
class NavItem {
  final String id;
  final String label;
  final int iconCodepoint;
  final String route;
  final NavGroup group;

  const NavItem({
    required this.id,
    required this.label,
    required this.iconCodepoint,
    required this.route,
    required this.group,
  });

  IconData get icon => IconData(iconCodepoint, fontFamily: 'MaterialIcons');

  // ── AI功能区 ──
  static const aiChat = NavItem(
    id: 'ai_chat',
    label: 'AI聊天',
    iconCodepoint: 0xe0b7, // Icons.chat
    route: 'ai_chat',
    group: NavGroup.ai,
  );
  static const assistantConfig = NavItem(
    id: 'assistant_config',
    label: '助手配置',
    iconCodepoint: 0xe3ae, // Icons.smart_toy
    route: 'assistant_config',
    group: NavGroup.ai,
  );
  static const memory = NavItem(
    id: 'memory',
    label: '记忆库',
    iconCodepoint: 0xea87, // Icons.psychology
    route: 'memory',
    group: NavGroup.ai,
  );
  static const toolbox = NavItem(
    id: 'toolbox',
    label: '工具箱',
    iconCodepoint: 0xe1bd, // Icons.build
    route: 'toolbox',
    group: NavGroup.ai,
  );
  static const workflow = NavItem(
    id: 'workflow',
    label: '工作流',
    iconCodepoint: 0xe914, // Icons.account_tree
    route: 'workflow',
    group: NavGroup.ai,
  );
  static const packageManager = NavItem(
    id: 'package_manager',
    label: '包管理',
    iconCodepoint: 0xef4f, // Icons.inventory_2
    route: 'package_manager',
    group: NavGroup.ai,
  );
  static const tokenUsage = NavItem(
    id: 'token_usage',
    label: 'Token用量',
    iconCodepoint: 0xe227, // Icons.data_usage
    route: 'token_usage',
    group: NavGroup.ai,
  );

  // ── AI 功能分组 ──
  static const aiGroup = [aiChat, assistantConfig, memory, toolbox, workflow];

  // ── 快捷操作 ──
  static const quickActions = [
    _QuickAction(
      iconCodepoint: 0xef4f, // Icons.inventory_2
      label: '包管理',
      badge: '5',
      route: 'package_manager',
    ),
    _QuickAction(
      iconCodepoint: 0xe8b8, // Icons.admin_panel_settings
      label: '权限',
      badge: 'OK',
      route: 'tool_perm',
    ),
    _QuickAction(
      iconCodepoint: 0xe914, // Icons.account_tree
      label: '工作流',
      badge: '3',
      route: 'workflow',
    ),
  ];

  // ── 底部快捷 ──
  static const bottomShortcuts = [
    BottomShortcut(
      id: 'import',
      label: '导入',
      iconCodepoint: 0xe2c6, // Icons.file_upload
      route: 'import',
      group: NavGroup.system,
    ),
    BottomShortcut(
      id: 'export',
      label: '导出',
      iconCodepoint: 0xe2c7, // Icons.file_download
      route: 'export',
      group: NavGroup.system,
    ),
    BottomShortcut(
      id: 'settings',
      label: '设置',
      iconCodepoint: 0xe8b8, // Icons.settings
      route: 'settings',
      group: NavGroup.system,
    ),
  ];

  /// 所有导航项
  static const allItems = [
    aiChat,
    assistantConfig,
    memory,
    toolbox,
    workflow,
    packageManager,
    tokenUsage,
  ];

  /// 根据路由查找导航项
  static NavItem? findByRoute(String route) {
    for (final item in allItems) {
      if (item.route == route) return item;
    }
    for (final shortcut in bottomShortcuts) {
      if (shortcut.route == route) return shortcut.toNavItem();
    }
    return null;
  }

  /// 根据路由获取显示标题（含子页面）
  static String titleForRoute(String route) {
    final titles = <String, String>{
      'ai_chat': 'AI聊天',
      'assistant_config': '助手配置',
      'memory': '记忆库',
      'toolbox': '工具箱',
      'workflow': '工作流',
      'package_manager': '包管理',
      'token_usage': 'Token用量统计',
      'settings': '设置',
      'about': '关于',
      'help': '帮助',
      'import': '导入',
      'export': '导出',
      'theme': '主题外观',
      'user_prefs': '用户偏好',
      'language': '语言设置',
      'model_config': '模型参数',
      'functional_config': '功能模型',
      'speech': '语音服务',
      'prompts': '系统提示词',
      'waifu': 'Waifu模式',
      'persona_gen': '人设卡生成',
      'chat_history': '聊天记录管理',
      'global_display': '全局显示',
      'layout_adjust': '布局调整',
      'external_http': '外部HTTP聊天',
      'terminal': '终端',
      'log_viewer': '日志查看器',
      'file_manager': '文件管理器',
      'sql_viewer': 'SQL查看器',
      'skill_detail': '技能详情',
      'tool_perm': '工具权限',
      'backup': '数据备份',
      'context_summary': '上下文摘要',
      'market': '市场',
      'memory_library': '记忆库(图)',
      'memory_graph': '记忆图谱',
      'memory_list': '记忆列表',
      'global_search': '全局搜索',
    };
    final found = findByRoute(route);
    return found?.label ?? titles[route] ?? route;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NavItem && route == other.route;

  @override
  int get hashCode => route.hashCode;
}

/// 快捷操作卡片数据
class _QuickAction {
  final int iconCodepoint;
  final String label;
  final String badge;
  final String route;

  const _QuickAction({
    required this.iconCodepoint,
    required this.label,
    required this.badge,
    required this.route,
  });

  IconData get icon => IconData(iconCodepoint, fontFamily: 'MaterialIcons');

  /// 转换为 NavItem 用于导航回调
  NavItem toNavItem() => NavItem(
    id: route,
    label: label,
    iconCodepoint: iconCodepoint,
    route: route,
    group: NavGroup.ai,
  );
}

/// 底部快捷导航数据
class BottomShortcut {
  final String id;
  final String label;
  final int iconCodepoint;
  final String route;
  final NavGroup group;

  const BottomShortcut({
    required this.id,
    required this.label,
    required this.iconCodepoint,
    required this.route,
    required this.group,
  });

  IconData get icon => IconData(iconCodepoint, fontFamily: 'MaterialIcons');

  NavItem toNavItem() => NavItem(
    id: id,
    label: label,
    iconCodepoint: iconCodepoint,
    route: route,
    group: group,
  );
}
