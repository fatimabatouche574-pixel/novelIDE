import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 用户偏好设置页 — 6个开关选项
class OperitUserPrefsPage extends StatefulWidget {
  const OperitUserPrefsPage({super.key});

  @override
  State<OperitUserPrefsPage> createState() => _OperitUserPrefsPageState();
}

class _OperitUserPrefsPageState extends State<OperitUserPrefsPage> {
  final _prefs = <String, bool>{
    '自动保存': true,
    '显示字数统计': true,
    '启动时恢复上次会话': false,
    '发送后清空输入框': true,
    '显示行号': true,
    '自动拼写检查': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('用户偏好')),
      body: ListView(
        padding: EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildGroup(
            '通用设置',
            _prefs.entries.map((entry) {
              return SwitchListTile(
                title: Text(entry.key, style: const TextStyle(fontSize: 14)),
                value: entry.value,
                onChanged: (v) {
                  setState(() => _prefs[entry.key] = v);
                },
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(String title, List<Widget> items) {
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
        ...items,
      ],
    );
  }
}
