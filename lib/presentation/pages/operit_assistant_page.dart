import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// Assistant configuration page — avatar setup & voice wake.
class OperitAssistantPage extends StatefulWidget {
  const OperitAssistantPage({super.key});

  @override
  State<OperitAssistantPage> createState() =>
      _OperitAssistantPageState();
}

class _OperitAssistantPageState extends State<OperitAssistantPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Tab 1 state
  double _scale = 1.0;
  double _xOffset = 0.0;
  double _yOffset = 0.0;
  final Set<String> _selectedEmotions = {'happy'};
  final List<_EmotionTag> _emotionTags = const [
    _EmotionTag('angry', '生气', Icons.sentiment_very_dissatisfied),
    _EmotionTag('happy', '开心', Icons.sentiment_very_satisfied),
    _EmotionTag('shy', '害羞', Icons.emoji_emotions),
    _EmotionTag('tsundere', '傲娇', Icons.face),
    _EmotionTag('cry', '哭泣', Icons.sentiment_dissatisfied),
  ];

  // Tab 2 state
  bool _continuousListening = false;
  bool _greetingEnabled = true;
  bool _voiceKeywordEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: const Text('助手配置'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '头像配置'),
            Tab(text: '语音唤醒'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvatarTab(),
          _buildVoiceTab(),
        ],
      ),
    );
  }

  // ── Tab 1: 头像配置 ──

  Widget _buildAvatarTab() {
    return ListView(
      padding: const EdgeInsets.all(UiTokens.pagePadH),
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: UiTokens.primaryContainer,
              border: Border.all(color: UiTokens.primary, width: 2),
            ),
            child: const Icon(Icons.person, size: 50, color: UiTokens.primary),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('视觉模型'),
        ListTile(
          leading: const Icon(Icons.view_in_ar),
          title: const Text('选择模型'),
          subtitle: const Text('Live2D / VRM / MMD'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.file_upload),
          title: const Text('导入模型'),
          subtitle: const Text('支持 zip / glb / gltf / mp4 / fbx'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),
        // Transform sliders
        _buildSectionTitle('变换'),
        _buildSlider('缩放', _scale * 100, 50, 200, (v) {
          setState(() => _scale = v / 100);
        }, unit: '%'),
        _buildSlider('X 偏移', _xOffset, -100, 100, (v) {
          setState(() => _xOffset = v);
        }),
        _buildSlider('Y 偏移', _yOffset, -100, 100, (v) {
          setState(() => _yOffset = v);
        }),
        const SizedBox(height: UiTokens.sectionSpacing),

        // Emotion tags
        _buildSectionTitle('情绪标签'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _emotionTags.map((tag) {
            final selected = _selectedEmotions.contains(tag.key);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tag.icon, size: 16),
                  const SizedBox(width: 4),
                  Text(tag.label),
                ],
              ),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _selectedEmotions.add(tag.key);
                  } else {
                    _selectedEmotions.remove(tag.key);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Tab 2: 语音唤醒 ──

  Widget _buildVoiceTab() {
    return ListView(
      padding: const EdgeInsets.all(UiTokens.pagePadH),
      children: [
        _buildSectionTitle('唤醒模式'),
        ListTile(
          leading: const Icon(Icons.mic),
          title: const Text('STT 语音识别'),
          subtitle: const Text('语音转文字唤醒'),
          trailing: const Icon(Icons.check_circle, color: UiTokens.greenSuccess),
        ),
        const Divider(),

        SwitchListTile(
          title: const Text('持续监听'),
          subtitle: const Text('始终在后台监听唤醒词'),
          value: _continuousListening,
          onChanged: (v) => setState(() => _continuousListening = v),
        ),
        const Divider(),

        _buildSectionTitle('唤醒词'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: UiTokens.primaryContainer,
            borderRadius: BorderRadius.circular(UiTokens.cardRadius),
          ),
          child: const Row(
            children: [
              Icon(Icons.record_voice_over, color: UiTokens.primary),
              SizedBox(width: 12),
              Text(
                '你好助手',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: UiTokens.sectionSpacing),

        _buildSectionTitle('空闲设置'),
        ListTile(
          leading: const Icon(Icons.timer),
          title: const Text('无操作超时'),
          subtitle: const Text('30 秒'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const Divider(),

        SwitchListTile(
          title: const Text('欢迎语'),
          subtitle: const Text('你好，我是你的写作助手，有什么可以帮你的吗？'),
          value: _greetingEnabled,
          onChanged: (v) => setState(() => _greetingEnabled = v),
        ),
        const Divider(),

        _buildSectionTitle('聊天行为'),
        SwitchListTile(
          title: const Text('自动回复'),
          subtitle: const Text('检测到语音输入后自动回复'),
          value: true,
          onChanged: (_) {},
        ),
        SwitchListTile(
          title: const Text('语音关键词触发'),
          subtitle: const Text('特定关键词触发特殊行为'),
          value: _voiceKeywordEnabled,
          onChanged: (v) => setState(() => _voiceKeywordEnabled = v),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: UiTokens.smallFS,
          fontWeight: FontWeight.bold,
          color: UiTokens.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    String unit = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: UiTokens.bodyFS)),
            Text(
              '${value.toStringAsFixed(0)}$unit',
              style: const TextStyle(
                fontSize: UiTokens.bodyFS,
                color: UiTokens.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _EmotionTag {
  final String key;
  final String label;
  final IconData icon;
  const _EmotionTag(this.key, this.label, this.icon);
}
