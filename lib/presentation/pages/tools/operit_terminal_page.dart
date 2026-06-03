import 'dart:async';

import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

class OperitTerminalPage extends StatefulWidget {
  const OperitTerminalPage({super.key});

  @override
  State<OperitTerminalPage> createState() => _OperitTerminalPageState();
}

class _OperitTerminalPageState extends State<OperitTerminalPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showCursor = true;
  Timer? _cursorTimer;

  static const _sampleOutput = [
    _TermLine(prompt: '\$ ', text: 'ls -la', isCommand: true),
    _TermLine(text: 'total 48', isCommand: false),
    _TermLine(text: 'drwxr-xr-x  12 user  staff   384 Jun  3 10:30 .', isCommand: false),
    _TermLine(text: 'drwxr-xr-x   6 user  staff   192 Jun  2 14:20 ..', isCommand: false),
    _TermLine(
      text: '-rw-r--r--   1 user  staff  2048 Jun  3 09:15 config.yaml',
      isCommand: false,
    ),
    _TermLine(text: '-rw-r--r--   1 user  staff  4096 May 30 18:45 data.json', isCommand: false),
    _TermLine(text: 'drwxr-xr-x   8 user  staff   256 May 28 11:00 src', isCommand: false),
    _TermLine(text: '-rwxr-xr-x   1 user  staff  1024 May 25 08:30 run.sh', isCommand: false),
    _TermLine(text: 'drwxr-xr-x   5 user  staff   160 May 22 16:10 logs', isCommand: false),
    _TermLine(text: '-rw-r--r--   1 user  staff   512 May 20 12:00 README.md', isCommand: false),
    _TermLine(text: '', isCommand: false),
    _TermLine(prompt: '\$ ', text: 'echo "Hello, Operit!"', isCommand: true),
    _TermLine(text: 'Hello, Operit!', isCommand: false),
    _TermLine(text: '', isCommand: false),
    _TermLine(prompt: '\$ ', text: '', isCommand: true),
  ];

  @override
  void initState() {
    super.initState();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 530), (_) {
      if (mounted) {
        setState(() => _showCursor = !_showCursor);
      }
    });
  }

  @override
  void dispose() {
    _cursorTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UiTokens.sidebarBg,
      appBar: AppBar(
        backgroundColor: UiTokens.sidebarBg,
        foregroundColor: UiTokens.sidebarText,
        title: const Text('终端'),
        centerTitle: true,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          _scrollToBottom();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 300),
          padding: const EdgeInsets.all(12),
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _sampleOutput.length + 1,
            itemBuilder: (context, index) {
              if (index == _sampleOutput.length) {
                return _buildBlinkingCursor();
              }
              return _buildLine(_sampleOutput[index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLine(_TermLine line) {
    if (line.isCommand && line.prompt != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: UiTokens.bodyFS,
              height: 1.5,
            ),
            children: [
              TextSpan(
                text: line.prompt,
                style: TextStyle(
                  color: UiTokens.greenSuccess,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: line.text,
                style: const TextStyle(color: Color(0xFFCDD6F4)),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        line.text.isEmpty ? ' ' : line.text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: UiTokens.bodyFS,
          color: Color(0xFFA6ADC8),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBlinkingCursor() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: UiTokens.bodyFS,
          height: 1.5,
        ),
        children: [
          TextSpan(
            text: '\$ ',
            style: TextStyle(
              color: UiTokens.greenSuccess,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_showCursor)
            WidgetSpan(
              child: Container(
                width: 8,
                height: 16,
                color: const Color(0xFFCDD6F4),
              ),
            ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class _TermLine {
  final String? prompt;
  final String text;
  final bool isCommand;

  const _TermLine({this.prompt, required this.text, required this.isCommand});
}
