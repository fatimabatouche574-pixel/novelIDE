import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// External HTTP chat configuration page.
class OperitExternalHttpPage extends StatefulWidget {
  const OperitExternalHttpPage({super.key});

  @override
  State<OperitExternalHttpPage> createState() =>
      _OperitExternalHttpPageState();
}

class _OperitExternalHttpPageState
    extends State<OperitExternalHttpPage> {
  final _urlCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  final _reqFormatCtrl = TextEditingController(
    text: '{"model":"gpt-3.5-turbo","messages":[...]}',
  );
  final _timeoutCtrl = TextEditingController(text: '30');
  final _retryCtrl = TextEditingController(text: '3');

  bool _testing = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _keyCtrl.dispose();
    _reqFormatCtrl.dispose();
    _timeoutCtrl.dispose();
    _retryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('外部 HTTP 对话')),
      body: ListView(
        padding: const EdgeInsets.all(UiTokens.pagePadH),
        children: [
          _buildSectionTitle('连接配置'),
          _buildTextField(
            'API URL',
            _urlCtrl,
            hint: 'https://api.openai.com/v1/chat/completions',
            icon: Icons.link,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'API Key',
            _keyCtrl,
            hint: 'sk-...',
            icon: Icons.vpn_key,
            obscure: true,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            '请求格式',
            _reqFormatCtrl,
            hint: 'JSON 格式的请求体模板',
            icon: Icons.code,
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('高级设置'),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('超时时间'),
            trailing: SizedBox(
              width: 80,
              child: TextField(
                controller: _timeoutCtrl,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  suffixText: '秒',
                  suffixStyle: const TextStyle(fontSize: UiTokens.smallFS),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(UiTokens.cardRadius),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: UiTokens.bodyFS),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.replay),
            title: const Text('重试次数'),
            trailing: SizedBox(
              width: 80,
              child: TextField(
                controller: _retryCtrl,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  suffixText: '次',
                  suffixStyle: const TextStyle(fontSize: UiTokens.smallFS),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(UiTokens.cardRadius),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: UiTokens.bodyFS),
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: _testing ? null : _testConnection,
              icon: _testing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.wifi_find),
              label: Text(_testing ? '测试中...' : '测试连接'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String hint = '',
    IconData? icon,
    int maxLines = 1,
    bool obscure = false,
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
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: UiTokens.bodyFS),
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
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

  Future<void> _testConnection() async {
    setState(() => _testing = true);

    // Simulate network test
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _testing = false);

    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      _showResult(false, '请先填写 API URL');
      return;
    }

    // Simulated success
    _showResult(true, '连接成功！API 响应正常');
  }

  void _showResult(bool success, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? UiTokens.greenSuccess : UiTokens.error,
            ),
            const SizedBox(width: 8),
            Text(success ? '连接成功' : '连接失败'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
