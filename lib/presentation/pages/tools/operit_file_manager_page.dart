import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

class OperitFileManagerPage extends StatefulWidget {
  const OperitFileManagerPage({super.key});

  @override
  State<OperitFileManagerPage> createState() =>
      _OperitFileManagerPageState();
}

class _OperitFileManagerPageState extends State<OperitFileManagerPage> {
  String _currentPath = '/home/user/projects';

  static const _entries = <_FileEntry>[
    _FileEntry(
      name: 'src',
      isDirectory: true,
      size: '-',
      modified: 'Jun 3',
      children: [
        _FileEntry(
          name: 'main.dart',
          isDirectory: false,
          size: '12.4 KB',
          modified: 'Jun 3 10:30',
        ),
        _FileEntry(
          name: 'utils.dart',
          isDirectory: false,
          size: '3.8 KB',
          modified: 'May 28 14:15',
        ),
      ],
    ),
    _FileEntry(
      name: 'config.yaml',
      isDirectory: false,
      size: '1.2 KB',
      modified: 'Jun 3 08:00',
    ),
    _FileEntry(
      name: 'pubspec.yaml',
      isDirectory: false,
      size: '2.8 KB',
      modified: 'Jun 2 22:10',
    ),
    _FileEntry(
      name: 'README.md',
      isDirectory: false,
      size: '0.5 KB',
      modified: 'May 20 12:00',
    ),
  ];

  String get _dirName => _currentPath.split('/').last;

  void _navigateTo(String dirName) {
    for (final entry in _entries) {
      if (entry.isDirectory && entry.name == dirName) {
        setState(() {
          _currentPath = '$_currentPath/$dirName';
        });
        return;
      }
    }
  }

  void _goUp() {
    final parts = _currentPath.split('/');
    if (parts.length > 1) {
      setState(() {
        _currentPath = parts.sublist(0, parts.length - 1).join('/');
        if (_currentPath.isEmpty) _currentPath = '/';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _getCurrentEntries();
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件管理器'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: UiTokens.quickIconSize),
            onPressed: () {},
            tooltip: '搜索',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPathBar(),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(UiTokens.pagePadH),
              itemCount: entries.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: UiTokens.outlineVariant.withValues(alpha: 0.3),
              ),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _FileItem(
                  entry: entry,
                  onTap: entry.isDirectory
                      ? () => _navigateTo(entry.name)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_FileEntry> _getCurrentEntries() {
    if (_currentPath == '/home/user/projects') return _entries;
    for (final entry in _entries) {
      if (entry.isDirectory && _currentPath.contains(entry.name)) {
        return entry.children;
      }
    }
    return [];
  }

  Widget _buildPathBar() {
    final parts = _currentPath.split('/')..removeWhere((p) => p.isEmpty);
    final displayParts = ['/'] + parts;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: UiTokens.pagePadH,
        vertical: 10,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _goUp,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: UiTokens.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.arrow_upward,
                size: 16,
                color: UiTokens.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < displayParts.length; i++) ...[
                    Text(
                      displayParts[i],
                      style: TextStyle(
                        fontSize: UiTokens.bodyFS,
                        fontWeight: i == displayParts.length - 1
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: i == displayParts.length - 1
                            ? UiTokens.onSurface
                            : UiTokens.onSurfaceVariant,
                      ),
                    ),
                    if (i < displayParts.length - 1)
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: UiTokens.onSurfaceVariant,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileItem extends StatelessWidget {
  const _FileItem({required this.entry, this.onTap});

  final _FileEntry entry;
  final VoidCallback? onTap;

  IconData get _icon {
    if (entry.isDirectory) return Icons.folder_outlined;
    final ext = entry.name.split('.').last;
    switch (ext) {
      case 'dart':
        return Icons.code;
      case 'yaml':
        return Icons.settings;
      case 'md':
        return Icons.article_outlined;
      case 'png':
      case 'svg':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color get _iconColor {
    if (entry.isDirectory) return const Color(0xFFF5A623);
    final ext = entry.name.split('.').last;
    switch (ext) {
      case 'dart':
        return const Color(0xFF00B4AB);
      case 'yaml':
        return const Color(0xFF7C4DFF);
      case 'md':
        return const Color(0xFF4A90D9);
      default:
        return UiTokens.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      leading: Icon(_icon, color: _iconColor, size: 22),
      title: Text(
        entry.name,
        style: TextStyle(
          fontSize: UiTokens.bodyFS,
          fontWeight: FontWeight.w500,
          color: UiTokens.onSurface,
        ),
      ),
      subtitle: Text(
        '${entry.size}  ·  ${entry.modified}',
        style: TextStyle(
          fontSize: UiTokens.tinyFS,
          color: UiTokens.onSurfaceVariant,
        ),
      ),
      trailing: entry.isDirectory
          ? Icon(
              Icons.chevron_right,
              size: 18,
              color: UiTokens.onSurfaceVariant,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _FileEntry {
  final String name;
  final bool isDirectory;
  final String size;
  final String modified;
  final List<_FileEntry> children;

  const _FileEntry({
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.modified,
    this.children = const [],
  });
}
