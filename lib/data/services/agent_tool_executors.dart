import 'package:novel_ide/data/models/material_models.dart';
import 'package:novel_ide/data/models/memory/memory_entity.dart';
import 'package:novel_ide/data/models/memory/memory_repository.dart';
import 'package:novel_ide/data/models/ai_config_model.dart';
import 'package:novel_ide/data/models/tomato_agent_model.dart';
import 'package:novel_ide/data/repositories/material_repository.dart';
import 'package:novel_ide/data/repositories/chapter_repository.dart';
import 'package:novel_ide/data/repositories/skill_repository.dart';
import 'package:novel_ide/data/repositories/novel_repository.dart';
import 'package:novel_ide/data/datasources/local_file_datasource.dart';
import 'package:novel_ide/data/datasources/database_helper.dart';
import 'package:novel_ide/data/datasources/secure_storage_datasource.dart';
import 'package:novel_ide/data/services/ai_service.dart';
import 'package:novel_ide/data/services/novel_memory.dart';
import 'package:novel_ide/data/services/workspace_agent.dart';
import 'package:novel_ide/data/services/web_search_service.dart';
import 'package:novel_ide/data/services/config_service.dart';
import 'package:novel_ide/data/services/workflow_engine.dart';
import 'package:uuid/uuid.dart';

/// 模糊匹配子Agent（精确ID → 中文名 → 关键词 → 描述）
TomatoAgent? fuzzyMatchAgent(String taskType, List<TomatoAgent> agents) {
  // 1. 精确ID匹配
  var match = agents.where((a) => a.id == taskType).firstOrNull;
  if (match != null) return match;
  // 2. 中文名匹配
  match = agents.where((a) => a.name == taskType).firstOrNull;
  if (match != null) return match;
  // 3. 中文名包含匹配
  match = agents
      .where((a) => a.name.contains(taskType) || taskType.contains(a.name))
      .firstOrNull;
  if (match != null) return match;
  // 4. 关键词映射
  final keywords = {
    'outline_generator': ['大纲', '剧情规划', '构思', '纲要', '概略'],
    'character_generator': ['角色', '人物', '设计', '反派', '主角', '配角'],
    'shuangdian_checker': ['爽点', '节奏', '高潮', '密度', '刺激'],
    'water_detector': ['水文', '质量', '废话', '拖', '注水'],
    'title_generator': ['标题', '书名', '起名', '爆款', '章名'],
    'humanize_zh': ['AI味', '润色', '自然', '人性化', '去机器', '去ai'],
  };
  final lower = taskType.toLowerCase();
  for (final entry in keywords.entries) {
    for (final kw in entry.value) {
      if (lower.contains(kw))
        return agents.where((a) => a.id == entry.key).firstOrNull;
    }
  }
  // 5. 描述包含匹配
  return agents.where((a) => a.description.contains(taskType)).firstOrNull;
}

/// 注册 delegate_to_sub_agent 执行器（共享逻辑，避免重复注册）
void _registerDelegateToSubAgent({
  required WorkspaceAgent agent,
  required List<TomatoAgent> presetAgents,
  required AiConfig aiConfig,
}) {
  agent.registerExecutor('delegate_to_sub_agent', (args) async {
    final taskType = args['task_type'] as String? ?? '';
    final instruction = args['instruction'] as String? ?? '';

    if (instruction.isEmpty) {
      return ToolResult.failure(
        toolName: 'delegate_to_sub_agent',
        error: '子代理指令不能为空',
      );
    }

    final subAgent = fuzzyMatchAgent(taskType, presetAgents);
    if (subAgent == null) {
      final available = presetAgents
          .map((a) => '  • ${a.id}（${a.name}）')
          .join('\n');
      return ToolResult.failure(
        toolName: 'delegate_to_sub_agent',
        error:
            '未找到匹配的子代理: "$taskType"\n\n可用的子代理：\n$available\n\n请用中文名或ID重新指定，例如："大纲生成器"或"outline_generator"',
      );
    }

    // 子Agent多轮推敲（最多3轮）
    try {
      final aiService = AiService();
      String currentInstruction = instruction;
      String? lastResult;

      for (int round = 0; round < 3; round++) {
        final prompt = round == 0
            ? currentInstruction
            : '请检查并优化你之前的结果。如有问题请修正，然后输出最终版本。\n\n之前的结果：\n$lastResult\n\n优化后的结果：';

        final result = await aiService.send(
          config: aiConfig,
          systemPrompt:
              '${subAgent.systemPrompt}\n\n你可以迭代优化你的输出。如果结果已经足够好，就直接确认。',
          userMessage: prompt,
          taskType: 'sub_agent:${subAgent.id}',
        );

        if (round == 0) {
          lastResult = result;
        } else {
          // 如果变化小于5%，认为已收敛，不再迭代
          if (result.isNotEmpty && lastResult != null) {
            final diff =
                (result.length - lastResult.length).abs() / lastResult.length;
            if (diff < 0.05) {
              lastResult = result;
              break;
            }
          }
          lastResult = result;
        }
      }

      return ToolResult.success(
        toolName: 'delegate_to_sub_agent',
        message: '【${subAgent.name}】返回结果：\n\n${lastResult ?? "（无输出）"}',
        data: {'agent_name': subAgent.name, 'agent_id': subAgent.id},
      );
    } catch (e) {
      return ToolResult.failure(
        toolName: 'delegate_to_sub_agent',
        error: '子代理「${subAgent.name}」执行失败: $e',
      );
    }
  });
}

/// 注册通用工具执行器（不需要小说上下文）
void registerGeneralToolExecutors({
  required WorkspaceAgent agent,
  required List<TomatoAgent> presetAgents,
  required AiConfig aiConfig,
  Function(String)? onSwitchNovel,
  Function(String novelId, String novelTitle)? onNovelCreated,
}) {
  // 配置管理
  agent.registerExecutor('get_ai_configs', (args) async {
    try {
      final db = DatabaseHelper();
      final maps = await db.getAllAiConfigs();
      if (maps.isEmpty)
        return ToolResult.success(
          toolName: 'get_ai_configs',
          message: '当前没有配置任何AI模型',
        );
      final storage = SecureStorageDataSource();
      final buffer = StringBuffer('已配置的AI模型：\n');
      for (final m in maps) {
        final apiKey = await storage.readApiKey(m['id'] as String);
        final config = db.fromDbMap(m, apiKey);
        final type = config.modelType.name;
        buffer.writeln(
          '- [${config.id}] ${config.name}（$type）: ${config.modelName}',
        );
      }
      return ToolResult.success(
        toolName: 'get_ai_configs',
        message: buffer.toString(),
      );
    } catch (e) {
      return ToolResult.failure(toolName: 'get_ai_configs', error: '获取失败: $e');
    }
  });

  agent.registerExecutor('add_ai_config', (args) async {
    try {
      final name = args['name'] as String? ?? '';
      final apiUrl = args['api_url'] as String? ?? '';
      final modelName = args['model_name'] as String? ?? '';
      final modelType = args['model_type'] as String? ?? 'text';
      final apiKey = args['api_key'] as String? ?? '';
      if (name.isEmpty || apiUrl.isEmpty || modelName.isEmpty) {
        return ToolResult.failure(
          toolName: 'add_ai_config',
          error: '名称、API地址、模型ID不能为空',
        );
      }
      final db = DatabaseHelper();
      final id = 'cfg_${DateTime.now().millisecondsSinceEpoch}';
      final config = AiConfig(
        id: id,
        name: name,
        apiUrl: apiUrl,
        modelName: modelName,
        modelType: modelType == 'tts'
            ? ModelType.tts
            : modelType == 'stt'
            ? ModelType.stt
            : ModelType.text,
      );
      await db.insertAiConfig(db.toDbMap(config));
      if (apiKey.isNotEmpty) {
        await SecureStorageDataSource().writeApiKey(id, apiKey);
      }
      return ToolResult.success(
        toolName: 'add_ai_config',
        message: '已添加AI模型「$name」($modelType)',
      );
    } catch (e) {
      return ToolResult.failure(toolName: 'add_ai_config', error: '添加失败: $e');
    }
  });

  agent.registerExecutor('set_active_ai_config', (args) async {
    try {
      final configId = args['config_id'] as String? ?? '';
      final purpose = args['purpose'] as String? ?? 'text';
      if (configId.isEmpty)
        return ToolResult.failure(
          toolName: 'set_active_ai_config',
          error: '请提供配置ID',
        );
      if (purpose == 'voice') {
        ConfigService.voiceConfigId = configId;
        return ToolResult.success(
          toolName: 'set_active_ai_config',
          message: '已设置语音模型',
        );
      } else {
        ConfigService.aiConfigId = configId;
        return ToolResult.success(
          toolName: 'set_active_ai_config',
          message: '已设置文本对话模型',
        );
      }
    } catch (e) {
      return ToolResult.failure(
        toolName: 'set_active_ai_config',
        error: '设置失败: $e',
      );
    }
  });

  // 项目管理
  agent.registerExecutor('list_novels', (args) async {
    try {
      final repo = NovelRepository();
      final novels = await repo.getAllNovels();
      if (novels.isEmpty)
        return ToolResult.success(toolName: 'list_novels', message: '当前没有小说项目');
      final buffer = StringBuffer('小说项目列表：\n');
      for (final n in novels) {
        buffer.writeln('- [${n.id}] ${n.title}（${n.category ?? '未分类'}）');
      }
      return ToolResult.success(
        toolName: 'list_novels',
        message: buffer.toString(),
      );
    } catch (e) {
      return ToolResult.failure(toolName: 'list_novels', error: '获取失败: $e');
    }
  });

  agent.registerExecutor('create_novel', (args) async {
    try {
      final title = args['title'] as String? ?? '';
      final genre = args['genre'] as String? ?? '';
      final description = args['description'] as String? ?? '';
      if (title.isEmpty)
        return ToolResult.failure(toolName: 'create_novel', error: '标题不能为空');
      final repo = NovelRepository();
      final novel = await repo.createNovel(
        title: title,
        category: genre,
        description: description,
      );
      // 调用回调，通知UI刷新并选中新创建的小说
      onNovelCreated?.call(novel.id, novel.title);
      return ToolResult.success(
        toolName: 'create_novel',
        message: '已创建小说「$title」(ID: ${novel.id})',
        data: {'novel_id': novel.id},
      );
    } catch (e) {
      return ToolResult.failure(toolName: 'create_novel', error: '创建失败: $e');
    }
  });

  agent.registerExecutor('switch_novel', (args) async {
    try {
      final novelId = args['novel_id'] as String? ?? '';
      if (novelId.isEmpty)
        return ToolResult.failure(toolName: 'switch_novel', error: '请提供小说ID');
      // 查找小说标题
      final repo = NovelRepository();
      final novels = await repo.getAllNovels();
      final novel = novels.where((n) => n.id == novelId).firstOrNull;
      if (novel == null)
        return ToolResult.failure(
          toolName: 'switch_novel',
          error: '未找到ID为 $novelId 的小说',
        );
      // 通过回调切换选中的小说
      onSwitchNovel?.call(novelId);
      return ToolResult.success(
        toolName: 'switch_novel',
        message: '已切换到小说「${novel.title}」(ID: $novelId)',
      );
    } catch (e) {
      return ToolResult.failure(toolName: 'switch_novel', error: '切换失败: $e');
    }
  });

  // ====== 子代理调度 ======

  _registerDelegateToSubAgent(
    agent: agent,
    presetAgents: presetAgents,
    aiConfig: aiConfig,
  );

  // ====== 文本处理工具 ======

  agent.registerExecutor('humanize_text', (args) async {
    final text = args['text'] as String? ?? '';
    if (text.isEmpty)
      return ToolResult.failure(
        toolName: 'humanize_text',
        error: '请提供需要去AI味的文本',
      );
    // 此工具由AI直接处理：AI读取工具描述中的Humanizer规则，对文本进行改写
    // 执行器仅做输入校验，实际改写由AI对话层完成
    return ToolResult.success(
      toolName: 'humanize_text',
      message: '请根据工具描述中的Humanizer规则，对以下文本进行去AI味改写：\n\n$text',
    );
  });

  // ====== 联网搜索工具 ======

  agent.registerExecutor('web_search', (args) async {
    try {
      final query = args['query'] as String? ?? '';
      if (query.isEmpty) {
        return ToolResult.failure(toolName: 'web_search', error: '请提供搜索关键词');
      }
      final results = await WebSearchService.search(query);
      if (results.isEmpty) {
        return ToolResult.success(
          toolName: 'web_search',
          message: '未找到与「$query」相关的搜索结果。',
        );
      }
      final buffer = StringBuffer('搜索「$query」的结果（共${results.length}条）：\n\n');
      for (int i = 0; i < results.length; i++) {
        final r = results[i];
        buffer.writeln('${i + 1}. ${r.title}');
        buffer.writeln('   ${r.snippet}');
        if (r.url.isNotEmpty) {
          buffer.writeln('   ${r.url}');
        }
        buffer.writeln();
      }
      return ToolResult.success(
        toolName: 'web_search',
        message: buffer.toString(),
      );
    } catch (e) {
      return ToolResult.failure(toolName: 'web_search', error: '搜索失败: $e');
    }
  });
}

/// 注册所有Agent工具执行器
/// 将工具名连接到实际的数据操作
void registerAllToolExecutors({
  required WorkspaceAgent agent,
  required String novelId,
  required String novelTitle,
  required List<TomatoAgent> presetAgents,
  required AiConfig aiConfig,
}) {
  final materialRepo = MaterialRepository();
  final chapterRepo = ChapterRepository();
  final fs = LocalFileDataSource();
  final skillRepo = SkillRepository();
  final uuid = Uuid();

  // ====== 读取类工具 ======

  agent.registerExecutor('get_novel_info', (args) async {
    final chapters = await chapterRepo.getChaptersByNovel(novelId);
    final totalWords = chapters.fold<int>(0, (sum, c) => sum + c.wordCount);
    return ToolResult.success(
      toolName: 'get_novel_info',
      message:
          '小说信息：\n标题：$novelTitle\nID：$novelId\n章节数：${chapters.length}\n总字数：$totalWords',
    );
  });

  agent.registerExecutor('get_characters', (args) async {
    final characters = await materialRepo.getCharacters(novelId);
    if (characters.isEmpty)
      return ToolResult.success(toolName: 'get_characters', message: '暂无角色');
    final info = characters
        .map(
          (c) =>
              '- ${c.name}${c.role != null ? " (${c.role})" : ""}：${c.description ?? "无描述"}',
        )
        .join('\n');
    return ToolResult.success(
      toolName: 'get_characters',
      message: '角色列表（${characters.length}个）：\n$info',
    );
  });

  agent.registerExecutor('get_settings', (args) async {
    final settings = await materialRepo.getSettingCards(novelId);
    if (settings.isEmpty)
      return ToolResult.success(toolName: 'get_settings', message: '暂无设定');
    final info = settings
        .map(
          (s) =>
              '- ${s.name}${s.category != null ? " [${s.category}]" : ""}：${s.description ?? "无内容"}',
        )
        .join('\n');
    return ToolResult.success(
      toolName: 'get_settings',
      message: '设定列表（${settings.length}个）：\n$info',
    );
  });

  agent.registerExecutor('get_locations', (args) async {
    final locations = await materialRepo.getLocations(novelId);
    if (locations.isEmpty)
      return ToolResult.success(toolName: 'get_locations', message: '暂无地点');
    final info = locations
        .map(
          (l) =>
              '- ${l.name}${l.category != null ? " [${l.category}]" : ""}：${l.description ?? "无描述"}',
        )
        .join('\n');
    return ToolResult.success(
      toolName: 'get_locations',
      message: '地点列表（${locations.length}个）：\n$info',
    );
  });

  agent.registerExecutor('get_factions', (args) async {
    final factions = await materialRepo.getFactions(novelId);
    if (factions.isEmpty)
      return ToolResult.success(toolName: 'get_factions', message: '暂无势力');
    final info = factions
        .map(
          (f) =>
              '- ${f.name}${f.category != null ? " [${f.category}]" : ""}：${f.description ?? "无描述"}',
        )
        .join('\n');
    return ToolResult.success(
      toolName: 'get_factions',
      message: '势力列表（${factions.length}个）：\n$info',
    );
  });

  agent.registerExecutor('get_items', (args) async {
    final items = await materialRepo.getItems(novelId);
    if (items.isEmpty)
      return ToolResult.success(toolName: 'get_items', message: '暂无道具');
    final info = items
        .map(
          (i) =>
              '- ${i.name}${i.category != null ? " [${i.category}]" : ""}：${i.description ?? "无描述"}',
        )
        .join('\n');
    return ToolResult.success(
      toolName: 'get_items',
      message: '道具列表（${items.length}个）：\n$info',
    );
  });

  agent.registerExecutor('get_hooks', (args) async {
    final hooks = await materialRepo.getPlotHooks(novelId);
    if (hooks.isEmpty)
      return ToolResult.success(toolName: 'get_hooks', message: '暂无伏笔');
    final info = hooks
        .map(
          (h) =>
              '- ${h.title} [${h.isRevealed ? "已回收" : "待回收"}]：${h.description ?? "无描述"}',
        )
        .join('\n');
    return ToolResult.success(
      toolName: 'get_hooks',
      message: '伏笔列表（${hooks.length}个）：\n$info',
    );
  });

  agent.registerExecutor('get_references', (args) async {
    final refs = await materialRepo.getReferences(novelId);
    if (refs.isEmpty)
      return ToolResult.success(toolName: 'get_references', message: '暂无参考');
    final info = refs
        .map((r) => '- ${r.title}：${r.content ?? "无内容"}')
        .join('\n');
    return ToolResult.success(
      toolName: 'get_references',
      message: '参考列表（${refs.length}个）：\n$info',
    );
  });

  agent.registerExecutor('get_chapters', (args) async {
    final chapters = await chapterRepo.getChaptersByNovel(novelId);
    if (chapters.isEmpty)
      return ToolResult.success(toolName: 'get_chapters', message: '暂无章节');
    final info = chapters
        .map((c) => '- ${c.title}（${c.wordCount}字）')
        .join('\n');
    return ToolResult.success(
      toolName: 'get_chapters',
      message: '章节列表（${chapters.length}章）：\n$info',
    );
  });

  agent.registerExecutor('get_chapter_content', (args) async {
    final title = args['chapter_title'] as String? ?? '';
    if (title.isEmpty)
      return ToolResult.failure(
        toolName: 'get_chapter_content',
        error: '章节标题不能为空',
      );
    final chapters = await chapterRepo.getChaptersByNovel(novelId);
    final match = chapters.where((c) => c.title.contains(title));
    if (match.isEmpty)
      return ToolResult.failure(
        toolName: 'get_chapter_content',
        error: '未找到匹配的章节',
      );
    final chapter = match.first;
    final projectPath = await fs.getProjectDir(novelId, novelTitle);
    final content = await fs.readChapterContent(projectPath, chapter.id);
    return ToolResult.success(
      toolName: 'get_chapter_content',
      message: '【${chapter.title}】\n$content',
    );
  });

  agent.registerExecutor('get_memory', (args) async {
    try {
      final db = await DatabaseHelper().database;
      final repo = MemoryRepository(db: db, profileId: novelId);
      final query = (args['query'] as String?) ?? '*';
      final results = await repo.searchMemories(
        query: query,
        novelId: novelId,
      );
      if (results.isEmpty) {
        // 回退到旧的记忆文件系统
        final memory = NovelMemory(
          novelId: novelId,
          novelTitle: novelTitle,
        );
        final content = await memory.autoUpdate();
        return ToolResult.success(
          toolName: 'get_memory',
          message: content.isEmpty ? '记忆为空' : content,
        );
      }
      // 按重要性排序，取 top 20
      final sorted = List<Memory>.from(results)
        ..sort((a, b) => b.importance.compareTo(a.importance));
      final selected = sorted.take(20);
      final buf = StringBuffer();
      buf.writeln('记忆检索结果（${results.length}条，显示top ${selected.length}）：');
      for (final m in selected) {
        buf.writeln('· [${m.importance.toStringAsFixed(1)}] ${m.title}: ${m.content}');
      }
      return ToolResult.success(
        toolName: 'get_memory',
        message: buf.toString(),
      );
    } catch (e) {
      // 查询失败时回退到旧的记忆文件系统
      final memory = NovelMemory(novelId: novelId, novelTitle: novelTitle);
      final content = await memory.autoUpdate();
      return ToolResult.success(
        toolName: 'get_memory',
        message: content.isEmpty ? '记忆为空' : content,
      );
    }
  });

  // ====== 写入类工具 ======

  agent.registerExecutor('add_character', (args) async {
    final name = args['name'] as String? ?? '';
    final role = args['role'] as String?;
    final description = args['description'] as String?;
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'add_character', error: '角色名称不能为空');
    final characters = await materialRepo.getCharacters(novelId);
    characters.add(
      Character(
        id: uuid.v4(),
        novelId: novelId,
        name: name,
        role: role,
        description: description,
      ),
    );
    await materialRepo.saveCharacters(novelId, characters);
    return ToolResult.success(
      toolName: 'add_character',
      message: '已添加角色：$name',
    );
  });

  agent.registerExecutor('add_setting', (args) async {
    final name = args['name'] as String? ?? '';
    final category = args['category'] as String?;
    final description = args['description'] as String?;
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'add_setting', error: '设定名称不能为空');
    final settings = await materialRepo.getSettingCards(novelId);
    settings.add(
      SettingCard(
        id: uuid.v4(),
        novelId: novelId,
        name: name,
        category: category,
        description: description,
      ),
    );
    await materialRepo.saveSettingCards(novelId, settings);
    return ToolResult.success(toolName: 'add_setting', message: '已添加设定：$name');
  });

  agent.registerExecutor('add_location', (args) async {
    final name = args['name'] as String? ?? '';
    final category = args['category'] as String?;
    final description = args['description'] as String?;
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'add_location', error: '地点名称不能为空');
    final locations = await materialRepo.getLocations(novelId);
    locations.add(
      Location(
        id: uuid.v4(),
        novelId: novelId,
        name: name,
        category: category,
        description: description,
      ),
    );
    await materialRepo.saveLocations(novelId, locations);
    return ToolResult.success(toolName: 'add_location', message: '已添加地点：$name');
  });

  agent.registerExecutor('add_faction', (args) async {
    final name = args['name'] as String? ?? '';
    final category = args['category'] as String?;
    final description = args['description'] as String?;
    final leader = args['leader'] as String?;
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'add_faction', error: '势力名称不能为空');
    final factions = await materialRepo.getFactions(novelId);
    factions.add(
      Faction(
        id: uuid.v4(),
        novelId: novelId,
        name: name,
        category: category,
        description: description,
        leader: leader,
      ),
    );
    await materialRepo.saveFactions(novelId, factions);
    return ToolResult.success(toolName: 'add_faction', message: '已添加势力：$name');
  });

  agent.registerExecutor('add_item', (args) async {
    final name = args['name'] as String? ?? '';
    final category = args['category'] as String?;
    final description = args['description'] as String?;
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'add_item', error: '道具名称不能为空');
    final items = await materialRepo.getItems(novelId);
    items.add(
      Item(
        id: uuid.v4(),
        novelId: novelId,
        name: name,
        category: category,
        description: description,
      ),
    );
    await materialRepo.saveItems(novelId, items);
    return ToolResult.success(toolName: 'add_item', message: '已添加道具：$name');
  });

  agent.registerExecutor('add_hook', (args) async {
    final title = args['title'] as String? ?? '';
    final description = args['description'] as String?;
    if (title.isEmpty)
      return ToolResult.failure(toolName: 'add_hook', error: '伏笔标题不能为空');
    final hooks = await materialRepo.getPlotHooks(novelId);
    hooks.add(
      PlotHook(
        id: uuid.v4(),
        novelId: novelId,
        title: title,
        description: description,
      ),
    );
    await materialRepo.savePlotHooks(novelId, hooks);
    return ToolResult.success(toolName: 'add_hook', message: '已添加伏笔：$title');
  });

  agent.registerExecutor('add_reference', (args) async {
    final title = args['title'] as String? ?? '';
    final content = args['content'] as String?;
    if (title.isEmpty)
      return ToolResult.failure(toolName: 'add_reference', error: '参考标题不能为空');
    final refs = await materialRepo.getReferences(novelId);
    refs.add(
      ReferenceMaterial(
        id: uuid.v4(),
        novelId: novelId,
        title: title,
        content: content,
      ),
    );
    await materialRepo.saveReferences(novelId, refs);
    return ToolResult.success(
      toolName: 'add_reference',
      message: '已添加参考：$title',
    );
  });

  // ====== 编辑类工具 ======

  agent.registerExecutor('update_character', (args) async {
    final name = args['name'] as String? ?? '';
    if (name.isEmpty)
      return ToolResult.failure(
        toolName: 'update_character',
        error: '角色名称不能为空',
      );
    final characters = await materialRepo.getCharacters(novelId);
    final idx = characters.indexWhere((c) => c.name == name);
    if (idx < 0)
      return ToolResult.failure(
        toolName: 'update_character',
        error: '未找到角色：$name',
      );
    final old = characters[idx];
    if (args['role'] != null ||
        args['description'] != null ||
        args['personality'] != null ||
        args['appearance'] != null ||
        args['background'] != null) {
      characters[idx] = Character(
        id: old.id,
        novelId: novelId,
        name: name,
        role: args['role'] as String? ?? old.role,
        description: args['description'] as String? ?? old.description,
        personality: args['personality'] as String? ?? old.personality,
        appearance: args['appearance'] as String? ?? old.appearance,
        background: args['background'] as String? ?? old.background,
        tags: old.tags,
      );
    }
    await materialRepo.saveCharacters(novelId, characters);
    return ToolResult.success(
      toolName: 'update_character',
      message: '已更新角色：$name',
    );
  });

  agent.registerExecutor('update_hook_status', (args) async {
    final title = args['title'] as String? ?? '';
    final status = args['status'] as String? ?? 'planted';
    if (title.isEmpty)
      return ToolResult.failure(
        toolName: 'update_hook_status',
        error: '伏笔标题不能为空',
      );
    final hooks = await materialRepo.getPlotHooks(novelId);
    final idx = hooks.indexWhere((h) => h.title == title);
    if (idx < 0)
      return ToolResult.failure(
        toolName: 'update_hook_status',
        error: '未找到伏笔：$title',
      );
    final isRevealed = status == 'resolved';
    hooks[idx] = PlotHook(
      id: hooks[idx].id,
      novelId: novelId,
      title: title,
      description: hooks[idx].description,
      isRevealed: isRevealed,
    );
    await materialRepo.savePlotHooks(novelId, hooks);
    return ToolResult.success(
      toolName: 'update_hook_status',
      message: '已更新伏笔「$title」状态为：${isRevealed ? "已回收" : "待回收"}',
    );
  });

  agent.registerExecutor('update_setting', (args) async {
    final name = args['name'] as String? ?? '';
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'update_setting', error: '设定名称不能为空');
    final settings = await materialRepo.getSettingCards(novelId);
    final idx = settings.indexWhere((s) => s.name == name);
    if (idx < 0)
      return ToolResult.failure(
        toolName: 'update_setting',
        error: '未找到设定：$name',
      );
    final old = settings[idx];
    settings[idx] = SettingCard(
      id: old.id,
      novelId: novelId,
      name: name,
      category: args['category'] as String? ?? old.category,
      description: args['description'] as String? ?? old.description,
      tags: old.tags,
    );
    await materialRepo.saveSettingCards(novelId, settings);
    return ToolResult.success(
      toolName: 'update_setting',
      message: '已更新设定：$name',
    );
  });

  agent.registerExecutor('update_location', (args) async {
    final name = args['name'] as String? ?? '';
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'update_location', error: '地点名称不能为空');
    final locations = await materialRepo.getLocations(novelId);
    final idx = locations.indexWhere((l) => l.name == name);
    if (idx < 0)
      return ToolResult.failure(
        toolName: 'update_location',
        error: '未找到地点：$name',
      );
    final old = locations[idx];
    locations[idx] = Location(
      id: old.id,
      novelId: novelId,
      name: name,
      category: args['category'] as String? ?? old.category,
      description: args['description'] as String? ?? old.description,
      features: args['features'] as String? ?? old.features,
      rules: args['rules'] as String? ?? old.rules,
      tags: old.tags,
    );
    await materialRepo.saveLocations(novelId, locations);
    return ToolResult.success(
      toolName: 'update_location',
      message: '已更新地点：$name',
    );
  });

  agent.registerExecutor('update_faction', (args) async {
    final name = args['name'] as String? ?? '';
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'update_faction', error: '势力名称不能为空');
    final factions = await materialRepo.getFactions(novelId);
    final idx = factions.indexWhere((f) => f.name == name);
    if (idx < 0)
      return ToolResult.failure(
        toolName: 'update_faction',
        error: '未找到势力：$name',
      );
    final old = factions[idx];
    factions[idx] = Faction(
      id: old.id,
      novelId: novelId,
      name: name,
      category: args['category'] as String? ?? old.category,
      description: args['description'] as String? ?? old.description,
      leader: args['leader'] as String? ?? old.leader,
      strength: args['strength'] as String? ?? old.strength,
      members: old.members,
      tags: old.tags,
    );
    await materialRepo.saveFactions(novelId, factions);
    return ToolResult.success(
      toolName: 'update_faction',
      message: '已更新势力：$name',
    );
  });

  agent.registerExecutor('update_item', (args) async {
    final name = args['name'] as String? ?? '';
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'update_item', error: '道具名称不能为空');
    final items = await materialRepo.getItems(novelId);
    final idx = items.indexWhere((i) => i.name == name);
    if (idx < 0)
      return ToolResult.failure(toolName: 'update_item', error: '未找到道具：$name');
    final old = items[idx];
    final isKey = args['isKeyItem'] as bool?;
    items[idx] = Item(
      id: old.id,
      novelId: novelId,
      name: name,
      category: args['category'] as String? ?? old.category,
      description: args['description'] as String? ?? old.description,
      powerLevel: args['powerLevel'] as String? ?? old.powerLevel,
      owner: args['owner'] as String? ?? old.owner,
      isKeyItem: isKey ?? old.isKeyItem,
      tags: old.tags,
    );
    await materialRepo.saveItems(novelId, items);
    return ToolResult.success(toolName: 'update_item', message: '已更新道具：$name');
  });

  agent.registerExecutor('update_reference', (args) async {
    final title = args['title'] as String? ?? '';
    if (title.isEmpty)
      return ToolResult.failure(
        toolName: 'update_reference',
        error: '参考标题不能为空',
      );
    final refs = await materialRepo.getReferences(novelId);
    final idx = refs.indexWhere((r) => r.title == title);
    if (idx < 0)
      return ToolResult.failure(
        toolName: 'update_reference',
        error: '未找到参考：$title',
      );
    final old = refs[idx];
    refs[idx] = ReferenceMaterial(
      id: old.id,
      novelId: novelId,
      title: title,
      content: args['content'] as String? ?? old.content,
      source: args['source'] as String? ?? old.source,
      sourceUrl: args['sourceUrl'] as String? ?? old.sourceUrl,
    );
    await materialRepo.saveReferences(novelId, refs);
    return ToolResult.success(
      toolName: 'update_reference',
      message: '已更新参考：$title',
    );
  });

  // ====== 删除类工具 ======

  agent.registerExecutor('delete_character', (args) async {
    final name = args['name'] as String? ?? '';
    if (name.isEmpty)
      return ToolResult.failure(
        toolName: 'delete_character',
        error: '角色名称不能为空',
      );
    final characters = await materialRepo.getCharacters(novelId);
    final idx = characters.indexWhere((c) => c.name == name);
    if (idx < 0)
      return ToolResult.failure(
        toolName: 'delete_character',
        error: '未找到角色：$name',
      );
    characters.removeAt(idx);
    await materialRepo.saveCharacters(novelId, characters);
    return ToolResult.success(
      toolName: 'delete_character',
      message: '已删除角色：$name',
    );
  });

  agent.registerExecutor('delete_setting', (args) async {
    final name = args['name'] as String? ?? '';
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'delete_setting', error: '设定名称不能为空');
    final settings = await materialRepo.getSettingCards(novelId);
    final idx = settings.indexWhere((s) => s.name == name);
    if (idx < 0)
      return ToolResult.failure(
        toolName: 'delete_setting',
        error: '未找到设定：$name',
      );
    settings.removeAt(idx);
    await materialRepo.saveSettingCards(novelId, settings);
    return ToolResult.success(
      toolName: 'delete_setting',
      message: '已删除设定：$name',
    );
  });

  agent.registerExecutor('delete_location', (args) async {
    final name = args['name'] as String? ?? '';
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'delete_location', error: '地点名称不能为空');
    final locations = await materialRepo.getLocations(novelId);
    final idx = locations.indexWhere((l) => l.name == name);
    if (idx < 0)
      return ToolResult.failure(
        toolName: 'delete_location',
        error: '未找到地点：$name',
      );
    locations.removeAt(idx);
    await materialRepo.saveLocations(novelId, locations);
    return ToolResult.success(
      toolName: 'delete_location',
      message: '已删除地点：$name',
    );
  });

  agent.registerExecutor('delete_faction', (args) async {
    final name = args['name'] as String? ?? '';
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'delete_faction', error: '势力名称不能为空');
    final factions = await materialRepo.getFactions(novelId);
    final idx = factions.indexWhere((f) => f.name == name);
    if (idx < 0)
      return ToolResult.failure(
        toolName: 'delete_faction',
        error: '未找到势力：$name',
      );
    factions.removeAt(idx);
    await materialRepo.saveFactions(novelId, factions);
    return ToolResult.success(
      toolName: 'delete_faction',
      message: '已删除势力：$name',
    );
  });

  agent.registerExecutor('delete_item', (args) async {
    final name = args['name'] as String? ?? '';
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'delete_item', error: '道具名称不能为空');
    final items = await materialRepo.getItems(novelId);
    final idx = items.indexWhere((i) => i.name == name);
    if (idx < 0)
      return ToolResult.failure(toolName: 'delete_item', error: '未找到道具：$name');
    items.removeAt(idx);
    await materialRepo.saveItems(novelId, items);
    return ToolResult.success(toolName: 'delete_item', message: '已删除道具：$name');
  });

  agent.registerExecutor('delete_hook', (args) async {
    final title = args['title'] as String? ?? '';
    if (title.isEmpty)
      return ToolResult.failure(toolName: 'delete_hook', error: '伏笔标题不能为空');
    final hooks = await materialRepo.getPlotHooks(novelId);
    final idx = hooks.indexWhere((h) => h.title == title);
    if (idx < 0)
      return ToolResult.failure(toolName: 'delete_hook', error: '未找到伏笔：$title');
    hooks.removeAt(idx);
    await materialRepo.savePlotHooks(novelId, hooks);
    return ToolResult.success(toolName: 'delete_hook', message: '已删除伏笔：$title');
  });

  agent.registerExecutor('delete_reference', (args) async {
    final title = args['title'] as String? ?? '';
    if (title.isEmpty)
      return ToolResult.failure(
        toolName: 'delete_reference',
        error: '参考标题不能为空',
      );
    final refs = await materialRepo.getReferences(novelId);
    final idx = refs.indexWhere((r) => r.title == title);
    if (idx < 0)
      return ToolResult.failure(
        toolName: 'delete_reference',
        error: '未找到参考：$title',
      );
    refs.removeAt(idx);
    await materialRepo.saveReferences(novelId, refs);
    return ToolResult.success(
      toolName: 'delete_reference',
      message: '已删除参考：$title',
    );
  });

  // ====== 分析类工具 ======

  agent.registerExecutor('analyze_plot_consistency', (args) async {
    final chapters = await chapterRepo.getChaptersByNovel(novelId);
    final hooks = await materialRepo.getPlotHooks(novelId);
    final characters = await materialRepo.getCharacters(novelId);
    final idleHooks = hooks.where((h) => !h.isRevealed).length;
    return ToolResult.success(
      toolName: 'analyze_plot_consistency',
      message:
          '剧情一致性分析：\n- 章节数：${chapters.length}\n- 角色数：${characters.length}\n- 未回收伏笔：$idleHooks\n\n请根据以上数据和小说内容进行详细分析。',
    );
  });

  agent.registerExecutor('check_idle_hooks', (args) async {
    final hooks = await materialRepo.getPlotHooks(novelId);
    final planted = hooks.where((h) => !h.isRevealed).toList();
    if (planted.isEmpty)
      return ToolResult.success(
        toolName: 'check_idle_hooks',
        message: '没有未回收的伏笔',
      );
    final info = planted
        .map(
          (h) => '- ${h.title}（闲置${h.idleChapters}章）：${h.description ?? "无描述"}',
        )
        .join('\n');
    return ToolResult.success(
      toolName: 'check_idle_hooks',
      message: '闲置伏笔（${planted.length}个）：\n$info',
    );
  });

  agent.registerExecutor('generate_chapter_outline', (args) async {
    final direction = args['direction'] as String? ?? '';
    final chapters = await chapterRepo.getChaptersByNovel(novelId);
    final recentTitles = chapters.length > 3
        ? chapters.sublist(chapters.length - 3).map((c) => c.title).join('、')
        : '无';
    return ToolResult.success(
      toolName: 'generate_chapter_outline',
      message:
          '请根据以下信息生成下一章大纲：\n- 当前共${chapters.length}章\n- 最近章节：$recentTitles\n- 写作方向：${direction.isEmpty ? "无特殊要求" : direction}',
    );
  });

  agent.registerExecutor('character_relationship_map', (args) async {
    final characters = await materialRepo.getCharacters(novelId);
    if (characters.isEmpty)
      return ToolResult.success(
        toolName: 'character_relationship_map',
        message: '暂无角色',
      );
    final info = characters
        .map((c) => '${c.name}${c.role != null ? "(${c.role})" : ""}')
        .join('、');
    return ToolResult.success(
      toolName: 'character_relationship_map',
      message: '角色列表：$info\n请根据小说内容分析角色之间的关系。',
    );
  });

  // ====== Skill工具 ======

  agent.registerExecutor('get_skills', (args) async {
    final context = await skillRepo.getEnabledSkillsContext();
    return ToolResult.success(
      toolName: 'get_skills',
      message: context.isEmpty ? '没有启用的Skill' : context,
    );
  });

  agent.registerExecutor('add_skill', (args) async {
    final name = args['name'] as String? ?? '';
    final category = args['category'] as String? ?? '通用';
    final description = args['description'] as String? ?? '';
    final content = args['content'] as String? ?? '';
    if (name.isEmpty)
      return ToolResult.failure(toolName: 'add_skill', error: 'Skill名称不能为空');
    final skill = skillRepo.createSkill(
      name: name,
      category: category,
      description: description,
      content: content,
    );
    await skillRepo.addSkill(skill);
    return ToolResult.success(toolName: 'add_skill', message: '已添加Skill：$name');
  });

  // ====== 子代理和工作流 ======

  _registerDelegateToSubAgent(
    agent: agent,
    presetAgents: presetAgents,
    aiConfig: aiConfig,
  );

  agent.registerExecutor('run_workflow', (args) async {
    final workflowName = args['workflow_name'] as String? ?? '';
    final workflow = WorkflowPresets.all
        .where((w) => w.id == workflowName)
        .firstOrNull;
    if (workflow == null) {
      return ToolResult.failure(
        toolName: 'run_workflow',
        error:
            '未找到工作流：$workflowName\n可用工作流：${WorkflowPresets.all.map((w) => w.id).join(', ')}',
      );
    }

    // 依次执行工作流步骤
    final results = <String>[];
    for (final step in workflow.steps) {
      final executor = agent.getExecutor(step.toolName);
      if (executor != null) {
        try {
          final result = await executor(step.toolArgs);
          results.add('✅ ${step.name}：${result.message}');
        } catch (e) {
          results.add('❌ ${step.name}：执行失败 $e');
        }
      } else {
        results.add('⚠️ ${step.name}：工具未注册');
      }
    }

    return ToolResult.success(
      toolName: 'run_workflow',
      message: '工作流「${workflow.name}」执行完成：\n\n${results.join('\n')}',
    );
  });

  // ====== 编辑器操作 ======

  agent.registerExecutor('write_chapter_content', (args) async {
    try {
      final chapterId = args['chapter_id'] as String? ?? '';
      final content = args['content'] as String? ?? '';
      if (chapterId.isEmpty)
        return ToolResult.failure(
          toolName: 'write_chapter_content',
          error: '章节ID不能为空',
        );
      final chapter = await chapterRepo.getChapter(chapterId);
      if (chapter == null)
        return ToolResult.failure(
          toolName: 'write_chapter_content',
          error: '未找到章节：$chapterId',
        );
      final updatedChapter = chapter.copyWith(
        content: content,
        wordCount: content.length,
      );
      await chapterRepo.updateChapter(updatedChapter);
      return ToolResult.success(
        toolName: 'write_chapter_content',
        message: '已写入章节内容（${content.length}字）',
      );
    } catch (e) {
      return ToolResult.failure(
        toolName: 'write_chapter_content',
        error: '写入失败: $e',
      );
    }
  });

  agent.registerExecutor('create_chapter', (args) async {
    try {
      final volumeId = args['volume_id'] as String? ?? '';
      final title = args['title'] as String? ?? '新章节';
      final content = args['content'] as String? ?? '';
      if (volumeId.isEmpty)
        return ToolResult.failure(toolName: 'create_chapter', error: '卷ID不能为空');
      final chapter = await chapterRepo.createChapter(
        novelId: novelId,
        volumeId: volumeId,
        title: title,
      );
      if (content.isNotEmpty) {
        final updatedChapter = chapter.copyWith(
          content: content,
          wordCount: content.length,
        );
        await chapterRepo.updateChapter(updatedChapter);
      }
      return ToolResult.success(
        toolName: 'create_chapter',
        message: '已创建章节「$title」(ID: ${chapter.id})',
        data: {'chapter_id': chapter.id},
      );
    } catch (e) {
      return ToolResult.failure(toolName: 'create_chapter', error: '创建失败: $e');
    }
  });
}
