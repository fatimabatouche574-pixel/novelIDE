import 'package:flutter/material.dart';
import 'package:novel_ide/core/theme/ui_tokens.dart';

/// Token 用量环形进度指示器
///
/// 使用 [CustomPainter] 绘制环形进度，中央显示百分比文字。
/// 值变化时带 300ms 线性动画过渡。
class OperitTokenRing extends StatefulWidget {
  const OperitTokenRing({
    super.key,
    required this.percent,
    this.size = 44.0,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// 用量百分比 0.0-1.0
  final double percent;

  /// 控件尺寸，默认 44
  final double size;

  /// 背景圆环颜色，默认 [UiTokens.outlineVariant]
  final Color? backgroundColor;

  /// 前景圆环颜色，默认 [UiTokens.primary]
  final Color? foregroundColor;

  @override
  State<OperitTokenRing> createState() => _OperitTokenRingState();
}

class _OperitTokenRingState extends State<OperitTokenRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _currentPercent = widget.percent;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: _currentPercent,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant OperitTokenRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percent != widget.percent) {
      _animation = Tween<double>(
        begin: _currentPercent,
        end: widget.percent,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _currentPercent = widget.percent;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ?? UiTokens.outlineVariant;
    final fgColor = widget.foregroundColor ?? UiTokens.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _TokenRingPainter(
            percent: _animation.value,
            backgroundColor: bgColor,
            foregroundColor: fgColor,
          ),
        );
      },
    );
  }
}

class _TokenRingPainter extends CustomPainter {
  _TokenRingPainter({
    required this.percent,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final double percent;
  final Color backgroundColor;
  final Color foregroundColor;

  static const double _strokeWidth = 3.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - _strokeWidth;

    // 背景圆环
    final bgPaint = Paint()
      ..color = backgroundColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // 前景圆环
    final fgPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.1415926535 * percent;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.1415926535 / 2, // 从12点钟方向开始
      sweepAngle,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TokenRingPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.foregroundColor != foregroundColor;
  }
}
