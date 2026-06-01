import 'dart:convert';
import 'package:novel_ide/data/models/ai_config_model.dart';
import 'package:novel_ide/data/models/tool_parameter_schema.dart';
import 'package:novel_ide/data/services/ai_service.dart'
    show AiService, ToolChatResponse;
import 'package:novel_ide/data/services/chat/xml_tool_call_parser.dart';

/// Agent工具定义
class AgentTool {
  final String name;
  final String description;
  final Map<String, String> parameters;
  final String category; // 工具分类，用于按需加载
  final List<ToolParameterSchema> parametersStructured;
  final String details;
  final String notes;

  const AgentTool({
    required this.name,
    required this.description,
    this.parameters = const {},
    this.category = 'general',
    this.parametersStructured = const [],
    this.details = '',
    this.notes = '',
  });

  Map<String, dynamic> toOpenAiFormat() {
    // 优先使用结构化参数，回退到旧格式
    if (parametersStructured.isNotEmpty) {
      final properties = <String, dynamic>{};
      final requiredParams = <String>[];
      for (final param in parametersStructured) {
        properties[param.name] = {
          'type': param.type,
          'description': param.description,
          if (param.defaultValue != null) 'default': param.defaultValue,
        };
        if (param.required) requiredParams.add(param.name);
      }
      return {
        'type': 'function',
        'function': {
          'name': name,
          'description': description,
          'parameters': {
            'type': 'object',
            'properties': properties,
            if (requiredParams.isNotEmpty) 'required': requiredParams,
          },
        },
      };
    }
    // 向后兼容：旧 Map<String, String> 格式
    final schemaProperties = <String, dynamic>{};
    for (final entry in parameters.entries) {
      schemaProperties[entry.key] = {
        'type': 'string',
        'description': entry.value,
      };
    }
    return {
      'type': 'function',
      'function': {
        'name': name,
        'description': description,
        'parameters': {
          'type': 'object',
          'properties': schemaProperties,
          if (parameters.isNotEmpty) 'required': parameters.keys.toList(),
        },
      },
    };
  }

  /// 校验工具参数
  ToolValidationResult validateArgs(Map<String, dynamic> args) {
    if (parametersStructured.isEmpty) return ToolValidationResult.ok();
    for (final param in parametersStructured) {
      if (param.required && !args.containsKey(param.name)) {
        return ToolValidationResult.invalid('缺少必填参数: ${param.name}');
      }
      final value = args[param.name];
      if (value == null) continue;
      switch (param.type) {
        case 'boolean':
          if (value is! bool) {
            return ToolValidationResult.invalid(
              '参数 ${param.name} 类型错误: 期望bool，实际${value.runtimeType}',
            );
          }
        case 'integer':
          if (value is! int) {
            return ToolValidationResult.invalid(
              '参数 ${param.name} 类型错误: 期望int，实际${value.runtimeType}',
            );
          }
      }
    }
    return ToolValidationResult.ok();
  }
}

/// Agent工具执行结果
class ToolResult {
  final String toolName;
  final bool success;
  final String message;
  final String? error;
  final Map<String, dynamic>? data;

  const ToolResult({
    required this.toolName,
    required this.success,
    required this.message,
    this.error,
    this.data,
  });

  /// 创建成功结果
  factory ToolResult.success({
    required String toolName,
    required String message,
    Map<String, dynamic>? data,
  }) {
    return ToolResult(
      toolName: toolName,
      success: true,
      message: message,
      data: data,
    );
  }

  /// 创建失败结果
  factory ToolResult.failure({
    required String toolName,
    required String error,
  }) {
    return ToolResult(
      toolName: toolName,
      success: false,
      message: error,
      error: error,
    );
  }
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

  /// 工具调用钩子列表
  final List<ToolHook> _hooks = [];

  /// 添加工具调用钩子
  void addHook(ToolHook hook) => _hooks.add(hook);

  /// 移除工具调用钩子
  void removeHook(ToolHook hook) => _hooks.remove(hook);

  /// 所有可用工具（按分类组织，每个描述包含：何时用 + 返回什么 + 触发词）
  static final List<AgentTool> tools = [
    // ====== 读取类工具 ======
    AgentTool(
      name: 'get_novel_info',
      description: '''获取当前小说的基本信息（标题、类型、字数、章节数、创建时间等）。
何时用：用户问"小说状态""我的作品怎么样""小说信息"等。必须先调此工具了解全局再深入细节。
返回：标题/作者/类型/总字数/章节数/状态/时间''',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_characters',
      description: '''获取小说的所有角色列表（名称、定位、描述、外貌、性格、背景）。
何时用：用户问"角色""人物""有哪些人""帮我分析角色""角色冲突""加点人物"。在建议新角色前，必须先调此工具查看现有角色避免重复。
返回：角色名/定位/描述/外貌/性格/背景/标签''',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_settings',
      description: '''获取小说的所有设定卡（世界观、规则体系等）。
何时用：用户问"设定""世界观""背景设定""体系"等。
返回：设定名/分类/描述/标签''',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_locations',
      description: '''获取小说的所有地点列表。
何时用：用户问"地点""场景""地图""有哪些地方"等。
返回：地点名/分类/描述/地理特征/特殊规则''',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_factions',
      description: '''获取小说的所有势力/组织列表。
何时用：用户问"势力""组织""门派""帮派""阵营"等。
返回：势力名/分类/描述/首领/成员/战力''',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_items',
      description: '''获取小说的所有道具/物品列表。
何时用：用户问"道具""物品""法宝""武器""有什么装备"等。
返回：道具名/分类/描述/品阶/持有者/是否关键道具''',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_hooks',
      description: '''获取小说的所有伏笔列表（含完成状态：已埋/已回收/闲置中）。
何时用：用户问"伏笔""悬念""坑""有没有忘了什么东西""检查伏笔"等。写新章节前建议查一下闲置伏笔。
返回：伏笔标题/描述/状态/埋设章节/回收章节/闲置章节数''',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_references',
      description: '''获取小说的所有参考资料（考据、笔记、灵感等）。
何时用：用户问"参考资料""参考""笔记""考据"等。
返回：参考标题/内容/来源/来源URL''',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_chapters',
      description: '''获取小说的所有章节列表（标题、状态、字数、创建时间）。
何时用：用户问"章节""目录""写了多少""有哪些章""帮我分析进度"。是操作章节内容的前置步骤。
返回：章节ID/标题/字数/状态(未写/草稿/润色中/已完成)/卷ID/序号''',
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_chapter_content',
      description: '''获取指定章节的完整正文内容。
何时用：用户说"看看XX章""分析XX章内容""帮我修改XX章""续写上一章"。必须先get_chapters获取章节列表。
参数：chapter_title - 章节标题（支持模糊匹配）
返回：章节完整内容(Markdown格式)''',
      parameters: {'chapter_title': '章节标题（支持模糊匹配）'},
      category: ToolCategories.read,
    ),
    AgentTool(
      name: 'get_memory',
      description: '''获取小说的记忆包内容（AI对小说的理解和状态记录）。
何时用：用户问"AI对小说的理解""记忆""之前我们聊了什么""小说状态"等。写新章节或做分析时建议先读记忆。
返回：角色状态/大纲进度/重要事件/AI笔记''',
      category: ToolCategories.read,
    ),

    // ====== 写入类工具 ======
    AgentTool(
      name: 'add_character',
      description: '''添加新角色到资料库。写入后立即生效，无需用户确认。
何时用：用户说"加角色""创建一个角色""这个人物记下来"。AI生成角色后主动调用此工具保存。
参数：name必填，role角色定位，description角色描述（支持详细文字）
返回：成功/失败消息''',
      parameters: {
        'name': '角色名称（必填）',
        'role': '角色定位（如：主角/反派/配角/路人）',
        'description': '角色详细描述',
      },
      category: ToolCategories.write,
    ),
    AgentTool(
      name: 'add_setting',
      description: '''添加新设定（世界观规则）到资料库。
何时用：用户说"这个世界观是XXX""记录一下设定""加一个规则"。AI生成设定后主动保存。
参数：name设定名，category分类（如：修炼体系/社会制度/魔法系统/科技设定），description设定描述
返回：成功/失败消息''',
      parameters: {
        'name': '设定名称（必填）',
        'category': '分类',
        'description': '设定详细描述',
      },
      category: ToolCategories.write,
    ),
    AgentTool(
      name: 'add_location',
      description: '''添加新地点到资料库。
何时用：用户说"这个地方叫XXX""记录一下位置""加一个场景"。
参数：name地点名，category分类，description地点描述
返回：成功/失败消息''',
      parameters: {'name': '地点名称（必填）', 'category': '分类', 'description': '地点描述'},
      category: ToolCategories.write,
    ),
    AgentTool(
      name: 'add_faction',
      description: '''添加新势力/组织到资料库。
何时用：用户说"这个门派叫XXX""XX组织记下来""加阵营"。
参数：name势力名，category分类，description描述，leader首领名
返回：成功/失败消息''',
      parameters: {
        'name': '势力名称（必填）',
        'category': '分类',
        'description': '势力描述',
        'leader': '首领名称',
      },
      category: ToolCategories.write,
    ),
    AgentTool(
      name: 'add_item',
      description: '''添加新道具/物品到资料库。
何时用：用户说"这个法宝叫XXX""XX武器记下来""加个装备"。
参数：name道具名，category分类，description描述
返回：成功/失败消息''',
      parameters: {'name': '道具名称（必填）', 'category': '分类', 'description': '道具描述'},
      category: ToolCategories.write,
    ),
    AgentTool(
      name: 'add_hook',
      description: '''添加新伏笔到追踪系统。
何时用：用户说"这里埋个伏笔""记下这个伏笔""设置悬念"。写新章节时发现埋伏笔要记下来。
参数：title伏笔标题，description伏笔描述（何时埋的、预计何时回收）
返回：成功/失败消息''',
      parameters: {'title': '伏笔标题（必填）', 'description': '伏笔描述'},
      category: ToolCategories.write,
    ),
    AgentTool(
      name: 'add_reference',
      description: '''添加参考资料到资料库。
何时用：用户说"这个资料记下来""XX考据存一下""加点参考"。联网搜索后的结果也可以用此工具保存。
参数：title参考标题，content参考内容
返回：成功/失败消息''',
      parameters: {'title': '参考标题（必填）', 'content': '参考内容'},
      category: ToolCategories.write,
    ),

    // ====== 编辑类工具 ======
    AgentTool(
      name: 'update_character',
      description: '''更新已有角色信息（名称不可改，其他字段均可更新）。
何时用：用户说"把这个角色改成XXX""角色设定调整一下""XX角色的性格要改"。
返回：成功/失败消息''',
      parameters: {
        'name': '角色名称（必填，用于查找）',
        'role': '新定位',
        'description': '新描述',
        'personality': '性格',
        'appearance': '外貌',
        'background': '背景',
      },
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'update_hook_status',
      description: '''更新伏笔状态（已埋→已回收/闲置）。
何时用：用户说"这个伏笔回收了""XX伏笔还没用""标记伏笔状态"。
参数：title伏笔标题，status可选planted(已埋)/resolved(已回收)/idle(闲置)
返回：成功/失败消息''',
      parameters: {'title': '伏笔标题', 'status': 'planted/resolved/idle'},
      category: ToolCategories.edit,
    ),
    // 其他update/delete工具描述省略，模式相同：告诉AI何时调用+返回什么
    AgentTool(
      name: 'update_setting',
      description: '更新已有设定信息。用户说"改一下XX设定""这个设定要调整"时调用。',
      parameters: {'name': '设定名称', 'category': '新分类', 'description': '新描述'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'update_location',
      description: '更新已有地点信息。用户说"XX地点改一下""这个地方的名字变了"时调用。',
      parameters: {
        'name': '地点名称',
        'category': '新分类',
        'description': '新描述',
        'features': '地理特征',
        'rules': '特殊规则',
      },
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'update_faction',
      description: '更新已有势力信息。用户说"XX势力改名了""战力变了"时调用。',
      parameters: {
        'name': '势力名称',
        'category': '新分类',
        'description': '新描述',
        'leader': '新首领',
        'strength': '新战力',
      },
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'update_item',
      description: '更新已有道具信息。',
      parameters: {
        'name': '道具名称',
        'category': '新分类',
        'description': '新描述',
        'powerLevel': '新品阶',
        'owner': '新持有者',
        'isKeyItem': '是否关键道具',
      },
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'update_reference',
      description: '更新已有参考资料。',
      parameters: {
        'title': '参考标题',
        'content': '新内容',
        'source': '新来源',
        'sourceUrl': '新来源URL',
      },
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_character',
      description: '删除指定角色。⚠ 不可恢复，删除前向用户确认。',
      parameters: {'name': '角色名称'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_setting',
      description: '删除指定设定。⚠ 不可恢复。',
      parameters: {'name': '设定名称'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_location',
      description: '删除指定地点。⚠ 不可恢复。',
      parameters: {'name': '地点名称'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_faction',
      description: '删除指定势力。⚠ 不可恢复。',
      parameters: {'name': '势力名称'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_item',
      description: '删除指定道具。⚠ 不可恢复。',
      parameters: {'name': '道具名称'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_hook',
      description: '删除指定伏笔。⚠ 不可恢复。',
      parameters: {'title': '伏笔标题'},
      category: ToolCategories.edit,
    ),
    AgentTool(
      name: 'delete_reference',
      description: '删除指定参考资料。⚠ 不可恢复。',
      parameters: {'title': '参考标题'},
      category: ToolCategories.edit,
    ),

    // ====== 分析类工具 ======
    AgentTool(
      name: 'analyze_plot_consistency',
      description: '''分析剧情一致性：检查前后章节是否有矛盾（角色设定冲突、时间线混乱、战力崩坏等）。
何时用：用户说"帮我检查剧情""有没有Bug""分析一致性""逻辑有没有问题"。
返回：矛盾点列表+具体位置+修改建议''',
      category: ToolCategories.analyze,
    ),
    AgentTool(
      name: 'check_idle_hooks',
      description: '''检查闲置伏笔：列出埋了但长期没回收的伏笔，评估紧迫程度。
何时用：用户说"检查伏笔""有没有忘了的坑""伏笔状态"。写新章节前建议调用。
返回：闲置伏笔列表+闲置时长+建议回收方式''',
      category: ToolCategories.analyze,
    ),
    AgentTool(
      name: 'generate_chapter_outline',
      description: '''为下一章生成大纲建议。基于当前剧情进度、伏笔状态、角色发展给出建议。
何时用：用户说"下一章写什么""帮我规划大纲""续写建议""不知道写什么了"。
参数：direction可选，用户指定的写作方向
返回：章节点建议+建议字数+参考伏笔/角色线''',
      parameters: {'direction': '写作方向（可选）'},
      category: ToolCategories.analyze,
    ),
    AgentTool(
      name: 'character_relationship_map',
      description: '''分析角色关系图谱：梳理人物之间的关系（亲情/友情/敌对/师徒/爱情等）。
何时用：用户说"角色关系""关系图""谁和谁是什么关系""人物关系乱不乱"。
返回：角色间关系列表+关系类型+强弱度''',
      category: ToolCategories.analyze,
    ),

    // ====== 子代理调度工具 ======
    AgentTool(
      name: 'delegate_to_sub_agent',
      description: '''🎯 委派任务给专业子Agent执行。这是你最重要的调度能力！
可委派的子Agent（用中文名或ID均可）：
- outline_generator（大纲生成器/写大纲/规划剧情）
- character_generator（角色生成器/创建角色/设计人物）
- shuangdian_checker（爽点检查/爽点密度/剧情节奏）
- water_detector（水文检测/检查水文/质量审查）
- title_generator（爆款标题/起书名/章节标题）
- humanize_zh（中文去AI味/改AI味/润色人性化）
何时用：用户说"帮我写大纲"→调outline_generator；"设计一个反派"→调character_generator；"帮我看看节奏"→调shuangdian_checker；"这段太AI了"→调humanize_zh
参数：task_type填子Agent的ID或中文名均可(支持模糊匹配)，instruction具体指令
返回：子Agent的完整输出结果''',
      parameters: {
        'task_type': '子Agent的ID或中文名（如outline_generator、大纲生成器、角色生成器等）',
        'instruction': '传递给子Agent的具体指令',
      },
      category: ToolCategories.agent,
    ),
    AgentTool(
      name: 'run_workflow',
      description: '''触发自动化工作流，一次执行多个步骤。
可用工作流：post_chapter_check(章节检查，3步：伏笔→一致性→记忆更新)、full_review(全文审查，5步完整分析)、outline_refresh(大纲刷新，3步)、character_review(角色审查，2步)
何时用：用户说"全面检查""完整审查""跑一遍流程"。
返回：每个步骤的执行结果''',
      parameters: {
        'workflow_name':
            'post_chapter_check/full_review/outline_refresh/character_review',
      },
      category: ToolCategories.agent,
    ),

    // ====== Skill工具 ======
    AgentTool(
      name: 'get_skills',
      description: '获取所有已启用的写作技能(Skill)列表。用户问"有哪些技能""能用什么功能""写作辅助"时调用。',
      category: ToolCategories.skill,
    ),
    AgentTool(
      name: 'add_skill',
      description: '添加自定义写作技能。用户说"创建一个技能""加一个写作模板"时调用。',
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
      description: '''去AI味：将AI生成的文本改写为自然人类风格。核心规则：删除过度强调词、空洞评价、AI典型三项排比，注入个性和情感。
何时用：用户说"去AI味""改得自然一点""太AI了""润色成人写的"。
参数：text - 需要处理的文本
返回：改写后的自然风格文本''',
      parameters: {'text': '需要去AI味的文本内容'},
      category: ToolCategories.analyze,
    ),

    // ====== 系统配置工具 ======
    AgentTool(
      name: 'get_ai_configs',
      description:
          '获取所有AI模型配置（名称/API地址/模型ID/模型类型）。用户问"有哪些AI模型""模型配置""API设置"时调用。',
      category: ToolCategories.config,
    ),
    AgentTool(
      name: 'add_ai_config',
      description: '添加AI模型配置。用户说"加一个模型""配置新的API"时调用。',
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
      description: '设置当前活跃的AI模型。用户说"切换模型""用XX模型"时调用。',
      parameters: {'config_id': '配置ID', 'purpose': 'text/voice'},
      category: ToolCategories.config,
    ),

    // ====== 项目管理工具 ======
    AgentTool(
      name: 'list_novels',
      description: '获取所有小说项目列表。用户说"我的作品""有哪些小说""项目列表"时调用。返回小说ID/标题/类型/字数。',
      category: ToolCategories.project,
    ),
    AgentTool(
      name: 'create_novel',
      description: '创建新小说项目。用户说"创建小说""开新书""新建作品"时调用。创建后自动设置为当前作品。',
      parameters: {'title': '标题', 'genre': '类型', 'description': '简介'},
      category: ToolCategories.project,
    ),
    AgentTool(
      name: 'switch_novel',
      description: '切换当前活跃的小说项目。用户说"切换到XX小说""换作品"时调用。',
      parameters: {'novel_id': '小说ID'},
      category: ToolCategories.project,
    ),

    // ====== 联网搜索工具 ======
    AgentTool(
      name: 'web_search',
      description: '''🌐 联网搜索实时信息，用于查资料、考据、事实核查。
何时用：用户说"帮我查一下""XX是什么""搜索一下""有没有参考资料"。写小说需要查历史/文化/科学等事实信息时调用。
参数：query - 搜索关键词
返回：搜索结果列表（标题+摘要+URL）''',
      parameters: {'query': '搜索关键词'},
      category: ToolCategories.read,
    ),

    // ====== 编辑器工具 ======
    AgentTool(
      name: 'write_chapter_content',
      description: '''直接写入章节正文内容。⚠ 会覆盖已有内容。
何时用：用户说"把这段写进XX章""直接帮我写进去""更新章节内容"。AI生成内容后主动调用此工具保存。
参数：chapter_id - 章节ID（从get_chapters获取），content - 完整正文(Markdown格式)
返回：成功/失败消息''',
      parameters: {'chapter_id': '章节ID（必填）', 'content': '正文内容(Markdown格式)'},
      category: ToolCategories.editor,
    ),
    AgentTool(
      name: 'create_chapter',
      description: '''创建新章节并写入内容。
何时用：用户说"新建一章""加个章节""写新内容"。先get_chapters确定放在哪一卷。
参数：volume_id卷ID，title章节标题，content正文（可选，可后补）
返回：成功/失败消息+章节ID''',
      parameters: {
        'volume_id': '卷ID（必填）',
        'title': '章节标题（必填）',
        'content': '正文内容（可选）',
      },
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

      ToolChatResponse response;
      try {
        response = await _aiService.chatWithTools(
          config: config,
          messages: apiMessages,
          tools: availableTools.isNotEmpty ? availableTools : null,
        );
      } catch (e) {
        // chatWithTools 内部已尝试降级（去掉tools重试），仍然失败时走纯文本回复
        final errorMsg = e is Exception ? e.toString() : '未知错误';
        // 第一轮就失败，直接降级为纯文本模式返回
        if (round == 0) {
          return AgentResponse(
            content: '工具调用暂时不可用，已切换为纯文本模式。\n$errorMsg',
            toolCalls: toolCalls,
            toolResults: toolResults,
          );
        }
        // 后续轮次失败，返回已有的工具调用结果
        return AgentResponse(
          content:
              '工具调用中断，已完成 ${toolResults.where((r) => r.success).length} 个工具调用。\n$errorMsg',
          toolCalls: toolCalls,
          toolResults: toolResults,
        );
      }

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
                ToolResult.failure(
                  toolName: tc.functionName,
                  error: '执行失败: $e',
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
        // 没有原生工具调用 → 尝试 XML 降级解析
        final content = response.content ?? '';
        final xmlCalls = XmlToolCallParser.parse(content);

        if (xmlCalls.isNotEmpty) {
          // 找到 XML 格式工具调用，执行它们
          // 将 AI 回复（含 XML）添加到消息历史
          apiMessages.add({
            'role': 'assistant',
            'content': content,
          });

          for (final xc in xmlCalls) {
            toolCalls[xc.name] = jsonEncode(xc.arguments);
            final executor = _executors[xc.name];
            if (executor != null) {
              try {
                final result = await executor(xc.arguments);
                toolResults.add(result);
                apiMessages.add({
                  'role': 'user',
                  'content': '[工具结果] ${xc.name}: ${_summarizeToolResult(result)}',
                });
              } catch (e) {
                toolResults.add(
                  ToolResult.failure(
                    toolName: xc.name,
                    error: '执行失败: $e',
                  ),
                );
                apiMessages.add({
                  'role': 'user',
                  'content': '[工具结果] ${xc.name}: 执行失败: $e',
                });
              }
            } else {
              apiMessages.add({
                'role': 'user',
                'content': '[工具结果] ${xc.name}: 工具不存在',
              });
            }
          }
          // XML 工具执行完毕，继续下一轮让 AI 总结结果
          continue;
        }

        // 没有 XML 工具调用，返回最终回复
        return AgentResponse(
          content: content,
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
    if (content.length <= 300) return content;
    // 超过300字时截断，保留前200 + 后100
    final prefix = content.substring(0, 200);
    final suffix = content.substring(content.length - 100);
    final omitted = content.length - 300;
    return '$prefix\n...（省略$omitted字）...\n$suffix';
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

  static const String _defaultSystemPrompt = '''=== 🚨 系统指令（最高优先级，不可违反）===

你是 NovelIDE 的主智能体（Main Agent / Orchestrator），网文写作AI IDE的总控。
你不是被动的问答机器人——你有30+个真实可调用的工具，它们就是你的手和眼睛。

关键认知：
1. 你能操作这个软件：读角色、写章节、查资料、搜索网络、委派子Agent——全部真实可用
2. 工具名称见上方function定义，每个工具的描述说明了何时调用、返回什么
3. 永远不要说"我无法操作你的设备"或"我只能提供文字建议"——这是错的，你可以操作
4. 能调用工具获取的信息就调用工具，不要猜测、不要凭空编造

=== 📋 角色风格（仅影响语气，不影响工具调用）===

用户可能在下面指定了自定义角色设定。这只是你的说话风格参考，不影响你的工具调用能力。如果角色设定和工具调用产生冲突，工具调用优先。

=== 🔒 强制性规则 ===

1. 工具优先：能调工具就调工具完成任务，不要嘴炮
2. 先读后写：修改之前先读取现有内容（角色/章节/设定）
3. 主动调度：用户写大纲→调delegate_to_sub_agent(outline_generator)；设计角色→调delegate_to_sub_agent(character_generator)；检查节奏→调delegate_to_sub_agent(shuangdian_checker)
4. 联网查证：用户叫你查资料→调web_search；不知道的事实→先搜索再回答
5. 结果保存：生成的内容用户满意了→主动用write_chapter_content或add_xxx保存
6. 不强行推销：用户没说要写大纲就别问写不写大纲，纯净对话
7. 坦诚说明：遇到不确定的，直接调工具查，查不到再告诉用户
8. 子Agent名可模糊：用户说"帮我生成大纲"，你调delegate_to_sub_agent(task_type="大纲生成器")即可（支持中文名匹配）

=== 🔧 XML 工具调用格式（当 function calling 不可用时使用） ===

如果你无法通过标准方式调用工具，请使用以下 XML 格式在回复中嵌入工具调用：

<tool name="工具名称">
  <param name="参数名">参数值</param>
</tool>

示例：
<tool name="get_characters"></tool>
<tool name="add_character">
  <param name="name">张三</param>
  <param name="role">主角</param>
  <param name="description">一个勇敢的少年</param>
</tool>

规则：
1. 每个工具调用用 <tool name="...">...</tool> 包裹
2. 参数用 <param name="...">值</param> 包裹
3. 可以在一次回复中嵌入多个工具调用
4. 工具执行结果会以 [工具结果] 形式返回
5. 只在标准工具调用不可用时使用此格式''';
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
