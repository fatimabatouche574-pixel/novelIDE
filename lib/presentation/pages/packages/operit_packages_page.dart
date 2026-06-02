import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

class OperitPackagesPage extends StatefulWidget {
  const OperitPackagesPage({super.key});

  @override
  State<OperitPackagesPage> createState() => _OperitPackagesPageState();
}

class _OperitPackagesPageState extends State<OperitPackagesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['制品', '技能', 'MCP'];

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
        title: const Text('包管理'),
        centerTitle: true,
        actions: [
          FilledButton.tonalIcon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('正在打开市场...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.store_outlined, size: 16),
            label: const Text(
              '浏览市场',
              style: TextStyle(fontSize: UiTokens.smallFS),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: UiTokens.pagePadH),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: UiTokens.primary,
          unselectedLabelColor: UiTokens.onSurfaceVariant,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildArtifactTab(), _buildSkillTab(), _buildMcpTab()],
      ),
    );
  }

  Widget _buildArtifactTab() {
    return _PackageList(packages: _SampleData.artifacts);
  }

  Widget _buildSkillTab() {
    return _PackageList(packages: _SampleData.skills);
  }

  Widget _buildMcpTab() {
    return _PackageList(packages: _SampleData.mcps);
  }
}

class _PackageList extends StatelessWidget {
  const _PackageList({required this.packages});

  final List<_PackageInfo> packages;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(UiTokens.pagePadH),
      itemCount: packages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final pkg = packages[index];
        return _PackageCard(package: pkg);
      },
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package});

  final _PackageInfo package;

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
                child: Icon(package.icon, size: 22, color: UiTokens.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          package.name,
                          style: TextStyle(
                            fontSize: UiTokens.titleFS,
                            fontWeight: FontWeight.w600,
                            color: UiTokens.onSurface,
                          ),
                        ),
                      ),
                      _StatusDot(installed: package.installed),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    package.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: UiTokens.smallFS,
                      color: UiTokens.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.installed});

  final bool installed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: installed ? UiTokens.greenSuccess : UiTokens.onSurfaceVariant,
      ),
    );
  }
}

class _PackageInfo {
  final String name;
  final String description;
  final IconData icon;
  final bool installed;

  const _PackageInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.installed,
  });
}

class _SampleData {
  static const artifacts = [
    _PackageInfo(
      name: 'novel-ide-core',
      description: '核心运行时库，提供文件操作、模型管理和基础服务',
      icon: Icons.extension,
      installed: true,
    ),
    _PackageInfo(
      name: 'operit-tts-engine',
      description: '文本转语音引擎，支持多语言和自定义语音模型',
      icon: Icons.record_voice_over,
      installed: true,
    ),
    _PackageInfo(
      name: 'auto-glm-plugin',
      description: 'AutoGLM 一键部署插件，自动化模型下载和配置',
      icon: Icons.rocket_launch,
      installed: false,
    ),
  ];

  static const skills = [
    _PackageInfo(
      name: '文本总结',
      description: 'AI驱动的长文本摘要生成技能，支持多种总结模式',
      icon: Icons.summarize,
      installed: true,
    ),
    _PackageInfo(
      name: '代码审查',
      description: '自动化代码审查技能，检测安全漏洞和代码异味',
      icon: Icons.code_review,
      installed: true,
    ),
    _PackageInfo(
      name: '数据分析',
      description: 'Python数据分析技能，支持Pandas/NumPy数据处理',
      icon: Icons.analytics,
      installed: false,
    ),
  ];

  static const mcps = [
    _PackageInfo(
      name: 'filesystem',
      description: 'MCP文件系统服务，提供安全的文件读写操作能力',
      icon: Icons.folder_special,
      installed: true,
    ),
    _PackageInfo(
      name: 'github',
      description: 'GitHub MCP 集成，支持仓库管理、PR/Issue操作',
      icon: Icons.code,
      installed: true,
    ),
    _PackageInfo(
      name: 'postgres',
      description: 'PostgreSQL MCP 服务，数据库查询和管理工具',
      icon: Icons.storage,
      installed: false,
    ),
  ];
}
