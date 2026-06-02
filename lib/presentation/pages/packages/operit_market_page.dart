import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

class OperitMarketPage extends StatefulWidget {
  const OperitMarketPage({super.key});

  @override
  State<OperitMarketPage> createState() => _OperitMarketPageState();
}

class _OperitMarketPageState extends State<OperitMarketPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['制品', '技能', 'MCP', '我的'];

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
        title: const Text('市场'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: UiTokens.primary,
          unselectedLabelColor: UiTokens.onSurfaceVariant,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab(_MarketSample.artifacts),
          _buildTab(_MarketSample.skills),
          _buildTab(_MarketSample.mcps),
          _buildMineTab(),
        ],
      ),
    );
  }

  Widget _buildTab(List<_MarketItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(UiTokens.pagePadH),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _MarketCard(item: item);
      },
    );
  }

  Widget _buildMineTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(UiTokens.pagePadH),
      itemCount: _MarketSample.myItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _MarketSample.myItems[index];
        return _MarketCard(item: item, showUpdate: true);
      },
    );
  }
}

class _MarketCard extends StatelessWidget {
  const _MarketCard({required this.item, this.showUpdate = false});

  final _MarketItem item;
  final bool showUpdate;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UiTokens.cardRadius),
        side: BorderSide(color: UiTokens.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: UiTokens.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(item.icon, size: 22, color: UiTokens.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: UiTokens.titleFS,
                      fontWeight: FontWeight.w600,
                      color: UiTokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: UiTokens.smallFS,
                      color: UiTokens.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 13,
                        color: const Color(0xFFF5A623),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.rating.toString(),
                        style: TextStyle(
                          fontSize: UiTokens.tinyFS,
                          color: UiTokens.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.download,
                        size: 13,
                        color: UiTokens.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.downloads,
                        style: TextStyle(
                          fontSize: UiTokens.tinyFS,
                          color: UiTokens.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showUpdate && item.hasUpdate)
              FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('正在更新...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: UiTokens.greenSuccess,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '更新',
                  style: TextStyle(fontSize: UiTokens.smallFS),
                ),
              )
            else
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('正在下载...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(
                    color: UiTokens.primary.withValues(alpha: 0.5),
                  ),
                ),
                child: const Text(
                  '下载',
                  style: TextStyle(fontSize: UiTokens.smallFS),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MarketItem {
  final String name;
  final String description;
  final IconData icon;
  final double rating;
  final String downloads;
  final bool hasUpdate;

  const _MarketItem({
    required this.name,
    required this.description,
    required this.icon,
    required this.rating,
    required this.downloads,
    this.hasUpdate = false,
  });
}

class _MarketSample {
  static const artifacts = [
    _MarketItem(
      name: 'novel-ide-monaco',
      description: 'Monaco 编辑器集成，提供代码高亮和智能补全',
      icon: Icons.edit_note,
      rating: 4.7,
      downloads: '3.2K',
    ),
    _MarketItem(
      name: 'operit-theme-pack',
      description: 'Operit 主题扩展包，包含 20+ 精选配色方案',
      icon: Icons.palette,
      rating: 4.5,
      downloads: '8.1K',
    ),
  ];

  static const skills = [
    _MarketItem(
      name: '智能校对',
      description: 'AI驱动的文章校对技能，检测错别字、语病和标点问题',
      icon: Icons.spellcheck,
      rating: 4.8,
      downloads: '6.7K',
    ),
    _MarketItem(
      name: '大纲生成',
      description: '基于关键词和主题自动生成文章大纲结构',
      icon: Icons.format_list_numbered,
      rating: 4.6,
      downloads: '4.3K',
    ),
  ];

  static const mcps = [
    _MarketItem(
      name: 'notion-mcp',
      description: 'Notion 工作区集成，文档同步和数据管理',
      icon: Icons.article,
      rating: 4.7,
      downloads: '7.8K',
    ),
  ];

  static const myItems = [
    _MarketItem(
      name: '文本智能总结',
      description: 'AI驱动的长文本摘要生成技能 v2.1.0',
      icon: Icons.summarize,
      rating: 4.8,
      downloads: '12.4K',
      hasUpdate: true,
    ),
  ];
}
