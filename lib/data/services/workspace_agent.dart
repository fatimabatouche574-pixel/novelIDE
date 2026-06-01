import 'dart:convert';
import 'package:novel_ide/data/models/ai_config_model.dart';
import 'package:novel_ide/data/services/ai_service.dart' show AiService;

/// Agent工具定义
class AgentTool {
  final String name;
  final String description;
  final Map<String, String> parameters;
  final String category; // 工具分类，用于按需加载

  const AgentTool({
    required this.name,
    required this.description,
    this.parameters = const {},
    this.category = 'general',
  });

  Map<String, dynamic> toOpenAiFormat() {
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': parameters,
          'required': parameters.keys.toList(),
        },
      },
    };
  }
}

/// Agent工具执行结果
class ToolResult {
  final String toolName;
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  const ToolResult({
    required this.toolName,
    required this.success,
    required this.message,
    this.data,
  });
}

/// Agent工具执行器接口
typedef ToolExecutor = Future<ToolResult> Function(Map<String, dynamic> args);

/// 工具分类常量
class ToolCategories {
  static const String read = 'read'; // 读取类
  static const String write = 'write'; // 写入类
  static const String edit = 'edit'; // 编辑类
  static const String analyze = 'analyze'; // 分析类
  static const String agent = 'agent'; // 子代理
  static const String skill = 'skill'; // 技能
  static const String config = 'config'; // 配置管理
  static const String project = 'project'; // 项目管理
  static const String editor = 'editor'; // 编辑器
}

/// Workspace Agent - AI IDE 核心协调层
/// 架构：主对话轻量 → 按需加载工具 → 独立执行 → 结果回传
class WorkspaceAgent {
  final AiService _aiService = AiService();

  /// 所有可用工具（按分类组织）
  static final List<AgentTool> tools = [
    // ====== 读取类工具 ======
    AgentTool(
      name: 'get_novel_info',
      description: '获取当前小说的基本信息',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_characters',
      description: '获取小说的所有角色列表',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_settings',
      description: '获取小说的所有设定卡',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_locations',
      description: '获取小说的所有地点',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_factions',
      description: '获取小说的所有势力/组织',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_items',
      description: '获取小说的所有道具/物品',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_hooks',
      description: '获取小说的所有伏笔',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_references',
      description: '获取小说的所有参考资料',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_chapters',
      description: '获取小说的章节列表',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_chapter_content',
      description: '获取指定章节的内容',
      parameters: {'chapter_title': '章节标题'},
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_memory',
      description: '获取小说的记忆包内容',
      category: ToolCategories.read,
    ),

    // ====== 写入类工具 ======
    AgentTool(
      name: 'add_character',
      description: '添加新角色到资料库',
      parameters: {'name': '角色名称', 'role': '角色定位', 'description': '角色描述'},
      category: ToolCategories.write,
    ),
    AgentTool(
      name: 'add_setting',
      description: '添加新设定到资料库',
      parameters: {'name': '设定名称', 'category': '分类', 'description': '设定描述'},
      category: ToolCategories.write,
    ),
    AgentTool(
      name: 'add_location',
      description: '添加新地点到资料库',
      parameters: {'name': '地点名称', 'category': '分类', 'description': '地点描述'},
      category: ToolCategories.write,
    ),
    AgentTool(
      name: 'add_faction',
      description: '添加新势力到资料库',
      parameters: {
        'name': '势力名称',
        'category': '分类',
        'description': '势力描述',
        'leader': '首领名称（可选）',
      },
      category: ToolCategories.write,
    ),
    AgentTool(
      name: 'add_item',
      description: '添加新道具到资料库',
      parameters: {'name': '道具名称', 'category': '分类', 'description': '道具描述'},
      category: ToolCategories.write,
    ),
    AgentTool(
      name: 'add_hook',
      description: '添加新伏笔',
      parameters: {'title': '伏笔标题', 'description': '伏笔描述'},
      category: ToolCategories.write,
    ),
    AgentTool(
      name: 'add_reference',
      description: '添加参考资料',
      parameters: {'title': '参考标题', 'content': '参考内容'},
      category: ToolCategories.write,
    ),

    // ====== 编辑类工具 ======
    AgentTool(
      name: 'update_character',
      description: '更新已有角色信息',
      parameters: {
        'name': '角色名称',
        'role': '新定位（可选）',
        'description': '新描述（可选）',
        'personality': '性格特征（可选）',
        'appearance': '外貌描述（可选）',
        'background': '背景故事（可选）',
      },
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'update_hook_status',
      description: '更新伏笔状态',
      parameters: {'title': '伏笔标题', 'status': 'planted/resolved/idle'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'update_setting',
      description: '更新已有设定信息',
      parameters: {
        'name': '设定名称',
        'category': '新分类（可选）',
        'description': '新描述（可选）',
      },
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'update_location',
      description: '更新已有地点信息',
      parameters: {
        'name': '地点名称',
        'category': '新分类（可选）',
        'description': '新描述（可选）',
        'features': '地理特征（可选）',
        'rules': '特殊规则（可选）',
      },
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'update_faction',
      description: '更新已有势力信息',
      parameters: {
        'name': '势力名称',
        'category': '新分类（可选）',
        'description': '新描述（可选）',
        'leader': '新首领（可选）',
        'strength': '新战力（可选）',
      },
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'update_item',
      description: '更新已有道具信息',
      parameters: {
        'name': '道具名称',
        'category': '新分类（可选）',
        'description': '新描述（可选）',
        'powerLevel': '新品阶（可选）',
        'owner': '新持有者（可选）',
        'isKeyItem': '是否关键道具（可选）',
      },
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'update_reference',
      description: '更新已有参考资料',
      parameters: {
        'title': '参考标题',
        'content': '新内容（可选）',
        'source': '新来源（可选）',
        'sourceUrl': '新来源URL（可选）',
      },
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_character',
      description: '删除指定角色',
      parameters: {'name': '角色名称'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_setting',
      description: '删除指定设定',
      parameters: {'name': '设定名称'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_location',
      description: '删除指定地点',
      parameters: {'name': '地点名称'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_faction',
      description: '删除指定势力',
      parameters: {'name': '势力名称'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_item',
      description: '删除指定道具',
      parameters: {'name': '道具名称'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_hook',
      description: '删除指定伏笔',
      parameters: {'title': '伏笔标题'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_reference',
      description: '删除指定参考资料',
      parameters: {'title': '参考标题'},
      category: ToolCategories.edit,
    ),

    // ====== 分析类工具 ======
    AgentTool(
      name: 'analyze_plot_consistency',
      description: '分析剧情一致性',
      category: ToolCategories.analyze,
    ),
    AgentTool(
      name: 'check_idle_hooks',
      description: '检查闲置伏笔',
      category: ToolCategories.analyze,
    ),
    AgentTool(
      name: 'generate_chapter_outline',
      description: '生成下一章大纲',
      parameters: {'direction': '写作方向（可选）'},
      category: ToolCategories.analyze,
    ),
    AgentTool(
      name: 'character_relationship_map',
      description: '分析角色关系图谱',
      category: ToolCategories.analyze,
    ),

    // ====== 子代理工具 ======
    AgentTool(
      name: 'delegate_to_sub_agent',
      description: '委派任务给子代理',
      parameters: {
        'task_type':
            'outline_editor/continuity_checker/character_analyst/pacing_advisor',
        'instruction': '具体指令',
      },
      category: ToolCategories.agent,
    ),
    AgentTool(
      name: 'run_workflow',
      description: '触发自动化工作流',
      parameters: {
        'workflow_name': 'post_chapter_check/full_review/outline_refresh',
      },
      category: ToolCategories.agent,
    ),

    // ====== Skill工具 ======
    AgentTool(
      name: 'get_skills',
      description: '获取所有已启用的Skill',
      category: ToolCategories.skill,
    ),
    AgentTool(
      name: 'add_skill',
      description: '添加自定义Skill',
      parameters: {
        'name': '名称',
        'category': '分类',
        'description': '描述',
        'content': '内容',
      },
      category: ToolCategories.skill,
    ),

    // ====== 文本处理工具 ======
    AgentTool(
      name: 'humanize_text',
      description: '''去AI味：将AI生成的文本改写为自然人类风格。核心规则：
1. 删除过度强调词：stands as, is a testament, crucial/pivotal/key role, underscores, highlights its significance, reflects broader, symbolizing, contributing to, setting the stage for, marking a shift, focal point, indelible mark, deeply rooted
2. 删除空洞评价：This is important, It is worth noting, It goes without saying, In today's world, At the end of the day
3. 删除AI典型三项排比：把"A, B, and C"结构改为更自然的表达
4. 减少破折号滥用：用逗号或句号替代不必要的em-dash
5. 删除虚假归因：研究表明/专家认为/有人说是（无具体来源时删除）
6. 打破句子同质化：混合长短句，加入个人视角和口语化表达
7. 注入个性和情感：加入主观评价、幽默、不确定感，而非中性报道
8. 保留核心含义，保持原文语气风格''',
      parameters: {'text': '需要去AI味的文本内容'},
      category: ToolCategories.analyze,
    ),

    // ====== 系统配置工具 ======
    AgentTool(
      name: 'get_ai_configs',
      description: '获取所有AI模型配置',
      category: ToolCategories.config,
    ),
    AgentTool(
      name: 'add_ai_config',
      description: '添加AI模型配置',
      parameters: {
        'name': '名称',
        'api_url': 'API地址',
        'model_name': '模型ID',
        'model_type': 'text/tts/stt',
        'api_key': 'API Key',
      },
      category: ToolCategories.config,
    ),
    AgentTool(
      name: 'set_active_ai_config',
      description: '设置当前使用的AI模型',
      parameters: {'config_id': '配置ID', 'purpose': 'text/voice'},
      category: ToolCategories.config,
    ),

    // ====== 项目管理工具 ======
    AgentTool(
      name: 'list_novels',
      description: '获取小说项目列表',
      category: ToolCategories.project,
    ),
    AgentTool(
      name: 'create_novel',
      description: '创建新小说项目',
      parameters: {'title': '标题', 'genre': '类型', 'description': '简介'},
      category: ToolCategories.project,
    ),
    AgentTool(
      name: 'switch_novel',
      description: '切换当前小说项目',
      parameters: {'novel_id': '小说ID'},
      category: ToolCategories.project,
    ),
    AgentTool(
      name: 'web_search',
      description: '联网搜索获取实时信息，用于查询写作参考资料、事实核查、知识查询等',
      parameters: {'query': '搜索关键词'},
      category: ToolCategories.project,
    ),

    // ====== 编辑器工具 ======
    AgentTool(
      name: 'write_chapter_content',
      description: '写入章节内容',
      parameters: {'chapter_id': '章节ID', 'content': '正文内容'},
      category: ToolCategories.editor,
    ),
    AgentTool(
      name: 'create_chapter',
      description: '创建新章节',
      parameters: {'volume_id': '卷ID', 'title': '章节标题', 'content': '正文（可选）'},
      category: ToolCategories.editor,
    ),
  ];

  /// 工具执行器映射
  final Map<String, ToolExecutor> _executors = {};

  /// 注册工具执行器
  void registerExecutor(String toolName, ToolExecutor executor) {
    _executors[toolName] = executor;
  }

  /// 获取工具执行器
  ToolExecutor? getExecutor(String toolName) => _executors[toolName];

  /// 获取已注册工具的分类列表
  Set<String> get registeredCategories {
    final cats = <String>{};
    for (final name in _executors.keys) {
      final tool = tools.where((t) => t.name == name).firstOrNull;
      if (tool != null) cats.add(tool.category);
    }
    return cats;
  }

  // ========== 核心架构：轻量主对话 + 按需工具调度 ==========

  /// 发送Agent请求（轻量架构）
  ///
  /// 架构流程：
  /// 1. 主对话请求（轻量，只传对话历史 + 工具摘要列表，不传完整工具定义）
  /// 2. AI返回工具调用意图
  /// 3. 独立执行工具（不占用对话payload）
  /// 4. 将工具结果摘要回传对话
  /// 5. AI根据结果生成最终回复
  Future<AgentResponse> chat({
    required AiConfig config,
    required List<Map<String, String>> messages,
    String? systemPrompt,
    int maxToolRounds = 5,
  }) async {
    // Agent系统提示始终作为基础，自定义提示作为角色补充
    final effectiveSystemPrompt = systemPrompt != null
        ? '$_defaultSystemPrompt\n\n---\n用户自定义角色设定：\n$systemPrompt'
        : _defaultSystemPrompt;

    // 构建轻量消息列表
    List<Map<String, dynamic>> apiMessages = [
      {'role': 'system', 'content': effectiveSystemPrompt},
      ...messages
          .map((m) => {'role': m['role'], 'content': m['content']})
          .toList(),
    ];

    final toolCalls = <String, String>{};
    final toolResults = <ToolResult>[];

    for (int round = 0; round < maxToolRounds; round++) {
      // 只传已注册工具的定义（按需，不是全部）
      final availableTools = _getRegisteredTools();

      final response = await _aiService.chatWithTools(
        config: config,
        messages: apiMessages,
        tools: availableTools.isNotEmpty ? availableTools : null,
      );

      // 检查是否有工具调用
      if (response.toolCalls != null && response.toolCalls!.isNotEmpty) {
        // 添加助手消息（含tool_calls）
        apiMessages.add({
          'role': 'assistant',
          'content': response.content,
          'tool_calls': response.toolCalls!
              .map(
                (tc) => {
                  'id': tc.id,
                  'type': 'function',
                  'function': {
                    'name': tc.functionName,
                    'arguments': tc.arguments is String
                        ? tc.arguments
                        : jsonEncode(tc.arguments),
                  },
                },
              )
              .toList(),
        });

        // 独立执行每个工具（不占用对话payload）
        for (final tc in response.toolCalls!) {
          toolCalls[tc.functionName] = tc.arguments is String
              ? tc.arguments
              : jsonEncode(tc.arguments);
          final executor = _executors[tc.functionName];
          if (executor != null) {
            try {
              final args = tc.arguments is String
                  ? jsonDecode(tc.arguments as String)
                  : (tc.arguments as Map<String, dynamic>? ?? {});
              final result = await executor(args);
              toolResults.add(result);

              // 工具结果摘要回传（截断过长内容，避免payload膨胀）
              apiMessages.add({
                'role': 'tool',
                'tool_call_id': tc.id,
                'content': _summarizeToolResult(result),
              });
            } catch (e) {
              toolResults.add(
                ToolResult(
                  toolName: tc.functionName,
                  success: false,
                  message: '执行失败: $e',
                ),
              );
              apiMessages.add({
                'role': 'tool',
                'tool_call_id': tc.id,
                'content': '执行失败: $e',
              });
            }
          } else {
            // 关键修复：工具不存在时也必须返回tool消息，否则API 400崩溃
            apiMessages.add({
              'role': 'tool',
              'tool_call_id': tc.id,
              'content': '工具 ${tc.functionName} 不存在，请不要调用此工具。',
            });
          }
        }
      } else {
        // 没有工具调用，返回最终回复
        return AgentResponse(
          content: response.content ?? '',
          thinkingContent: response.thinkingContent,
          toolCalls: toolCalls,
          toolResults: toolResults,
        );
      }
    }

    // 达到最大轮次
    return AgentResponse(
      content: '已达到最大工具调用轮次（$maxToolRounds轮），请简化你的需求。',
      toolCalls: toolCalls,
      toolResults: toolResults,
    );
  }

  /// 获取已注册工具的OpenAI格式定义（只传已注册的，不是全部）
  List<Map<String, dynamic>> _getRegisteredTools() {
    return tools
        .where((t) => _executors.containsKey(t.name))
        .map((t) => t.toOpenAiFormat())
        .toList();
  }

  /// 工具结果摘要（截断过长内容，避免payload膨胀）
  String _summarizeToolResult(ToolResult result) {
    final content = result.message;
    if (content.length <= 500) return content;
    // 超过500字时截断，保留开头和结尾
    return '${content.substring(0, 300)}\n...（省略${content.length - 500}字）...\n${content.substring(content.length - 200)}';
  }

  /// 轻量模式：只发对话，不传工具定义
  /// 用于普通闲聊场景，完全不占用工具payload
  Future<String> chatLite({
    required AiConfig config,
    required List<Map<String, String>> messages,
    String? systemPrompt,
  }) async {
    // Agent系统提示始终作为基础，自定义提示作为角色补充
    final effectiveSystemPrompt = systemPrompt != null
        ? '$_defaultSystemPrompt\n\n---\n用户自定义角色设定：\n$systemPrompt'
        : _defaultSystemPrompt;

    final conversationText = messages
        .map((m) => '${m["role"]}: ${m["content"]}')
        .join('\n\n');

    return await _aiService.send(
      config: config,
      systemPrompt: effectiveSystemPrompt,
      userMessage: conversationText,
      taskType: 'chat',
    );
  }

  static const String _defaultSystemPrompt =
      '''你是 NovelIDE 的主智能体（Main Agent / Orchestrator），是网文写作AI IDE的总控。

你的身份：你不是被动的问答机器人，你是拥有完整工具调用能力的自主Agent。用户只需表达意图，你来拆解执行。

你的核心原则：
1. 先理解再行动：通过对话了解用户真实需求（在写小说？找灵感？修改旧文？），然后自主决定调用什么工具
2. 不推销不预设：用户没说要写大纲就不要推荐大纲，用户没说要写文章就不要问写什么文章。保持纯净对话
3. 工具优先：能调用工具获取的信息就调用工具，不要猜测
4. 结果导向：直接交付结果，不要说"我无法操作你的设备"

你能调用的工具类别：
- 读取：get_novel_info, get_chapters, get_chapter_content, get_characters, get_settings, get_locations, get_factions, get_items, get_hooks, get_references, get_memory, get_skills, get_ai_configs, list_novels
- 写入：add_character, add_setting, add_location, add_faction, add_item, add_hook, add_reference, add_skill, add_ai_config, create_novel, create_chapter, write_chapter_content
- 编辑：update_character, update_setting, update_location, update_faction, update_item, update_hook, update_reference, update_hook_status, delete_character, delete_setting, delete_location, delete_faction, delete_item, delete_hook, delete_reference
- 分析：analyze_plot_consistency, check_idle_hooks, generate_chapter_outline, character_relationship_map, humanize_text
- 调度：delegate_to_sub_agent（派任务给子Agent）、run_workflow（触发自动化工作流）
- 配置：set_active_ai_config, switch_novel

典型工作流示例：
- 用户说"帮我看看现有的角色" → 调用 get_characters → 展示结果
- 用户说"把刚才讨论的角色加到资料库" → 调用 add_character
- 用户说"帮我查一下xxx" → 调用联网搜索（如有）
- 用户说"分析我的小说有没有Bug" → 调用 analyze_plot_consistency + check_idle_hooks + character_relationship_map

回复风格：
- 用中文，简洁有力
- 不要过度承诺能力，实事求是
- 遇到不确定的情况，坦诚说明并提出替代方案
- 工具执行结果有误差时，告知用户并寻求确认''';
}

/// Agent响应结果
class AgentResponse {
  final String content;
  final Map<String, String> toolCalls;
  final List<ToolResult> toolResults;
  final String? thinkingContent;

  const AgentResponse({
    required this.content,
    this.toolCalls = const {},
    this.toolResults = const [],
    this.thinkingContent,
  });
}
