import 'dart:async';

import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// 显示 Operit 风格的 Toast/Snackbar 覆盖层
///
/// 在屏幕底部显示深色圆角提示条，2 秒后自动消失。
/// 使用 [ScaffoldMessenger]（回退到 [Overlay]），
/// 深色背景（onSurface），白色文字，10px 圆角。
void showOperitToast(BuildContext context, String message) {
  final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);

  if (scaffoldMessenger != null) {
    scaffoldMessenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: UiTokens.onSurface.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 6,
        ),
      );
  } else {
    // 回退：使用 Overlay
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 36,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: UiTokens.onSurface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Timer(const Duration(seconds: 2), () => entry.remove());
  }
}
