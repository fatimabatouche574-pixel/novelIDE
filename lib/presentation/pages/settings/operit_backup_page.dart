import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 数据备份页 — 概览统计/导出格式/导入/自动备份
class OperitBackupPage extends StatefulWidget {
  const OperitBackupPage({super.key});

  @override
  State<OperitBackupPage> createState() => _OperitBackupPageState();
}

class _OperitBackupPageState extends State<OperitBackupPage> {
  String _exportFormat = 'ZIP';
  bool _autoBackup = false;
  int _autoBackupInterval = 7;

  static const _exportFormats = ['ZIP', 'JSON', 'SQLite'];
  static const _intervalDays = [1, 3, 7, 14, 30];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据备份')),
      body: ListView(
        padding: EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildGroup('数据概览', [_buildOverviewCard()]),
          const SizedBox(height: UiTokens.sectionSpacing),
          _buildGroup('导出', [
            _buildDropdownTile('导出格式', _exportFormat, _exportFormats, (v) {
              setState(() => _exportFormat = v);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('导出已开始...'),
                      backgroundColor: UiTokens.greenSuccess,
                    ),
                  );
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('导出所有数据'),
              ),
            ),
          ]),
          const SizedBox(height: UiTokens.sectionSpacing),
          _buildGroup('导入', [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload, size: 18),
                label: const Text('从文件导入'),
              ),
            ),
          ]),
          const SizedBox(height: UiTokens.sectionSpacing),
          _buildGroup('自动备份', [
            SwitchListTile(
              title: const Text('自动备份', style: TextStyle(fontSize: 14)),
              subtitle: Text('每$_autoBackupInterval天自动备份一次'),
              value: _autoBackup,
              onChanged: (v) => setState(() => _autoBackup = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (_autoBackup)
              _buildDropdownTile('备份间隔', '$_autoBackupInterval天',
                  _intervalDays.map((d) => '$d天').toList(), (v) {
                setState(
                  () => _autoBackupInterval = int.parse(v.replaceAll('天', '')),
                );
              }),
          ]),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiTokens.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow('作品数量', '3'),
            const Divider(),
            _buildStatRow('总章节数', '128'),
            const Divider(),
            _buildStatRow('资料卡片', '56'),
            const Divider(),
            _buildStatRow('上次备份', '2026-06-01 14:30'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(
    String label,
    String value,
    List<String> options,
    void Function(String) onChanged,
  ) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        isDense: true,
        items:
            options.map((o) {
              return DropdownMenuItem(
                value: o,
                child: Text(o, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
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
