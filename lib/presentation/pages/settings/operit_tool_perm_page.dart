import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 工具权限管理页 — 全局设置 + 允许/拒绝工具列表
class OperitToolPermPage extends StatefulWidget {
  const OperitToolPermPage({super.key});

  @override
  State<OperitToolPermPage> createState() => _OperitToolPermPageState();
}

class _OperitToolPermPageState extends State<OperitToolPermPage> {
  String _globalSetting = '询问';

  final _allowedTools = <String>{
    'read_file',
    'search_content',
    'list_files',
  };

  final _deniedTools = <String>{
    'delete_file',
    'execute_command',
  };

  static const _globalOptions = ['拒绝', '询问', '允许'];

  static const _allTools = [
    ('read_file', '读取文件', '允许读取本地文件内容'),
    ('write_file', '写入文件', '创建或修改文件'),
    ('search_content', '搜索内容', '在文件中搜索文本'),
    ('list_files', '列出文件', '查看目录结构'),
    ('delete_file', '删除文件', '删除本地文件'),
    ('execute_command', '执行命令', '运行系统命令'),
    ('web_search', '网络搜索', '联网搜索信息'),
    ('api_call', 'API调用', '调用外部API'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('工具权限')),
      body: ListView(
        padding: EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildGroup('全局默认设置', [
            ListTile(
              title: const Text('默认权限', style: TextStyle(fontSize: 14)),
              trailing: SegmentedButton<String>(
                segments:
                    _globalOptions.map((o) {
                      return ButtonSegment<String>(
                        value: o,
                        label: Text(o, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                selected: {_globalSetting},
                onSelectionChanged: (v) {
                  setState(() => _globalSetting = v.first);
                },
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ]),
          const SizedBox(height: UiTokens.sectionSpacing),
          _buildGroup('工具列表', [
            ..._allTools.map(
              (tool) => _buildToolTile(
                id: tool.$1,
                name: tool.$2,
                desc: tool.$3,
                current: _getToolStatus(tool.$1),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  String _getToolStatus(String toolId) {
    if (_allowedTools.contains(toolId)) return '允许';
    if (_deniedTools.contains(toolId)) return '拒绝';
    return '询问';
  }

  Widget _buildToolTile({
    required String id,
    required String name,
    required String desc,
    required String current,
  }) {
    return ListTile(
      title: Text(name, style: const TextStyle(fontSize: 14)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      trailing: DropdownButton<String>(
        value: current,
        underline: const SizedBox.shrink(),
        isDense: true,
        items:
            _globalOptions.map((o) {
              return DropdownMenuItem(
                value: o,
                child: Text(o, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
        onChanged: (v) {
          if (v == null) return;
          setState(() {
            _allowedTools.remove(id);
            _deniedTools.remove(id);
            if (v == '允许') {
              _allowedTools.add(id);
            } else if (v == '拒绝') {
              _deniedTools.add(id);
            }
          });
        },
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: UiTokens.titleFS,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
