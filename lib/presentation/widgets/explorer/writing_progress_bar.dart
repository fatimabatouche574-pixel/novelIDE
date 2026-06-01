import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';

/// 写作进度条
///
/// 显示进度条 + 百分比 + 总字数 + 今日新增。使用 SkinTheme 颜色。
class WritingProgressBar extends ConsumerWidget {
  const WritingProgressBar({
    super.key,
    required this.totalWords,
    this.todayWords = 0,
    this.todayGoalPercent = 0.0,
    this.goalWords = 10000,
  });

  final int totalWords;
  final int todayWords;
  final double todayGoalPercent;
  final int goalWords;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinThemeProvider);
    final progress = (totalWords / goalWords).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: skin.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '写作进度',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: skin.textSecondary,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: skin.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: skin.textSecondary.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(skin.primary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '总字数: ${_formatWords(totalWords)}',
                style: TextStyle(fontSize: 11, color: skin.textSecondary),
              ),
              const Spacer(),
              if (todayWords > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: skin.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '今日 +${_formatWords(todayWords)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: skin.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatWords(int words) {
    if (words >= 10000) return '${(words / 10000).toStringAsFixed(1)}万';
    if (words >= 1000) return '${(words / 1000).toStringAsFixed(1)}k';
    return '$words';
  }
}
