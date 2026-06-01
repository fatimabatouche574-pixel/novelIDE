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

class _VendorInfo {
  final String name;
  final String apiUrl;
  final List<String> defaultModels;
  final ApiProtocol protocol;
  const _VendorInfo(this.name, this.apiUrl, this.defaultModels, this.protocol);
}

class _VendorCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _VendorCard({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            onPressed: () => _showAddEditDialog(context, ref),
          ),
        ],
      ),
      body: configs.isEmpty
          ? const Center(
              child: Text('未配置AI模型', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              itemCount: configs.length,
              itemBuilder: (context, index) {
                final config = configs[index];
                final isSelected = config.id == selectedId;
                final isBuiltin = DefaultConfigService.isBuiltinModel(
                  config.id,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  elevation: isSelected ? 3 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isSelected
                        ? BorderSide(color: AppColors.primary, width: 2)
                        : BorderSide.none,
                  ),
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.08)
                      : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      Icons.smart_toy,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                    title: Row(
                      children: [
                        Text(
                          config.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 15,
                          ),
                        ),
                        if (isBuiltin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '内置',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '使用中',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
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
                                ref
                                        .read(selectedAiConfigProvider.notifier)
                                        .state =
                                    config;
                              } else if (value == 'edit') {
                                _showAddEditDialog(
                                  context,
                                  ref,
                                  existingConfig: config,
                                );
                              } else if (value == 'delete') {
                                _showDeleteConfirm(context, ref, config);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'use',
                                child: Text('使用这个模型'),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('编辑'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  '删除',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    onTap: () {
                      ConfigService.aiConfigId = config.id;
                      ref.read(selectedAiConfigProvider.notifier).state =
                          config;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已切换到「${config.name}」'),
                          duration: const Duration(seconds: 1),
                        ),
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

  void _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    AiConfig config,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除「${config.name}」？'),
        content: const Text('删除后无法恢复，确定要删除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
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
                    SnackBar(
                      content: Text('删除失败: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              final list = ref
                  .read(aiConfigsProvider)
                  .where((c) => c.id != config.id)
                  .toList();
              ref.read(aiConfigsProvider.notifier).state = list;
              if (ref.read(selectedAiConfigProvider)?.id == config.id) {
                if (list.isNotEmpty) {
                  ConfigService.aiConfigId = list.first.id;
                  ref.read(selectedAiConfigProvider.notifier).state =
                      list.first;
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

  void _showAddEditDialog(
    BuildContext context,
    WidgetRef ref, {
    AiConfig? existingConfig,
  }) {
    final bool isEdit = existingConfig != null;

    final nameCtrl = TextEditingController(text: existingConfig?.name ?? '');
    final urlCtrl = TextEditingController(text: existingConfig?.apiUrl ?? '');
    final modelCtrl = TextEditingController(
      text: existingConfig?.modelName ?? '',
    );
    final keyCtrl = TextEditingController(text: existingConfig?.apiKey ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        const vendors = [
          _VendorInfo('OpenAI', 'https://api.openai.com/v1', [
            'gpt-4o',
            'gpt-4-turbo',
          ], ApiProtocol.openaiCompatible),
          _VendorInfo('Anthropic', 'https://api.anthropic.com/v1', [
            'claude-opus-4-8',
            'claude-sonnet-4-6',
          ], ApiProtocol.anthropic),
          _VendorInfo('DeepSeek', 'https://api.deepseek.com/v1', [
            'deepseek-chat',
          ], ApiProtocol.openaiCompatible),
          _VendorInfo(
            '智谱AI',
            'https://open.bigmodel.cn/api/paas/v4',
            ['glm-4-flash'],
            ApiProtocol.openaiCompatible,
          ),
          _VendorInfo(
            '通义千问',
            'https://dashscope.aliyuncs.com/compatible-mode/v1',
            ['qwen-plus'],
            ApiProtocol.openaiCompatible,
          ),
          _VendorInfo('Moonshot', 'https://api.moonshot.cn/v1', [
            'moonshot-v1-8k',
          ], ApiProtocol.openaiCompatible),
        ];

        // State variables declared outside StatefulBuilder so they persist
        // across rebuilds triggered by setDialogState.
        int step = isEdit ? 1 : 0;
        ApiProtocol selectedProtocol =
            existingConfig?.protocol ?? ApiProtocol.openaiCompatible;
        bool testing = false;
        bool fetchingModels = false;
        List<String> availableModels = [];
        String? testResult;
        bool? testSuccess;
        int? testLatency;

        // 高级参数状态变量
        double tempValue = existingConfig?.temperature ?? 1.0;
        double topPValue = existingConfig?.topP ?? 1.0;
        int topKValue = existingConfig?.topK ?? 0;
        double presencePenaltyValue = existingConfig?.presencePenalty ?? 0.0;
        double frequencyPenaltyValue = existingConfig?.frequencyPenalty ?? 0.0;
        bool topPEnabled = existingConfig?.topPEnabled ?? false;
        bool topKEnabled = existingConfig?.topKEnabled ?? false;
        bool presencePenaltyEnabled = existingConfig?.presencePenaltyEnabled ?? false;
        bool frequencyPenaltyEnabled = existingConfig?.frequencyPenaltyEnabled ?? false;
        bool enableToolCall = existingConfig?.enableToolCall ?? false;
        bool enableSummary = existingConfig?.enableSummary ?? true;
        bool enableClaudeCache = existingConfig?.enableClaude1hPromptCache ?? false;
        bool enableGoogleSearch = existingConfig?.enableGoogleSearch ?? false;
        final maxTokensCtrl = TextEditingController(
          text: (existingConfig?.maxTokens ?? 4096).toString(),
        );
        final contextLengthCtrl = TextEditingController(
          text: (existingConfig?.contextLength ?? 64.0).toStringAsFixed(1),
        );

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void selectVendor(_VendorInfo v) {
              setDialogState(() {
                step = 1;
                nameCtrl.text = v.name;
                urlCtrl.text = v.apiUrl;
                selectedProtocol = v.protocol;
                if (v.defaultModels.isNotEmpty) {
                  modelCtrl.text = v.defaultModels.first;
                }
              });
            }

            void selectCustom() {
              setDialogState(() => step = 1);
            }

            Future<void> doTestConnection() async {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('请先填写 API 地址'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              setDialogState(() {
                testing = true;
                testResult = null;
              });
              final aiService = ref.read(aiServiceProvider);
              final testCfg = AiConfig(
                id: '_test',
                name: nameCtrl.text.trim().isEmpty
                    ? 'test'
                    : nameCtrl.text.trim(),
                apiUrl: url,
                modelName: modelCtrl.text.trim().isEmpty
                    ? 'gpt-3.5-turbo'
                    : modelCtrl.text.trim(),
                apiKey: keyCtrl.text.trim().isEmpty
                    ? null
                    : keyCtrl.text.trim(),
                protocol: selectedProtocol,
              );
              final result = await aiService.testConnection(testCfg);
              setDialogState(() {
                testing = false;
                testSuccess = result['success'] as bool;
                testResult = result['message'] as String;
                testLatency = result['latency_ms'] as int?;
              });
            }

            Future<void> doFetchModels() async {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('请先填写 API 地址'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              setDialogState(() => fetchingModels = true);
              final aiService = ref.read(aiServiceProvider);
              final fetchCfg = AiConfig(
                id: '_fetch',
                name: 'fetch',
                apiUrl: url,
                modelName: 'x',
                apiKey: keyCtrl.text.trim().isEmpty
                    ? null
                    : keyCtrl.text.trim(),
                protocol: selectedProtocol,
              );
              try {
                final models = await aiService.fetchModels(fetchCfg);
                setDialogState(() {
                  fetchingModels = false;
                  availableModels = models;
                });
                if (models.isEmpty && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('未获取到模型列表，请检查地址和 Key'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                setDialogState(() => fetchingModels = false);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('获取失败: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }

            return AlertDialog(
              title: Text(isEdit ? '编辑模型配置' : '添加模型配置'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (step == 0)
                        _buildVendorGrid(vendors, selectVendor, selectCustom)
                      else ...[
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: '配置名称',
                            prefixIcon: Icon(Icons.label),
                          ),
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
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: modelCtrl,
                                decoration: const InputDecoration(
                                  labelText: '模型 ID',
                                  prefixIcon: Icon(Icons.memory),
                                ),
                              ),
                            ),
                            if (availableModels.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.arrow_drop_down_circle,
                                  color: Colors.blue,
                                ),
                                tooltip: '从获取的模型列表中选择',
                                onSelected: (v) {
                                  modelCtrl.text = v;
                                  setDialogState(() {});
                                },
                                itemBuilder: (_) => availableModels
                                    .map(
                                      (m) => PopupMenuItem(
                                        value: m,
                                        child: Text(
                                          m,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<ApiProtocol>(
                          value: selectedProtocol,
                          decoration: const InputDecoration(
                            labelText: 'API 协议',
                            prefixIcon: Icon(Icons.swap_horiz),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: ApiProtocol.openaiCompatible,
                              child: Text('OpenAI兼容'),
                            ),
                            DropdownMenuItem(
                              value: ApiProtocol.anthropic,
                              child: Text('Anthropic'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => selectedProtocol = v);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: keyCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'API Key',
                            prefixIcon: Icon(Icons.key),
                          ),
                        ),
                        const SizedBox(height: 16),
const SizedBox(height: 8),
Theme(
  data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
  child: ExpansionTile(
    title: Text(
      "高级参数",
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    leading: const Icon(Icons.tune),
    children: [
      // Temperature
      _buildParamTile(ctx,
        title: "Temperature",
        value: tempValue,
        min: 0.0,
        max: 2.0,
        onChanged: (v) => setDialogState(() => tempValue = v),
      ),
      // Top-P
      _buildParamTileWithSwitch(ctx,
        title: "Top-P",
        value: topPValue,
        enabled: topPEnabled,
        min: 0.0,
        max: 1.0,
        onToggle: (v) => setDialogState(() => topPEnabled = v),
        onChanged: (v) => setDialogState(() => topPValue = v),
      ),
      // Top-K
      _buildIntParamTileWithSwitch(ctx,
        title: "Top-K",
        value: topKValue,
        enabled: topKEnabled,
        min: 0,
        max: 100,
        onToggle: (v) => setDialogState(() => topKEnabled = v),
        onChanged: (v) => setDialogState(() => topKValue = v),
      ),
      // Presence Penalty
      _buildParamTileWithSwitch(ctx,
        title: "Presence Penalty",
        value: presencePenaltyValue,
        enabled: presencePenaltyEnabled,
        min: -2.0,
        max: 2.0,
        onToggle: (v) => setDialogState(() => presencePenaltyEnabled = v),
        onChanged: (v) => setDialogState(() => presencePenaltyValue = v),
      ),
      // Frequency Penalty
      _buildParamTileWithSwitch(ctx,
        title: "Frequency Penalty",
        value: frequencyPenaltyValue,
        enabled: frequencyPenaltyEnabled,
        min: -2.0,
        max: 2.0,
        onToggle: (v) => setDialogState(() => frequencyPenaltyEnabled = v),
        onChanged: (v) => setDialogState(() => frequencyPenaltyValue = v),
      ),
      // Max Tokens
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: maxTokensCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Max Tokens",
            prefixIcon: Icon(Icons.token),
          ),
        ),
      ),
      // Context Length
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: contextLengthCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Context Length (K tokens)",
            prefixIcon: Icon(Icons.memory),
          ),
        ),
      ),
      // Tool Call toggle
      SwitchListTile(
        title: const Text("Tool Call"),
        subtitle: const Text("启用原生工具调用"),
        value: enableToolCall,
        onChanged: (v) => setDialogState(() => enableToolCall = v),
      ),
      // Claude Cache toggle
      SwitchListTile(
        title: const Text("Claude 1h Cache"),
        subtitle: const Text("启用1小时提示缓存"),
        value: enableClaudeCache,
        onChanged: (v) => setDialogState(() => enableClaudeCache = v),
      ),
      // Google Search toggle
      SwitchListTile(
        title: const Text("Google Search"),
        subtitle: const Text("启用Google搜索地面"),
        value: enableGoogleSearch,
        onChanged: (v) => setDialogState(() => enableGoogleSearch = v),
      ),
    ],
  ),
),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: testing ? null : doTestConnection,
                                icon: testing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.wifi_tethering,
                                        size: 18,
                                      ),
                                label: Text(testing ? '测试中...' : '测试连接'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: fetchingModels
                                    ? null
                                    : doFetchModels,
                                icon: fetchingModels
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.download, size: 18),
                                label: Text(fetchingModels ? '获取中...' : '获取模型'),
                              ),
                            ),
                          ],
                        ),
                        if (testResult != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  (testSuccess == true
                                          ? Colors.green
                                          : Colors.red)
                                      .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    (testSuccess == true
                                            ? Colors.green
                                            : Colors.red)
                                        .withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  testSuccess == true
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: testSuccess == true
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        testResult!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: testSuccess == true
                                              ? Colors.green[800]
                                              : Colors.red[800],
                                        ),
                                      ),
                                      if (testLatency != null)
                                        Text(
                                          '延迟: ${testLatency}ms',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (availableModels.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '可用模型 (${availableModels.length})，点击选择:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: Text(
                                          availableModels[i],
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                if (step == 1)
                  FilledButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final url = urlCtrl.text.trim();
                      final model = modelCtrl.text.trim();
                      final key = keyCtrl.text.trim();
                      if (name.isEmpty || url.isEmpty || model.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('名称、API地址、模型ID不能为空'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      final db = DatabaseHelper();
                      if (isEdit) {
                        final updated = AiConfig(
                          id: existingConfig.id,
                          name: name,
                          apiUrl: url,
                          modelName: model,
                          protocol: selectedProtocol,
                          temperature: tempValue,
                          maxTokens: int.tryParse(maxTokensCtrl.text.trim()) ?? 4096,
                          topP: topPValue,
                          topK: topKValue,
                          presencePenalty: presencePenaltyValue,
                          frequencyPenalty: frequencyPenaltyValue,
                          topPEnabled: topPEnabled,
                          topKEnabled: topKEnabled,
                          presencePenaltyEnabled: presencePenaltyEnabled,
                          frequencyPenaltyEnabled: frequencyPenaltyEnabled,
                          contextLength: double.tryParse(contextLengthCtrl.text.trim()) ?? 64.0,
                          enableSummary: enableSummary,
                          enableToolCall: enableToolCall,
                          enableClaude1hPromptCache: enableClaudeCache,
                          enableGoogleSearch: enableGoogleSearch,
                        );
                        await db.insertAiConfig(db.toDbMap(updated));
                        if (key.isNotEmpty) {
                          await SecureStorageDataSource().writeApiKey(
                            existingConfig.id,
                            key,
                          );
                        }
                      } else {
                        final newId = DateTime.now().millisecondsSinceEpoch
                            .toString();
                        final config = AiConfig(
                          id: newId,
                          name: name,
                          apiUrl: url,
                          modelName: model,
                          protocol: selectedProtocol,
                          temperature: tempValue,
                          maxTokens: int.tryParse(maxTokensCtrl.text.trim()) ?? 4096,
                          topP: topPValue,
                          topK: topKValue,
                          presencePenalty: presencePenaltyValue,
                          frequencyPenalty: frequencyPenaltyValue,
                          topPEnabled: topPEnabled,
                          topKEnabled: topKEnabled,
                          presencePenaltyEnabled: presencePenaltyEnabled,
                          frequencyPenaltyEnabled: frequencyPenaltyEnabled,
                          contextLength: double.tryParse(contextLengthCtrl.text.trim()) ?? 64.0,
                          enableSummary: enableSummary,
                          enableToolCall: enableToolCall,
                          enableClaude1hPromptCache: enableClaudeCache,
                          enableGoogleSearch: enableGoogleSearch,
                        );
                        await db.insertAiConfig(db.toDbMap(config));
                        if (key.isNotEmpty) {
                          await SecureStorageDataSource().writeApiKey(
                            config.id,
                            key,
                          );
                        }
                      }
                      await loadAiConfigs(ref);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEdit ? '已更新「$name」' : '已添加「$name」'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: Text(isEdit ? '保存修改' : '添加'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildParamTile(BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13)),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildParamTileWithSwitch(BuildContext context, {
    required String title,
    required double value,
    required bool enabled,
    required double min,
    required double max,
    required ValueChanged<bool> onToggle,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Switch(
                    value: enabled,
                    onChanged: onToggle,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 4),
                  Text(title, style: const TextStyle(fontSize: 13)),
                ],
              ),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 13,
                  color: enabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildIntParamTileWithSwitch(BuildContext context, {
    required String title,
    required int value,
    required bool enabled,
    required int min,
    required int max,
    required ValueChanged<bool> onToggle,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Switch(
                    value: enabled,
                    onChanged: onToggle,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 4),
                  Text(title, style: const TextStyle(fontSize: 13)),
                ],
              ),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: enabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            onChanged: enabled ? (v) => onChanged(v.round()) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildVendorGrid(
    List<_VendorInfo> vendors,
    void Function(_VendorInfo) onSelect,
    VoidCallback onCustom,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '选择厂商',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
          ),
          itemCount: vendors.length + 1,
          itemBuilder: (_, i) {
            if (i == vendors.length) {
              return _VendorCard(
                name: '自定义',
                subtitle: '手动填写所有字段',
                icon: Icons.build,
                onTap: onCustom,
              );
            }
            final v = vendors[i];
            return _VendorCard(
              name: v.name,
              subtitle: v.defaultModels.join(', '),
              icon: Icons.cloud,
              onTap: () => onSelect(v),
            );
          },
        ),
      ],
    );
  }
}
