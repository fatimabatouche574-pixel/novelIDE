import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:novel_ide/data/models/ai_config_model.dart';
import 'package:novel_ide/data/models/ai_chat_session_model.dart';
import 'package:novel_ide/data/models/proactive_question_model.dart';
import 'package:novel_ide/data/models/writing_skill_model.dart';
import 'package:novel_ide/data/models/tomato_preset_model.dart';
import 'package:novel_ide/presentation/state/app_providers.dart';
import 'package:novel_ide/data/services/ai_service.dart';
import 'package:novel_ide/data/services/novel_memory.dart';
import 'package:novel_ide/data/services/user_memory.dart';
import 'package:novel_ide/data/services/workspace_agent.dart';
import 'package:novel_ide/data/services/agent_tool_executors.dart';
import 'package:novel_ide/data/services/voice_service.dart';
import 'package:novel_ide/data/services/skill_matcher.dart';
import 'package:novel_ide/data/services/fuzzy_need_detector.dart';
import 'package:novel_ide/data/repositories/chat_history_repository.dart';
import 'package:novel_ide/presentation/widgets/top_notification.dart';
import 'package:novel_ide/presentation/widgets/skill_indicator.dart';
import 'package:novel_ide/presentation/widgets/proactive_question_dialog.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';
import 'package:novel_ide/presentation/pages/ai/voice_call_page.dart';

/// AI chat session model.
class AiChatSession {
  final String id;
  String title;
  List<Map<String, String>> messages;
  final DateTime createdAt;

  AiChatSession({
    required this.id,
    required this.title,
    List<Map<String, String>>? messages,
    DateTime? createdAt,
  }) : messages = messages != null ? List.from(messages) : [],
       createdAt = createdAt ?? DateTime.now();
}

/// GPT风格聊天页面 - 纯聊天消息列表 + 底部胶囊式输入框
class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage>
    with WidgetsBindingObserver {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<AiChatSession> _sessions = [];
  AiChatSession? _currentSession;
  bool _isLoading = false;
  DateTime _lastProactiveCardTime = DateTime(2000); // 选择卡片冷却

  // 语音相关
  final VoiceService _voiceService = VoiceService();

  // 技能匹配记录：assistant消息索引 → 匹配到的技能列表
  final Map<int, List<WritingSkill>> _skillMatches = {};

  // 深度思考内容：assistant消息索引 → 思考内容
  final Map<int, String> _thinkingContents = {};

  // 展开的思考卡片索引
  final Set<int> _expandedThinking = {};

  // 历史记录仓库
  final ChatHistoryRepository _historyRepo = ChatHistoryRepository();
  bool _isHistoryLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVoice();
    _loadHistory();

    // 监听新建会话触发器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<int>(newSessionTriggerProvider, (previous, next) {
        if (next != previous && next > 0) {
          _newSession();
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveHistory();
    }
  }

  Future<void> _loadHistory() async {
    try {
      final savedSessions = await _historyRepo.loadSessions();
      if (savedSessions.isNotEmpty && mounted) {
        setState(() {
          _sessions.clear();
          for (final model in savedSessions) {
            _sessions.add(
              AiChatSession(
                id: model.id,
                title: model.title,
                messages: model.messages,
                createdAt: model.createdAt,
              ),
            );
          }
          _currentSession = _sessions.first;
        });
      }
      _isHistoryLoaded = true;
    } catch (e) {
      debugPrint('Load history error: $e');
      _isHistoryLoaded = true;
    }
  }

  Future<void> _saveHistory() async {
    if (!_isHistoryLoaded) return;
    try {
      final models = _sessions
          .map(
            (s) => AiChatSessionModel(
              id: s.id,
              title: s.title,
              messages: s.messages,
              createdAt: s.createdAt,
              updatedAt: DateTime.now(),
            ),
          )
          .toList();
      await _historyRepo.saveSessions(models);
    } catch (e) {
      debugPrint('Save history error: $e');
    }
  }

  Future<void> _initVoice() async {
    await _voiceService.init();
    if (mounted) setState(() {});
  }

  void _newSession() {
    final session = AiChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '新会话 ${_sessions.length + 1}',
    );
    setState(() {
      _sessions.insert(0, session);
      _currentSession = session;
      _skillMatches.clear();
      _thinkingContents.clear();
      _expandedThinking.clear();
    });
  }

  /// 停止AI生成
  void _stopGenerate() {
    setState(() {
      _isLoading = false;
    });
    // 如果有部分生成的内容，保留它
    if (_currentSession != null && _currentSession!.messages.isNotEmpty) {
      final lastMsg = _currentSession!.messages.last;
      if (lastMsg['role'] == 'assistant' &&
          (lastMsg['content']?.isEmpty ?? true)) {
        _currentSession!.messages.removeLast();
      }
    }
    _scrollToBottom();
  }

  void _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    if (_currentSession == null) _newSession();

    final config = ref.read(effectiveAiConfigProvider);
    if (config == null) {
      TopNotification.error(context, '请先配置AI模型');
      return;
    }

    // 模糊需求检测（带30秒冷却，避免频繁弹窗）
    final now = DateTime.now();
    final canShowCard = now.difference(_lastProactiveCardTime).inSeconds > 30;
    if (canShowCard) {
      final detector = FuzzyNeedDetector();
      final fuzzyType = await detector.detect(
        text,
        config: config,
        userMemory: await UserMemory.load().catchError((_) => ''),
        novelContext: ref.read(selectedNovelProvider) != null
            ? await NovelMemory.getForAiContext(
                ref.read(selectedNovelProvider)!.id,
                ref.read(selectedNovelProvider)!.title,
              ).catchError((_) => '')
            : null,
      );

      if (fuzzyType != null) {
        List<WritingSkill>? skills;
        try {
          final skillRepo = ref.read(skillRepoProvider);
          skills = await skillRepo.getAllSkills();
        } catch (e) {
          debugPrint('Load materials error: $e');
        }

        final question = await detector.generateQuestion(
          text,
          fuzzyType,
          config: config,
          userMemory: await UserMemory.load().catchError((_) => ''),
          novelContext: ref.read(selectedNovelProvider) != null
              ? await NovelMemory.getForAiContext(
                  ref.read(selectedNovelProvider)!.id,
                  ref.read(selectedNovelProvider)!.title,
                ).catchError((_) => '')
              : null,
          availableSkills: skills,
        );

        if (question != null && mounted) {
          ProactiveSelection? selection;
          await ProactiveQuestionDialog.show(
            context,
            question: question,
            onSelected: (s) => selection = s,
            onSkipped: () => selection = null,
          );

          if (selection != null) {
            _inputCtrl.text = '$text\n\n[用户选择：${selection!.toAiContext()}]';
          }
        }
      }
      _lastProactiveCardTime = now; // 更新冷却时间戳
    }

    setState(() {
      _currentSession!.messages.add({
        'role': 'user',
        'content': _inputCtrl.text.trim(),
      });
      if (_currentSession!.messages.length == 1) {
        _currentSession!.title = text.length > 20
            ? '${text.substring(0, 20)}...'
            : text;
      }
      _isLoading = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    try {
      final preset = ref.read(currentPresetProvider);
      // Agent系统提示作为基础，预设/用户自定义作为角色补充
      var systemPrompt =
          preset?.systemPrompt ?? '你是用户的网文创作伙伴，根据对话自然回应，不强行推销功能。';

      List<WritingSkill> matchedSkills = [];
      try {
        final skillRepo = ref.read(skillRepoProvider);
        final allSkills = await skillRepo.getAllSkills();
        final enabled = allSkills.where((s) => s.isEnabled).toList();
        matchedSkills = SkillMatcher.match(text, enabled);
        if (matchedSkills.isNotEmpty) {
          systemPrompt = SkillMatcher.injectSkillContext(
            systemPrompt,
            matchedSkills,
          );
        }
      } catch (e) {
        debugPrint('Load materials error: $e');
      }

      String memoryContext = '';
      try {
        final novel = ref.read(selectedNovelProvider);
        if (novel != null) {
          memoryContext = await NovelMemory.getForAiContext(
            novel.id,
            novel.title,
          );
        }
      } catch (e) {
        debugPrint('Load materials error: $e');
      }

      String userMemoryContext = '';
      try {
        userMemoryContext = await UserMemory.getForAiContext();
      } catch (e) {
        debugPrint('Load materials error: $e');
      }

      if (_currentSession!.messages.length > 600) {
        await _compactMessages(config);
      }

      final novel = ref.read(selectedNovelProvider);

      // 始终使用Agent模式，创建Agent并注册所有工具
      final agent = WorkspaceAgent();
      if (novel != null) {
        registerAllToolExecutors(
          agent: agent,
          novelId: novel.id,
          novelTitle: novel.title,
          presetAgents: ref.read(tomatoAgentsProvider),
          aiConfig: config,
        );
      } else {
        registerGeneralToolExecutors(
          agent: agent,
          presetAgents: ref.read(tomatoAgentsProvider),
          aiConfig: config,
          onSwitchNovel: (id) {
            final novels = ref.read(novelsProvider).valueOrNull ?? [];
            final novel = novels.where((n) => n.id == id).firstOrNull;
            if (novel != null) {
              ref.read(selectedNovelProvider.notifier).state = novel;
              loadNovelMaterials(ref, id);
            }
          },
          onNovelCreated: (novelId, novelTitle) {
            // 刷新作品列表
            ref.invalidate(novelsProvider);
            // 延迟选中新创建的作品，等待列表刷新完成
            Future.delayed(const Duration(milliseconds: 500), () {
              final novels = ref.read(novelsProvider).valueOrNull ?? [];
              final novel = novels.where((n) => n.id == novelId).firstOrNull;
              if (novel != null) {
                ref.read(selectedNovelProvider.notifier).state = novel;
                loadNovelMaterials(ref, novelId);
              }
            });
          },
        );
      }

      final effectiveSystemPrompt = novel != null
          ? '$systemPrompt\n\n小说记忆文件（当前状态）：\n$memoryContext$userMemoryContext'
          : '$systemPrompt\n\n$userMemoryContext';

      final response = await agent.chat(
        config: config,
        messages: _currentSession!.messages,
        systemPrompt: effectiveSystemPrompt,
      );

      setState(() {
        _currentSession!.messages.add({
          'role': 'assistant',
          'content': response.content,
        });
        final msgIdx = _currentSession!.messages.length - 1;
        if (matchedSkills.isNotEmpty) {
          _skillMatches[msgIdx] = matchedSkills;
        }
        if (response.thinkingContent != null &&
            response.thinkingContent!.isNotEmpty) {
          _thinkingContents[msgIdx] = response.thinkingContent!;
        }
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _currentSession!.messages.add({
          'role': 'assistant',
          'content': '请求失败: $e',
        });
        _isLoading = false;
      });
    }
  }

  Future<void> _compactMessages(AiConfig config) async {
    try {
      final msgs = _currentSession!.messages;
      final toSummarize = msgs
          .take(30)
          .map((m) => '${m['role']}: ${m['content']}')
          .join('\n');
      final aiService = ref.read(aiServiceProvider);
      final summary = await aiService.send(
        config: config,
        systemPrompt: '你是一个对话摘要助手。请将以下对话压缩为简短的摘要（200字以内），保留关键信息和上下文。',
        userMessage: toSummarize,
        taskType: 'chat',
      );
      setState(() {
        _currentSession!.messages = [
          {'role': 'user', 'content': '以下是之前的对话摘要，请据此回复用户后续的问题：\n$summary'},
          ...msgs.skip(30),
        ];
      });
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveHistory();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  // 主题颜色实例变量（build 时更新）
  late Color _bgColor;
  late Color _cardBg;
  late Color _cardBg2;
  late Color _primaryColor;
  late Color _textPrimary;
  late Color _textSecondary;
  late Color _textTertiary;

  @override
  Widget build(BuildContext context) {
    final messages = _currentSession?.messages ?? [];

    // 从主题系统读取颜色
    final skin = ref.watch(skinThemeProvider);
    _bgColor = skin.background;
    _cardBg = skin.surface;
    _cardBg2 = skin.cardBg;
    _primaryColor = skin.primary;
    _textPrimary = skin.textPrimary;
    _textSecondary = skin.textSecondary;
    _textTertiary = skin.textSecondary.withOpacity(0.7);

    return Container(
      color: _bgColor,
      child: Column(
        children: [
          // 聊天消息列表
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return _buildTypingIndicator();
                      }
                      final msg = messages[index];
                      final isUser = msg['role'] == 'user';
                      final matchedForThis = _skillMatches[index];
                      final thinkingForThis = _thinkingContents[index];
                      return _buildMessage(
                        msg['content']!,
                        isUser,
                        matchedForThis,
                        index,
                        thinkingContent: thinkingForThis,
                      );
                    },
                  ),
          ),
          // 底部胶囊式输入框
          _buildInputBar(),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI头像
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _textPrimary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  'AI',
                  style: TextStyle(
                    color: _bgColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              '欢迎使用网文写作IDE！',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '我可以帮助你构思大纲、创建角色、润色文字、分析爽点分布。',
              style: TextStyle(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            // 快捷操作
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickChip('构思剧情', () => _quickSend('帮我构思一个有趣的剧情')),
                _buildQuickChip('起个书名', () => _quickSend('帮我起5个吸引人的书名')),
                _buildQuickChip('设计角色', () => _quickSend('帮我设计一个有意思的主角')),
                _buildQuickChip('生成大纲', () => _quickSend('帮我写一个小说大纲')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _cardBg2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: TextStyle(color: _textPrimary, fontSize: 13)),
      ),
    );
  }

  void _quickSend(String text) {
    _inputCtrl.text = text;
    _sendMessage();
  }

  /// 消息气泡
  Widget _buildMessage(
    String content,
    bool isUser,
    List<WritingSkill>? skills,
    int index, {
    String? thinkingContent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (skills != null && skills.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 44),
            child: SkillIndicator(matchedSkills: skills),
          ),
        if (thinkingContent != null && thinkingContent.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 44),
            child: _CollapsibleThinkingCard(thinkingContent: thinkingContent),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isUser ? _primaryColor : _textPrimary,
                  borderRadius: BorderRadius.circular(isUser ? 14 : 4),
                ),
                child: Center(
                  child: Icon(
                    isUser ? Icons.person : Icons.smart_toy,
                    color: isUser ? _textPrimary : _bgColor,
                    size: 16,
                  ),
                ),
              ),
              // 内容
              Expanded(
                child: GestureDetector(
                  onLongPress: () => _showMessageMenu(content, index),
                  child: isUser
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _cardBg2,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            content,
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 15,
                              height: 1.6,
                            ),
                          ),
                        )
                      : SelectableText(
                          content,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 深度思考可折叠卡片
  Widget _buildThinkingCard(int index, String thinkingContent) {
    final isExpanded = _expandedThinking.contains(index);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedThinking.remove(index);
          } else {
            _expandedThinking.add(index);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 40),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: _primaryColor.withOpacity(0.4), width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, size: 16, color: _textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExpanded ? '已深度思考（点击收起）' : '已深度思考（点击展开）',
                    style: TextStyle(color: _textSecondary, fontSize: 13),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _textSecondary,
                  size: 18,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 8),
              Divider(height: 1, color: _cardBg2),
              const SizedBox(height: 8),
              SelectableText(
                thinkingContent,
                style: TextStyle(
                  color: _textPrimary.withOpacity(0.75),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 加载中指示器
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _textPrimary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                'AI',
                style: TextStyle(
                  color: _bgColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _textTertiary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 底部胶囊式输入框
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, _bgColor],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg2,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // + 按钮
            IconButton(
              icon: Icon(Icons.add, color: _textSecondary, size: 22),
              onPressed: _showBottomSheet,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            // 输入框
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                maxLines: null,
                minLines: 1,
                style: TextStyle(color: _textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(color: _textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                ),
                onChanged: (_) => setState(() {}), // 输入时实时更新发送按钮状态
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            // 发送/停止/语音按钮
            _isLoading
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.stop_rounded,
                        color: _textPrimary,
                        size: 22,
                      ),
                      onPressed: _stopGenerate,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  )
                : _inputCtrl.text.isNotEmpty
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: _bgColor, size: 20),
                      onPressed: _sendMessage,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _cardBg2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.call, color: _primaryColor, size: 20),
                      onPressed: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VoiceCallPage(
                              onCallEnd: (transcript, aiResponse) {
                                if (mounted) {
                                  _inputCtrl.text = transcript;
                                }
                              },
                            ),
                          ),
                        );
                        if (result != null && result.isNotEmpty && mounted) {
                          _inputCtrl.text = result;
                        }
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// 显示底部弹窗菜单 - 附加功能
  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _cardBg2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '附加',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildAttachmentItem(
                icon: Icons.psychology,
                title: 'Skills',
                subtitle: '选择已启用的技能',
                onTap: () {
                  Navigator.pop(ctx);
                  _showSkillsPicker();
                },
              ),
              _buildAttachmentItem(
                icon: Icons.folder,
                title: '作品区',
                subtitle: '选择章节/文件',
                onTap: () {
                  Navigator.pop(ctx);
                  _showWorkspacePicker();
                },
              ),
              _buildAttachmentItem(
                icon: Icons.source,
                title: '资料区',
                subtitle: '选择资料',
                onTap: () {
                  Navigator.pop(ctx);
                  _showMaterialPicker();
                },
              ),
              _buildAttachmentItem(
                icon: Icons.attach_file,
                title: '本地文件',
                subtitle: '上传文件',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleFileUpload();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 处理文件上传
  Future<void> _handleFileUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'md', 'docx', 'pdf'],
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      final file = File(filePath);
      if (!await file.exists()) return;

      // 读取文件内容
      String content = '';
      final ext = filePath.split('.').last.toLowerCase();

      if (ext == 'txt' || ext == 'md') {
        content = await file.readAsString();
      } else {
        // 对于 docx/pdf，暂时只显示文件名
        TopNotification.show(context, '暂不支持该格式，请使用TXT文件');
        return;
      }

      if (content.length > 5000) {
        content = content.substring(0, 5000) + '\n...(内容过长已截断)';
      }

      // 将文件内容插入输入框
      setState(() {
        _inputCtrl.text =
            '[上传文件：${result.files.first.name}]\n\n$content\n\n请帮我分析以上内容。';
      });

      TopNotification.success(context, '已读取文件：${result.files.first.name}');
    } catch (e) {
      TopNotification.error(context, '读取文件失败: $e');
    }
  }

  /// 构建附加菜单项
  Widget _buildAttachmentItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _cardBg2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: _primaryColor, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(color: _textTertiary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _textTertiary, size: 20),
          ],
        ),
      ),
    );
  }

  /// 显示技能选择器
  void _showSkillsPicker() {
    final skillsAsync = ref.watch(skillRepoProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: _cardBg2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '选择技能',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FutureBuilder<List<WritingSkill>>(
                future: skillsAsync.getAllSkills(),
                builder: (context, snapshot) {
                  final allSkills = snapshot.data ?? [];
                  final enabledSkills = allSkills
                      .where((s) => s.isEnabled)
                      .toList();

                  if (enabledSkills.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '暂无启用的技能',
                        style: TextStyle(color: _textTertiary, fontSize: 14),
                      ),
                    );
                  }

                  return Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: enabledSkills.length,
                      itemBuilder: (context, index) {
                        final skill = enabledSkills[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _cardBg2,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                skill.name.substring(0, 1),
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            skill.name,
                            style: TextStyle(color: _textPrimary, fontSize: 14),
                          ),
                          subtitle: Text(
                            skill.description,
                            style: TextStyle(
                              color: _textTertiary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            ref
                                .read(currentPresetProvider.notifier)
                                .state = TomatoPreset(
                              id: skill.id,
                              name: skill.name,
                              category: skill.category,
                              description: skill.description,
                              systemPrompt: skill.content,
                              tags: skill.keywords,
                            );
                            TopNotification.success(
                              context,
                              '已应用技能：${skill.name}',
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示作品区选择器（选择章节/文件）
  void _showWorkspacePicker() {
    final novel = ref.read(selectedNovelProvider);
    if (novel == null) {
      TopNotification.error(context, '请先选择一部作品');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: _cardBg2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.folder, size: 20, color: _primaryColor),
                  SizedBox(width: 8),
                  Text(
                    '选择章节',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _cardBg2),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: ref
                    .read(volumeRepoProvider)
                    .getVolumesByNovel(novel.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        '暂无章节',
                        style: TextStyle(color: _textTertiary, fontSize: 14),
                      ),
                    );
                  }

                  final volumes = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: volumes.length,
                    itemBuilder: (context, vIndex) {
                      final vol = volumes[vIndex];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Text(
                              vol.title,
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          FutureBuilder<List<dynamic>>(
                            future: ref
                                .read(chapterRepoProvider)
                                .getChaptersByVolume(vol.id),
                            builder: (context, chSnapshot) {
                              if (chSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              final chapters = chSnapshot.data ?? [];
                              if (chapters.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    '无章节',
                                    style: TextStyle(
                                      color: _textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: chapters
                                    .map(
                                      (ch) => ListTile(
                                        leading: Icon(
                                          Icons.description,
                                          color: _textPrimary,
                                          size: 18,
                                        ),
                                        title: Text(
                                          ch.title,
                                          style: TextStyle(
                                            color: _textPrimary,
                                            fontSize: 14,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          final buffer = StringBuffer();
                                          buffer.writeln('[章节：${ch.title}]');
                                          buffer.writeln(
                                            ch.content.length > 2000
                                                ? '${ch.content.substring(0, 2000)}...(内容过长已截断)'
                                                : ch.content,
                                          );
                                          _inputCtrl.text =
                                              '${buffer.toString()}\n${_inputCtrl.text}';
                                          TopNotification.success(
                                            context,
                                            '已选择章节：${ch.title}',
                                          );
                                        },
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示消息长按菜单
  void _showMessageMenu(String content, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: _cardBg2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.copy, color: _textPrimary),
                title: Text('复制', style: TextStyle(color: _textPrimary)),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: content));
                  Navigator.pop(ctx);
                  TopNotification.success(context, '已复制到剪贴板');
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('撤回', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteMessage(index);
                },
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 删除单条消息
  void _deleteMessage(int index) {
    if (_currentSession == null ||
        index < 0 ||
        index >= _currentSession!.messages.length)
      return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text('撤回消息', style: TextStyle(color: _textPrimary)),
        content: Text('确定要撤回这条消息吗？', style: TextStyle(color: _textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _currentSession!.messages.removeAt(index);
                _skillMatches.remove(index);
                final newMatches = <int, List<WritingSkill>>{};
                _skillMatches.forEach((key, value) {
                  if (key < index) {
                    newMatches[key] = value;
                  } else if (key > index) {
                    newMatches[key - 1] = value;
                  }
                });
                _skillMatches.clear();
                _skillMatches.addAll(newMatches);
              });
              _saveHistory();
              TopNotification.success(context, '消息已撤回');
            },
            child: Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 选择资料作为AI上下文
  void _showMaterialPicker() {
    final novel = ref.read(selectedNovelProvider);
    if (novel == null) {
      TopNotification.error(context, '请先选择一部作品');
      return;
    }
    final novelId = novel.id;

    final characters = ref.read(charactersProvider(novelId));
    final settings = ref.read(settingCardsProvider(novelId));
    final hooks = ref.read(plotHooksProvider(novelId));
    final references = ref.read(referencesProvider(novelId));

    final selectedIds = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPickerState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: _cardBg2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(Icons.library_books, size: 20, color: _primaryColor),
                    SizedBox(width: 8),
                    Text(
                      '选择资料',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${selectedIds.length} 项已选',
                      style: TextStyle(fontSize: 13, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: _cardBg2),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  children: [
                    _buildPickerSection(
                      '角色',
                      characters
                          .map(
                            (c) => (
                              c.id,
                              c.name,
                              '${c.role ?? ""} ${c.description ?? ""}'.trim(),
                            ),
                          )
                          .toList(),
                      selectedIds,
                      setPickerState,
                    ),
                    _buildPickerSection(
                      '设定',
                      settings
                          .map((s) => (s.id, s.name, s.description ?? ''))
                          .toList(),
                      selectedIds,
                      setPickerState,
                    ),
                    _buildPickerSection(
                      '伏笔',
                      hooks
                          .map((h) => (h.id, h.title, h.description ?? ''))
                          .toList(),
                      selectedIds,
                      setPickerState,
                    ),
                    _buildPickerSection(
                      '参考',
                      references
                          .map((r) => (r.id, r.title, r.content ?? ''))
                          .toList(),
                      selectedIds,
                      setPickerState,
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryColor,
                      ),
                      onPressed: selectedIds.isEmpty
                          ? null
                          : () {
                              final buffer = StringBuffer();
                              buffer.writeln('[选择的资料上下文]');
                              for (final c in characters.where(
                                (c) => selectedIds.contains(c.id),
                              )) {
                                buffer.writeln('## 角色：${c.name}');
                                if (c.role != null)
                                  buffer.writeln('定位: ${c.role}');
                                if (c.description != null)
                                  buffer.writeln(c.description);
                                buffer.writeln();
                              }
                              for (final s in settings.where(
                                (s) => selectedIds.contains(s.id),
                              )) {
                                buffer.writeln('## 设定：${s.name}');
                                if (s.description != null)
                                  buffer.writeln(s.description);
                                buffer.writeln();
                              }
                              buffer.writeln('---请基于以上资料回答用户的问题---');
                              _inputCtrl.text =
                                  '${buffer.toString()}\n${_inputCtrl.text}';
                              Navigator.pop(ctx);
                            },
                      child: Text('确定 (${selectedIds.length}项)'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerSection(
    String title,
    List<(String, String, String)> items,
    Set<String> selectedIds,
    StateSetter setPickerState,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ),
        for (final (id, name, desc) in items)
          CheckboxListTile(
            value: selectedIds.contains(id),
            onChanged: (v) => setPickerState(() {
              v == true ? selectedIds.add(id) : selectedIds.remove(id);
            }),
            title: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
            ),
            subtitle: Text(
              desc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: _textTertiary),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: _primaryColor,
          ),
      ],
    );
  }
}

/// 可折叠的深度思考卡片
class _CollapsibleThinkingCard extends StatefulWidget {
  final String thinkingContent;
  const _CollapsibleThinkingCard({required this.thinkingContent});

  @override
  State<_CollapsibleThinkingCard> createState() =>
      _CollapsibleThinkingCardState();
}

class _CollapsibleThinkingCardState extends State<_CollapsibleThinkingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade400, width: 2)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '💭 已深度思考',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SelectableText(
                widget.thinkingContent,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }
}
