import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/constants.dart';
import 'package:novel_ide/data/models/ai_config_model.dart';
import 'package:novel_ide/presentation/state/app_providers.dart';
import 'package:novel_ide/data/datasources/database_helper.dart';
import 'package:novel_ide/data/datasources/secure_storage_datasource.dart';
import 'package:novel_ide/data/services/config_service.dart';
import 'package:novel_ide/data/services/default_config_service.dart';
import 'package:novel_ide/data/services/ai_service.dart';


class AiConfigListPage extends ConsumerWidget {
  const AiConfigListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = ref.watch(aiConfigsProvider);
    final selectedId = ref.watch(selectedAiConfigProvider)?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 模型配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加自定义模型',
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: configs.isEmpty
          ? const Center(child: Text('未配置AI模型', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              itemCount: configs.length,
              itemBuilder: (context, index) {
                final config = configs[index];
                final isSelected = config.id == selectedId;
                final isBuiltin = DefaultConfigService.isBuiltinModel(config.id);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: isSelected ? 3 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected ? BorderSide(color: AppColors.primary, width: 2) : BorderSide.none,
                  ),
                  color: isSelected ? AppColors.primary.withOpacity(0.08) : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Icon(
                      Icons.smart_toy,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                    title: Row(
                      children: [
                        Text(
                          config.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 15,
                          ),
                        ),
                        if (isBuiltin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('内置', style: TextStyle(fontSize: 11, color: Colors.orange)),
                          ),
                        ],
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('使用中', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${config.modelName} · ${_extractDomain(config.apiUrl)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: isBuiltin
                        ? null
                        : PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'use') {
                                ConfigService.aiConfigId = config.id;
                                ref.read(selectedAiConfigProvider.notifier).state = config;
                              } else if (value == 'delete') {
                                _showDeleteConfirm(context, ref, config);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'use', child: Text('使用这个模型')),
                              const PopupMenuItem(value: 'delete', child: Text('删除', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                    onTap: () {
                      ConfigService.aiConfigId = config.id;
                      ref.read(selectedAiConfigProvider.notifier).state = config;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('已切换到「${config.name}」'), duration: const Duration(seconds: 1)),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url.length > 30 ? '${url.substring(0, 30)}...' : url;
    }
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, AiConfig config) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除「${config.name}」？'),
        content: const Text('删除后无法恢复，确定要删除吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              try {
                await DatabaseHelper().deleteAiConfig(config.id);
                await SecureStorageDataSource().deleteApiKey(config.id);
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.red),
                  );
                }
                return;
              }
              final list = ref.read(aiConfigsProvider).where((c) => c.id != config.id).toList();
              ref.read(aiConfigsProvider.notifier).state = list;
              if (ref.read(selectedAiConfigProvider)?.id == config.id) {
                if (list.isNotEmpty) {
                  ConfigService.aiConfigId = list.first.id;
                  ref.read(selectedAiConfigProvider.notifier).state = list.first;
                } else {
                  ConfigService.aiConfigId = '';
                  ref.read(selectedAiConfigProvider.notifier).state = null;
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final keyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        ApiProtocol selectedProtocol = ApiProtocol.openaiCompatible;
        bool testing = false;
        bool fetchingModels = false;
        List<String> availableModels = [];
        String? testResult;
        bool? testSuccess;
        int? testLatency;

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('添加自定义模型'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: '配置名称', prefixIcon: Icon(Icons.label)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'API 地址',
                      prefixIcon: Icon(Icons.link),
                      hintText: '如 https://api.deepseek.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 模型ID + 下拉选择
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: modelCtrl,
                          decoration: const InputDecoration(labelText: '模型 ID', prefixIcon: Icon(Icons.memory)),
                        ),
                      ),
                      if (availableModels.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.blue),
                          tooltip: '从获取的模型列表中选择',
                          onSelected: (v) {
                            modelCtrl.text = v;
                            setDialogState(() {});
                          },
                          itemBuilder: (_) => availableModels
                              .map((m) => PopupMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ApiProtocol>(
                    value: selectedProtocol,
                    decoration: const InputDecoration(labelText: 'API 协议', prefixIcon: Icon(Icons.swap_horiz)),
                    items: const [
                      DropdownMenuItem(value: ApiProtocol.openaiCompatible, child: Text('OpenAI兼容')),
                      DropdownMenuItem(value: ApiProtocol.anthropic, child: Text('Anthropic')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => selectedProtocol = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'API Key', prefixIcon: Icon(Icons.key)),
                  ),
                  const SizedBox(height: 16),

                  // ── 测试连接 & 获取模型列表 按钮 ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: testing
                              ? null
                              : () async {
                                  final url = urlCtrl.text.trim();
                                  if (url.isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('请先填写 API 地址'), backgroundColor: Colors.orange),
                                    );
                                    return;
                                  }
                                  setDialogState(() {
                                    testing = true;
                                    testResult = null;
                                  });
                                  final aiService = ref.read(aiServiceProvider);
                                  final config = AiConfig(
                                    id: '_test',
                                    name: nameCtrl.text.trim().isEmpty ? 'test' : nameCtrl.text.trim(),
                                    apiUrl: url,
                                    modelName: modelCtrl.text.trim().isEmpty ? 'gpt-3.5-turbo' : modelCtrl.text.trim(),
                                    apiKey: keyCtrl.text.trim().isEmpty ? null : keyCtrl.text.trim(),
                                    protocol: selectedProtocol,
                                  );
                                  final result = await aiService.testConnection(config);
                                  setDialogState(() {
                                    testing = false;
                                    testSuccess = result['success'] as bool;
                                    testResult = result['message'] as String;
                                    testLatency = result['latency_ms'] as int?;
                                  });
                                },
                          icon: testing
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.wifi_tethering, size: 18),
                          label: Text(testing ? '测试中...' : '测试连接'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: fetchingModels
                              ? null
                              : () async {
                                  final url = urlCtrl.text.trim();
                                  if (url.isEmpty) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(content: Text('请先填写 API 地址'), backgroundColor: Colors.orange),
                                    );
                                    return;
                                  }
                                  setDialogState(() => fetchingModels = true);
                                  final aiService = ref.read(aiServiceProvider);
                                  final config = AiConfig(
                                    id: '_fetch',
                                    name: 'fetch',
                                    apiUrl: url,
                                    modelName: 'x',
                                    apiKey: keyCtrl.text.trim().isEmpty ? null : keyCtrl.text.trim(),
                                    protocol: selectedProtocol,
                                  );
                                  try {
                                    final models = await aiService.fetchModels(config);
                                    setDialogState(() {
                                      fetchingModels = false;
                                      availableModels = models;
                                    });
                                    if (models.isEmpty && ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(content: Text('未获取到模型列表，请检查地址和 Key'), backgroundColor: Colors.orange),
                                      );
                                    }
                                  } catch (e) {
                                    setDialogState(() => fetchingModels = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(content: Text('获取失败: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                          icon: fetchingModels
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.download, size: 18),
                          label: Text(fetchingModels ? '获取中...' : '获取模型'),
                        ),
                      ),
                    ],
                  ),

                  // ── 测试结果 ──
                  if (testResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (testSuccess == true ? Colors.green : Colors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (testSuccess == true ? Colors.green : Colors.red).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            testSuccess == true ? Icons.check_circle : Icons.error,
                            color: testSuccess == true ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  testResult!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: testSuccess == true ? Colors.green[800] : Colors.red[800],
                                  ),
                                ),
                                if (testLatency != null)
                                  Text('延迟: ${testLatency}ms', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── 模型列表预览 ──
                  if (availableModels.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '可用模型 (${availableModels.length})，点击选择:',
                            style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: availableModels.length,
                              itemBuilder: (_, i) => InkWell(
                                onTap: () {
                                  modelCtrl.text = availableModels[i];
                                  setDialogState(() {});
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(availableModels[i], style: const TextStyle(fontSize: 13)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final url = urlCtrl.text.trim();
                  final model = modelCtrl.text.trim();
                  final key = keyCtrl.text.trim();
                  if (name.isEmpty || url.isEmpty || model.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('名称、API地址、模型ID不能为空'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  final db = DatabaseHelper();
                  final config = AiConfig(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    apiUrl: url,
                    modelName: model,
                    protocol: selectedProtocol,
                  );
                  await db.insertAiConfig(db.toDbMap(config));
                  if (key.isNotEmpty) {
                    await SecureStorageDataSource().writeApiKey(config.id, key);
                  }
                  await loadAiConfigs(ref);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已添加「$name」'), backgroundColor: Colors.green),
                    );
                  }
                },
                child: const Text('添加'),
              ),
            ],
          ),
        );
      },
    );
  }
}