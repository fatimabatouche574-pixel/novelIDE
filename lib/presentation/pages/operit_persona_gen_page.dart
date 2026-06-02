import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// Persona card generation page — editor & dialogue training.
class OperitPersonaGenPage extends StatefulWidget {
  const OperitPersonaGenPage({super.key});

  @override
  State<OperitPersonaGenPage> createState() =>
      _OperitPersonaGenPageState();
}

class _OperitPersonaGenPageState extends State<OperitPersonaGenPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _settingCtrl = TextEditingController();
  final _openingCtrl = TextEditingController();
  final _chatCtrl = TextEditingController();
  final _voiceCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _settingCtrl.dispose();
    _openingCtrl.dispose();
    _chatCtrl.dispose();
    _voiceCtrl.dispose();
    _promptCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('角色卡生成'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '编辑器'),
            Tab(text: '对话训练'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建角色卡',
            onPressed: _createNewPersona,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '删除当前',
            onPressed: _deletePersona,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEditorTab(),
          _buildTrainingTab(),
        ],
      ),
    );
  }

  Widget _buildEditorTab() {
    return ListView(
      padding: const EdgeInsets.all(UiTokens.pagePadH),
      children: [
        _buildTextField('角色名称', _nameCtrl, hint: '输入角色名称'),
        const SizedBox(height: 12),
        _buildTextField('角色描述', _descCtrl, hint: '简要描述角色特征', maxLines: 2),
        const SizedBox(height: 12),
        _buildTextField(
          '角色设定',
          _settingCtrl,
          hint: '详细设定信息，包括性格、背景等',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _buildTextField('开场白', _openingCtrl, hint: '角色初次对话的开场白', maxLines: 2),
        const SizedBox(height: 12),
        _buildTextField(
          '对话内容',
          _chatCtrl,
          hint: '其他聊天内容参考',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          '语音内容',
          _voiceCtrl,
          hint: '其他语音内容参考',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          '高级提示词',
          _promptCtrl,
          hint: '给 AI 模型的高级提示词',
          maxLines: 4,
        ),
        const SizedBox(height: 12),
        _buildTextField('备注', _notesCtrl, hint: '其他备注信息', maxLines: 2),
      ],
    );
  }

  Widget _buildTrainingTab() {
    return ListView(
      padding: const EdgeInsets.all(UiTokens.pagePadH),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: UiTokens.primaryContainer,
            borderRadius: BorderRadius.circular(UiTokens.cardRadius),
          ),
          child: const Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: UiTokens.primary),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '对话训练',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: UiTokens.bodyFS,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '0/40 条消息',
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
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.forum,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                '暂无训练数据',
                style: TextStyle(
                  fontSize: UiTokens.bodyFS,
                  color: Colors.grey.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '请先在编辑器中创建角色卡，然后添加对话训练数据',
                style: TextStyle(
                  fontSize: UiTokens.smallFS,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String hint = '',
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: UiTokens.smallFS,
            fontWeight: FontWeight.bold,
            color: UiTokens.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: UiTokens.bodyFS),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(UiTokens.cardRadius),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: UiTokens.bodyFS),
        ),
      ],
    );
  }

  void _createNewPersona() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已创建新角色卡')),
    );
    _clearAllFields();
  }

  void _deletePersona() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除角色卡'),
        content: const Text('确定要删除当前角色卡吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: UiTokens.error),
            onPressed: () {
              Navigator.pop(ctx);
              _clearAllFields();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已删除角色卡')),
                );
              }
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _clearAllFields() {
    _nameCtrl.clear();
    _descCtrl.clear();
    _settingCtrl.clear();
    _openingCtrl.clear();
    _chatCtrl.clear();
    _voiceCtrl.clear();
    _promptCtrl.clear();
    _notesCtrl.clear();
  }
}
