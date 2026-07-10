/// Skill模型
class WritingSkill {
  final String id;
  String name;
  String category;
  String description;
  String content; // 技能详细内容/prompt
  List<String> keywords; // 用于自动匹配的关键词
  bool isEnabled;
  bool isBuiltIn; // 是否为内置技能
  final DateTime createdAt;
  final DateTime updatedAt;

  WritingSkill({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.content,
    this.keywords = const [],
    this.isEnabled = true,
    this.isBuiltIn = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory WritingSkill.fromJson(Map<String, dynamic> json) {
    return WritingSkill(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? '通用',
      description: json['description'] as String? ?? '',
      content: json['content'] as String? ?? '',
      keywords: (json['keywords'] as List<dynamic>?)?.cast<String>() ?? [],
      isEnabled: json['isEnabled'] as bool? ?? true,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'content': content,
      'keywords': keywords,
      'isEnabled': isEnabled,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 获取所有内置技能
  static List<WritingSkill> get builtInSkills => [
    WritingSkill(
      id: 'builtin_hook_design',
      name: '伏笔设计',
      category: '剧情技巧',
      description: '如何设计引人入胜的伏笔，包括埋设时机、回收节奏、多层伏笔嵌套',
      isBuiltIn: true,
      keywords: ['伏笔', '埋线', '回收', '悬念', '草蛇灰线', '铺垫'],
      content: '''【伏笔设计技巧】

1. 埋设原则：
- 伏笔要自然融入剧情，不能刻意
- 读者第一遍读时不应察觉，回看时恍然大悟
- 重要的伏笔至少提前3-5章埋设

2. 回收节奏：
- 短期伏笔：3-5章内回收，制造即时爽感
- 中期伏笔：10-20章回收，推动剧情转折
- 长期伏笔：贯穿整卷甚至全书，作为大高潮引爆点

3. 嵌套技巧：
- 明线伏笔 + 暗线伏笔双重布局
- 用看似无关的细节掩盖关键伏笔
- 同一伏笔在不同阶段揭示不同层面

4. 注意事项：
- 记录每个伏笔的埋设位置和预计回收位置
- 避免伏笔过多导致读者遗忘
- 闲置超过10章的伏笔应尽快安排回收''',
    ),
    WritingSkill(
      id: 'builtin_pacing',
      name: '节奏把控',
      category: '结构技巧',
      description: '网文节奏控制方法，包括张弛有度、高潮设置、低谷过渡',
      isBuiltIn: true,
      keywords: ['节奏', '高潮', '拖沓', '紧凑', '水章', '爽点', '张弛'],
      content: '''【节奏把控技巧】

1. 基本节奏模式：
- 紧张→释放→铺垫→高潮→余韵（五段式循环）
- 每3-5章一个小高潮，每15-20章一个大高潮
- 高潮之后必须有1-2章的缓冲/日常过渡

2. 章节节奏：
- 开头200字：承接上章悬念或制造新冲突
- 中段：推进主线+支线穿插
- 结尾：留下悬念或反转，吸引读者点下一章

3. 张弛有度：
- 连续高潮不超过3章，读者会疲劳
- 日常/轻松章节穿插在紧张剧情中
- 战斗/冲突后安排角色互动放松

4. 节奏信号：
- 加速：短句、快节奏对话、多场景切换
- 减速：长句、环境描写、内心独白
- 停顿：章节末尾留白、时间跳跃''',
    ),
    WritingSkill(
      id: 'builtin_dialogue',
      name: '对话写作',
      category: '文笔技巧',
      description: '写出有个性、推动剧情的对话，避免千篇一律',
      isBuiltIn: true,
      keywords: ['对话', '台词', '说话', '口癖', '语气', '对白'],
      content: '''【对话写作技巧】

1. 角色个性化：
- 每个角色有独特的说话方式（口头禅、用词习惯、语气）
- 身份地位影响措辞（皇帝用朕、武将直爽、文人文雅）
- 情绪变化时说话方式也要变化

2. 对话推动剧情：
- 对话中传递信息，避免"为说而说"
- 通过对话揭示角色关系和冲突
- 对话中设置悬念和伏笔

3. 技巧：
- 少用"说道"，多用动作/表情代替提示语
- 对话要留白，不要把话说尽
- 适当加入沉默、停顿、动作描写

4. 格式：
- 一段对话不宜超过3-4轮
- 穿插动作描写和内心活动
- 重要对话单独成段，增强感染力''',
    ),
    WritingSkill(
      id: 'builtin_description',
      name: '场景描写',
      category: '文笔技巧',
      description: '写出有画面感的场景描写，调动读者五感',
      isBuiltIn: true,
      keywords: ['描写', '场景', '环境', '画面', '氛围', '五感'],
      content: '''【场景描写技巧】

1. 五感描写法：
- 视觉：色彩、光影、动态
- 听觉：环境音、对话声、战斗声
- 嗅觉：气味（花香、血腥、药香）
- 触觉：温度、质感、疼痛
- 味道：食物、毒药、灵气

2. 描写原则：
- 不要流水账式罗列，选择最有特征的2-3个细节
- 动静结合，静态场景加入动态元素
- 以角色感受为视角，不要上帝视角

3. 场景切换：
- 用感官变化过渡（温度骤降→进入秘境）
- 用角色反应带出新环境
- 重要场景首次出现时详细描写，后续简略

4. 战斗场景：
- 快节奏短句，突出力量感和速度感
- 招式描写不宜过长，重点写效果和反应
- 穿插角色心理活动增加深度''',
    ),
    WritingSkill(
      id: 'builtin_suspense',
      name: '悬念设置',
      category: '剧情技巧',
      description: '制造悬念吸引读者持续阅读，包括章末钩子、反转设计',
      isBuiltIn: true,
      keywords: ['悬念', '反转', '章末', '钩子', '意外', '揭秘'],
      content: '''【悬念设置技巧】

1. 章末钩子类型：
- 危机型：主角陷入绝境
- 转折型：意外信息出现
- 悬念型：即将揭晓的秘密
- 冲突型：矛盾激化到临界点

2. 反转设计：
- 铺垫要充分，反转才有说服力
- 最好的反转是回看有迹可循
- 避免为反转而反转，要服务于剧情

3. 信息差悬念：
- 读者知道角色不知道→紧张感
- 角色知道读者不知道→好奇心
- 双方都不知道→探索欲

4. 注意事项：
- 每章结尾必须有钩子
- 不要每章都用同类型钩子
- 大悬念下设置小悬念，层层递进''',
    ),
    WritingSkill(
      id: 'builtin_character_design',
      name: '角色塑造',
      category: '角色技巧',
      description: '塑造立体丰满的角色，包括性格、成长弧线、记忆点',
      isBuiltIn: true,
      keywords: ['角色', '人设', '性格', '成长', '反派', '配角', '主角'],
      content: '''【角色塑造技巧】

1. 角色立体化：
- 优点+缺点并存，避免完美或纯粹反派
- 给每个角色一个核心动机
- 过去经历影响当前行为

2. 成长弧线：
- 主角要有明确的成长轨迹
- 成长不是突变，要有铺垫和触发事件
- 偶尔倒退和迷茫让角色更真实

3. 角色记忆点：
- 外貌特征（标志性发型/服饰/伤疤）
- 口头禅或习惯动作
- 独特的价值观或信条

4. 角色关系：
- 角色之间要有化学反应
- 配角也要有自己的故事线
- 对手/反派的动机要合理''',
    ),
    WritingSkill(
      id: 'builtin_opening_three_chapters',
      name: '黄金三章',
      category: '结构技巧',
      description: '用冲突、目标与兑现设计能留住读者的网文开篇',
      isBuiltIn: true,
      keywords: ['黄金三章', '开篇', '第一章', '开头留存', '开局', '前三章'],
      content: '''【黄金三章设计】

1. 第一章先建立异常：
- 300字内给出人物处境或反常事件，不用百科式介绍世界观
- 让主角立刻面临一个必须处理的问题
- 章末给出更大的代价、机会或身份反差

2. 第二章明确承诺：
- 交代主角短期目标、核心优势及使用限制
- 用一次小行动证明主角会主动解决问题
- 让读者知道这本书接下来主要提供哪种体验

3. 第三章完成第一次兑现：
- 回收前两章至少一个期待，给出小胜、反转或关键发现
- 同时抬高下一阶段目标，不能兑现后原地停住

4. 自检：
- 删除可推迟到后文的设定说明
- 每章都应有“目标—阻碍—结果—新问题”
- 开篇承诺必须与书名、简介和主线类型一致''',
    ),
    WritingSkill(
      id: 'builtin_long_outline',
      name: '长篇大纲',
      category: '结构技巧',
      description: '从核心卖点拆到卷、篇章与关键节点，控制长篇不跑偏',
      isBuiltIn: true,
      keywords: ['长篇大纲', '分卷大纲', '卷纲', '主线规划', '剧情规划', '大纲拆解'],
      content: '''【长篇大纲方法】

1. 先写一句话故事：主角是谁、想得到什么、主要阻力是什么、失败代价是什么。
2. 建立三条线：主线目标、角色成长线、关系或情感线；每卷至少推进其中两条。
3. 分卷时为每卷写清：卷目标、主要对手、阶段代价、卷中转折、卷末不可逆变化。
4. 再拆关键节点：诱因、首次行动、中点升级、最低谷、高潮选择、结果与新悬念。
5. 章节只规划“本章变化”，避免把内容摘要当剧情；没有状态变化的章节应合并或删除。
6. 每完成一卷复盘未回收伏笔、角色位置与力量等级，再滚动修订后续大纲。''',
    ),
    WritingSkill(
      id: 'builtin_payoff_design',
      name: '爽点设计',
      category: '剧情技巧',
      description: '通过压制、蓄势、反差与兑现构造有因果的爽点',
      isBuiltIn: true,
      keywords: ['爽点设计', '打脸', '逆袭', '装逼', '情绪价值', '期待兑现'],
      content: '''【爽点设计方法】

1. 爽点不是结果本身，而是“期待建立—阻力加码—能力证明—情绪兑现”。
2. 先说明主角想赢什么，再让对手或环境给出具体压制；压制必须可信，不能只靠降智。
3. 兑现时使用信息差或能力差制造反差，但关键能力应提前露出限制和铺垫。
4. 结果要改变关系、资源或地位，不能所有人惊叹后剧情毫无变化。
5. 小爽点解决眼前问题，大爽点改写阶段格局；连续使用同一种打脸会迅速疲劳。
6. 让胜利带来新成本或更强目标，既保留满足感，也给下一段剧情动力。''',
    ),
    WritingSkill(
      id: 'builtin_action_scene',
      name: '战斗场景',
      category: '文笔技巧',
      description: '写清空间、目标和攻防变化，让战斗紧张而不混乱',
      isBuiltIn: true,
      keywords: ['战斗场景', '打斗', '动作戏', '交手', '招式', '追逐战'],
      content: '''【战斗场景写法】

1. 开打前交代三件事：双方目标、空间限制、失败代价。
2. 每个动作都要产生反应：攻击→应对→局势变化，避免连续罗列招式名称。
3. 用可感知的参照物说明距离、速度和破坏力，让读者知道人物在哪里。
4. 强者也要做判断；胜负来自信息、策略、资源与性格选择，少用临时觉醒救场。
5. 高速段落多用短句，关键受伤或选择处放慢，用感官和心理突出重量。
6. 战后必须留下结果：伤势、资源损耗、关系变化、线索或新的威胁。''',
    ),
    WritingSkill(
      id: 'builtin_romance_arc',
      name: '感情线推进',
      category: '角色技巧',
      description: '用共同经历、边界变化和具体选择推动关系，而非口头宣布',
      isBuiltIn: true,
      keywords: ['感情线', '恋爱线', '暧昧', '情侣互动', '情感推进', '关系升温'],
      content: '''【感情线推进方法】

1. 先区分吸引、信任、依赖与承诺，关系升级必须跨过对应事件。
2. 用行动证明偏爱：记住细节、承担风险、尊重边界、在利益冲突时做选择。
3. 暧昧来自双方都察觉到的特殊对待，以及尚未说破的顾虑，不靠反复误会拖延。
4. 每次关系推进都改变后续互动方式，例如称呼、距离、秘密共享或决策权。
5. 冲突应来自价值观、目标或现实代价；能够一句话解释清的误会不要拖十章。
6. 保留双方独立目标，避免一方成为只围着另一方转的功能角色。''',
    ),
    WritingSkill(
      id: 'builtin_worldbuilding',
      name: '世界观搭建',
      category: '设定技巧',
      description: '从规则、资源与利益关系出发，建立能持续产生剧情的世界',
      isBuiltIn: true,
      keywords: ['世界观', '设定体系', '力量体系', '社会结构', '地图设定', '规则设定'],
      content: '''【世界观搭建方法】

1. 先确定不可轻易违反的底层规则，以及违反规则的成本。
2. 找出稀缺资源：谁生产、谁分配、谁保护、谁被排除；利益关系会自然生成冲突。
3. 力量体系必须同时写清获得方式、使用代价、克制关系和能力上限。
4. 制度、职业、宗教与日常生活应受底层规则影响，不能只存在于设定表。
5. 设定随角色经历逐步展示：先给当前行动必需的信息，再通过结果补充规则。
6. 新设定出现前检查是否推翻旧规则；必要时明确它是例外，并付出更高代价。''',
    ),
    WritingSkill(
      id: 'builtin_chapter_continuation',
      name: '章节续写',
      category: '创作辅助',
      description: '承接既有文风、人物状态和未完成动作续写章节',
      isBuiltIn: true,
      keywords: ['章节续写', '继续写', '接着写', '续写本章', '往下写', '补完章节'],
      content: '''【章节续写规范】

1. 续写前提取：当前视角、时间地点、人物目标、最后一个动作、未回答的问题和文风特征。
2. 从原文最后的动作或感官直接承接，不重复总结用户已经写过的内容。
3. 保持人物说话习惯、能力边界和已知信息，不擅自新增会改写主线的设定。
4. 每800—1500字至少产生一次有效变化：信息、关系、资源、位置或风险发生改变。
5. 模仿句长与叙述密度，不机械复用原文措辞；控制形容词、比喻和心理独白数量。
6. 若缺少决定性信息，给出最小假设并标明，不偷偷替作者做重大剧情选择。''',
    ),
    WritingSkill(
      id: 'builtin_consistency_review',
      name: '一致性审校',
      category: '审校技巧',
      description: '检查时间线、人物知识、力量等级、道具与因果关系的矛盾',
      isBuiltIn: true,
      keywords: ['一致性', '设定冲突', '逻辑漏洞', '时间线检查', '前后矛盾', '战力崩坏'],
      content: '''【一致性审校清单】

1. 时间线：日期、昼夜、路程、伤势恢复和事件先后是否可同时成立。
2. 人物信息：角色是否使用了自己尚未获知的情报，称呼与关系是否符合当前阶段。
3. 能力规则：技能效果、消耗、冷却、克制与战力结果是否遵守已有设定。
4. 物品空间：道具的持有者、数量、损耗，人物进出场与地点变化是否连续。
5. 因果链：关键结果是否有足够原因；巧合可以引发麻烦，不应反复直接解决麻烦。
6. 输出时按“位置—冲突证据—影响—最小修改方案”列出，不确定项标为待确认。''',
    ),
    WritingSkill(
      id: 'builtin_point_of_view',
      name: '视角控制',
      category: '文笔技巧',
      description: '稳定叙事视角和信息边界，避免无意识跳视角',
      isBuiltIn: true,
      keywords: ['视角控制', '叙事视角', '跳视角', '第一人称', '第三人称限知', 'POV'],
      content: '''【视角控制方法】

1. 每个场景确定一个视角角色，只写其能感知、推断或回忆的信息。
2. 不直接断言其他人物的内心；改用表情、动作、语气和视角角色的判断呈现。
3. 切换视角应发生在分章、分节或明确的场景转换处，并立刻给出新视角锚点。
4. 描写选择要受人物经验影响：医生先看症状，士兵先看出口，儿童关注的细节不同。
5. 有意隐藏信息时不能让视角人物“假装不想”，应通过注意力、误判或现实阻碍处理。
6. 审校时逐段问：这条信息是谁知道的、通过什么知道、此刻为什么会注意到。''',
    ),
    WritingSkill(
      id: 'builtin_style_polish',
      name: '文风精修',
      category: '审校技巧',
      description: '在不改剧情事实的前提下，清理赘词并提升句子节奏与准确性',
      isBuiltIn: true,
      keywords: ['文风精修', '润色文风', '精修文字', '语言优化', '修改病句', '去赘词'],
      content: '''【文风精修规范】

1. 先保留事实、人物意图和叙事视角，再调整措辞，不能借润色擅自改剧情。
2. 删除重复解释、同义形容和已经被动作证明的情绪标签。
3. 把抽象判断换成可观察的动作、细节或结果，但不为每句话都添加修辞。
4. 调整连续同长度句子；动作段更利落，情绪转折处允许停顿和留白。
5. 检查主语漂移、指代不明、搭配错误、时间顺序与标点节奏。
6. 输出精修稿后，简短列出影响最大的修改类型；拿不准的作者意图不要强改。''',
    ),
  ];
}
