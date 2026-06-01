import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/core/theme/app_themes.dart';
import 'package:novel_ide/core/theme/skin_provider.dart';

/// 手机端布局组件
///
/// 管理侧边栏滑入/滑出动画、拖拽手势和遮罩层。
/// 使用弹簧动画（320ms Curves.elasticOut）实现自然的物理感。
class PhoneLayout extends ConsumerStatefulWidget {
  const PhoneLayout({
    super.key,
    required this.sidebar,
    required this.content,
    required this.sidebarOpen,
    required this.onSidebarOpenChanged,
    this.modelDropdown,
  });

  /// 侧边栏内容
  final Widget sidebar;

  /// 主内容区
  final Widget content;

  /// 侧边栏是否打开
  final bool sidebarOpen;

  /// 侧边栏开关回调
  final ValueChanged<bool> onSidebarOpenChanged;

  /// 可选的模型下拉菜单
  final Widget? modelDropdown;

  @override
  ConsumerState<PhoneLayout> createState() => _PhoneLayoutState();
}

class _PhoneLayoutState extends ConsumerState<PhoneLayout>
    with SingleTickerProviderStateMixin {
  static const _sidebarWidth = 280.0;
  static const _animationDuration = Duration(milliseconds: 320);
  static const _animationCurve = Curves.elasticOut;

  late AnimationController _controller;
  late Animation<double> _animation;

  /// 拖拽状态
  double _dragStartX = 0;
  bool _isDragging = false;
  bool _dragOpened = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: _animationCurve,
    );
    if (widget.sidebarOpen) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant PhoneLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sidebarOpen != oldWidget.sidebarOpen) {
      widget.sidebarOpen
          ? _controller.forward()
          : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── 拖拽手势 ──────────────────────────────────────────────

  void _handleDragStart(DragStartDetails details) {
    // 仅在屏幕左侧 30px 范围内起始时激活
    if (details.globalPosition.dx < 30) {
      _isDragging = true;
      _dragStartX = details.globalPosition.dx;
      _dragOpened = widget.sidebarOpen;
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final delta = details.globalPosition.dx - _dragStartX;
    final progress = (delta / _sidebarWidth).clamp(0.0, 1.0);
    _controller.value = _dragOpened ? (1.0 - progress) : progress;
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.velocity.pixelsPerSecond.dx;
    final shouldOpen = _dragOpened
        ? _controller.value < 0.7
        : (_controller.value > 0.3 || velocity > 300);

    widget.onSidebarOpenChanged(shouldOpen);
  }

  // ── 构建 ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinThemeProvider);

    return Scaffold(
      backgroundColor: skin.background,
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // 主内容区
              widget.content,

              // 遮罩层（侧边栏打开时显示）
              _buildMask(skin),

              // 左侧侧边栏（滑入动画）
              _buildSidebar(),

              // 模型选择下拉菜单
              if (widget.modelDropdown != null) widget.modelDropdown!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMask(SkinTheme skin) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value * 0.45;
        if (opacity <= 0) return const SizedBox.shrink();
        return Positioned.fill(
          child: GestureDetector(
            onTap: () => widget.onSidebarOpenChanged(false),
            child: Container(color: Colors.black.withOpacity(opacity)),
          ),
        );
      },
    );
  }

  Widget _buildSidebar() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final offset = -_sidebarWidth * (1 - _animation.value);
        return Positioned(
          left: offset,
          top: 0,
          bottom: 0,
          width: _sidebarWidth,
          child: child!,
        );
      },
      child: Material(
        elevation: 16,
        child: widget.sidebar,
      ),
    );
  }
}
