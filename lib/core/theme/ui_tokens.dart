import 'package:flutter/material.dart';

/// NovelIDE UI 设计令牌 - Operit Material You purple design system
class UiTokens {
  UiTokens._();

  // ── 颜色 (对应 Operit-HTML CSS变量) ──
  static const primary = Color(0xFF7C4DFF);
  static const primaryContainer = Color(0xFFEDE7FF);
  static const onPrimaryContainer = Color(0xFF22005D);
  static const secondary = Color(0xFF625B71);
  static const secondaryContainer = Color(0xFFE8DEF8);
  static const tertiary = Color(0xFF7D5260);
  static const tertiaryContainer = Color(0xFFFFD8E4);
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFF9DEDC);
  static const surface = Color(0xFFFFFBFE);
  static const surfaceVariant = Color(0xFFE7E0EC);
  static const onSurface = Color(0xFF1C1B1F);
  static const onSurfaceVariant = Color(0xFF49454F);
  static const outlineVariant = Color(0xFFCAC4D0);
  static const greenSuccess = Color(0xFF2E7D32);

  // ── 侧边栏暗色方案 ──
  static const sidebarBg = Color(0xFF1E1E2E);
  static const sidebarText = Color(0xFFCDD6F4);
  static const sidebarActive = Color(0xFFCBA6F7);
  static const sidebarItemBg = Color(0xFF313244);
  static const sidebarHover = Color(0xFF45475A);
  static const sidebarActiveBg = Color.fromRGBO(203, 166, 247, 0.18);

  // ── 尺寸 ──
  static const double sidebarWidth = 240.0;
  static const double drawerW = 280.0;
  static const double toolbarH = 52.0;
  static const double topBarHeight = 46.0;
  static const double navItemHeight = 40.0;
  static const double quickCardHeight = 60.0;
  static const double bottomBtnHeight = 48.0;
  static const double cardRadius = 8.0;
  static const double groupRadius = 6.0;
  static const double inputRadius = 22.0;
  static const double bubbleRadius = 16.0;
  static const double bubbleBorderRadius = 16.0;
  static const double fabSize = 40.0;
  static const double toolCardHeight = 130.0;
  static const double themeCardHeight = 68.0;
  static const double avatarSize = 28.0;
  static const double chatAvatarSize = 32.0;
  static const double iconSize = 14.0;
  static const double navIconSize = 15.0;
  static const double quickIconSize = 16.0;
  static const double pagePadH = 12.0;
  static const double msgGap = 6.0;
  static const double sectionSpacing = 8.0;
  static const double bubbleMax = 0.85;

  // ── 字体 ──
  static const double titleFS = 13.0;
  static const double bodyFS = 12.0;
  static const double smallFS = 10.0;
  static const double microFS = 9.0;
  static const double tinyFS = 7.0;
  static const double brandFS = 18.0;

  // ── 动画时长（与 Flutter Drawer 默认 246ms 同步）──
  static const int drawerAnimMs = 246;
  static const int screenInMs = 280;

  // ── Z-index / 层级常量 ──
  static const int zLayerMask = 900;
  static const int zLayerDrawer = 1000;
  static const int zLayerDropdown = 1100;
  static const int zLayerToast = 2000;
}
