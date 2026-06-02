import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

class OperitSqlViewerPage extends StatefulWidget {
  const OperitSqlViewerPage({super.key});

  @override
  State<OperitSqlViewerPage> createState() =>
      _OperitSqlViewerPageState();
}

class _OperitSqlViewerPageState extends State<OperitSqlViewerPage> {
  final _queryController = TextEditingController(
    text: 'SELECT id, name, created_at FROM users LIMIT 5',
  );
  bool _hasResults = false;

  static const _mockColumns = ['id', 'name', 'created_at'];
  static const _mockRows = [
    ['1', 'Alice', '2026-05-15 10:30:00'],
    ['2', 'Bob', '2026-05-16 14:20:00'],
    ['3', 'Charlie', '2026-05-18 09:00:00'],
    ['4', 'Diana', '2026-05-22 16:45:00'],
    ['5', 'Eve', '2026-06-01 08:15:00'],
  ];

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _executeQuery() {
    setState(() => _hasResults = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SQL 查看器'), centerTitle: true),
      body: Column(
        children: [
          _buildQueryInput(),
          const Divider(height: 1),
          if (_hasResults) _buildResultTable(),
        ],
      ),
    );
  }

  Widget _buildQueryInput() {
    return Padding(
      padding: const EdgeInsets.all(UiTokens.pagePadH),
      child: Column(
        children: [
          TextField(
            controller: _queryController,
            maxLines: 3,
            minLines: 2,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: UiTokens.bodyFS,
              color: UiTokens.onSurface,
            ),
            decoration: InputDecoration(
              hintText: '输入 SQL 查询语句...',
              hintStyle: TextStyle(
                fontSize: UiTokens.bodyFS,
                color: UiTokens.onSurfaceVariant,
              ),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UiTokens.cardRadius),
                borderSide: BorderSide(color: UiTokens.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UiTokens.cardRadius),
                borderSide: BorderSide(
                  color: UiTokens.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UiTokens.cardRadius),
                borderSide: BorderSide(color: UiTokens.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: FilledButton.icon(
              onPressed: _executeQuery,
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text(
                '执行查询',
                style: TextStyle(fontSize: UiTokens.bodyFS),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: UiTokens.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(UiTokens.cardRadius),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultTable() {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: UiTokens.pagePadH),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              UiTokens.primaryContainer.withValues(alpha: 0.4),
            ),
            headingTextStyle: TextStyle(
              fontSize: UiTokens.bodyFS,
              fontWeight: FontWeight.w700,
              color: UiTokens.onPrimaryContainer,
            ),
            dataTextStyle: TextStyle(
              fontSize: UiTokens.bodyFS,
              fontFamily: 'monospace',
              color: UiTokens.onSurface,
            ),
            columnSpacing: 28,
            horizontalMargin: 12,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 40,
            border: TableBorder.all(
              color: UiTokens.outlineVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(UiTokens.cardRadius),
            ),
            columns: _mockColumns
                .map(
                  (col) => DataColumn(label: Text(col), numeric: col == 'id'),
                )
                .toList(),
            rows: _mockRows
                .map(
                  (row) => DataRow(
                    cells: row
                        .asMap()
                        .entries
                        .map(
                          (entry) => DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                entry.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
