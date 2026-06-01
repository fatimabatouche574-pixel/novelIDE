import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novel_ide/data/models/file_tree_node.dart';
import 'package:novel_ide/data/repositories/chapter_repository.dart';
import 'package:novel_ide/data/repositories/volume_repository.dart';
import 'package:novel_ide/data/datasources/database_helper.dart';
import 'package:novel_ide/data/datasources/local_file_datasource.dart';

/// 排序模式枚举
enum SortMode {
  byName('按名称'),
  byModified('按修改时间');

  final String label;
  const SortMode(this.label);
}

/// 展平后的树节点（供 ListView.builder 使用）
///
/// 包含节点本身和它在树中的深度（用于缩进计算）
class FlattenedNode {
  const FlattenedNode({
    required this.node,
    required this.depth,
    required this.isExpanded,
    required this.hasChildren,
  });

  final FileTreeNode node;
  final int depth;

  /// 该节点是否处于展开状态
  final bool isExpanded;

  /// 该节点是否有子节点
  final bool hasChildren;
}

/// Explorer 不可变状态类
///
/// 所有字段 final，通过 [copyWith] 创建新副本。
class ExplorerData {
  const ExplorerData({
    this.rootNode,
    this.expandedPaths = const {},
    this.searchQuery = '',
    this.sortMode = SortMode.byName,
    this.currentFilePath,
    this.isLoading = false,
    this.errorMessage,
  });

  /// 根节点
  final FileTreeNode? rootNode;

  /// 展开的路径集合（使用 path 作为 key）
  final Set<String> expandedPaths;

  /// 搜索过滤关键字
  final String searchQuery;

  /// 排序模式
  final SortMode sortMode;

  /// 当前正在编辑的文件路径
  final String? currentFilePath;

  /// 是否正在加载
  final bool isLoading;

  /// 错误消息
  final String? errorMessage;

  /// 不可变 copyWith
  ExplorerData copyWith({
    FileTreeNode? rootNode,
    Set<String>? expandedPaths,
    String? searchQuery,
    SortMode? sortMode,
    String? currentFilePath,
    bool? isLoading,
    String? errorMessage,
    bool clearCurrentFile = false,
    bool clearError = false,
  }) {
    return ExplorerData(
      rootNode: rootNode ?? this.rootNode,
      expandedPaths: expandedPaths ?? this.expandedPaths,
      searchQuery: searchQuery ?? this.searchQuery,
      sortMode: sortMode ?? this.sortMode,
      currentFilePath: clearCurrentFile
          ? null
          : (currentFilePath ?? this.currentFilePath),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Explorer 状态管理 Notifier
///
/// 负责：
/// - 加载卷/章数据并构建 FileTreeNode 树
/// - 管理展开/折叠状态
/// - 搜索过滤
/// - 排序
/// - 标记当前编辑文件
class ExplorerNotifier extends StateNotifier<ExplorerData> {
  ExplorerNotifier(this._novelId) : super(const ExplorerData()) {
    loadTree();
  }

  final String _novelId;
  final ChapterRepository _chapterRepo = ChapterRepository();
  final VolumeRepository _volumeRepo = VolumeRepository();
  final LocalFileDataSource _fs = LocalFileDataSource();

  /// 加载文件树
  Future<void> loadTree() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final volumes = await _volumeRepo.getVolumesByNovel(_novelId);
      final chapters = await _chapterRepo.getChaptersByNovel(_novelId);

      // 获取作品路径
      final db = DatabaseHelper();
      final dbInstance = await db.database;
      final novelMaps = await dbInstance.query(
        'novels',
        where: 'id = ?',
        whereArgs: [_novelId],
      );
      if (novelMaps.isEmpty) {
        state = state.copyWith(isLoading: false, errorMessage: '作品不存在');
        return;
      }
      final novelTitle = novelMaps.first['title'] as String;
      final projectPath = await _fs.getProjectDir(_novelId, novelTitle);

      // 构建树
      final volumeDataList = volumes
          .map(
            (v) =>
                VolumeData(id: v.id, title: v.title, orderIndex: v.orderIndex),
          )
          .toList();

      final chapterDataList = chapters
          .map(
            (c) => ChapterData(
              id: c.id,
              title: c.title,
              volumeId: c.volumeId,
              wordCount: c.wordCount,
              orderIndex: c.orderIndex,
              updatedAt: c.updatedAt,
            ),
          )
          .toList();

      final root = FileTreeNode.fromFileSystem(
        rootPath: projectPath,
        volumes: volumeDataList,
        chapters: chapterDataList,
      );

      // 保持已有展开状态，或默认展开根节点
      final expanded = Set<String>.from(state.expandedPaths);
      if (expanded.isEmpty) {
        expanded.add(root.path);
      }

      state = state.copyWith(
        rootNode: root,
        expandedPaths: expanded,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('ExplorerNotifier.loadTree error: $e');
      state = state.copyWith(isLoading: false, errorMessage: '加载失败: $e');
    }
  }

  /// 展开或折叠节点
  void toggleExpand(String nodePath) {
    final expanded = Set<String>.from(state.expandedPaths);
    if (expanded.contains(nodePath)) {
      expanded.remove(nodePath);
    } else {
      expanded.add(nodePath);
    }
    state = state.copyWith(expandedPaths: expanded);
  }

  /// 设置搜索关键字
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 设置排序模式
  void setSortMode(SortMode mode) {
    state = state.copyWith(sortMode: mode);
  }

  /// 标记当前编辑文件
  void setCurrentFile(String? filePath) {
    if (filePath == null) {
      state = state.copyWith(clearCurrentFile: true);
    } else {
      state = state.copyWith(currentFilePath: filePath);
    }
  }

  /// 刷新树
  Future<void> refresh() => loadTree();
}

/// 展平树 Provider（供 ListView.builder 使用）
///
/// 根据 [ExplorerData.expandedPaths]、[searchQuery]、[sortMode]
/// 将树结构展平为线性列表。
final flattenedTreeProvider = Provider.family<List<FlattenedNode>, String>((
  ref,
  novelId,
) {
  final explorer = ref.watch(explorerStateProvider(novelId));
  final root = explorer.rootNode;
  if (root == null) return [];

  final items = <FlattenedNode>[];
  _flattenNode(
    node: root,
    depth: 0,
    expandedPaths: explorer.expandedPaths,
    searchQuery: explorer.searchQuery,
    sortMode: explorer.sortMode,
    currentFilePath: explorer.currentFilePath,
    result: items,
  );

  // 过滤掉根节点本身（不显示作品根目录行）
  return items.where((item) => !item.node.isRoot).toList();
});

/// 递归展平节点
void _flattenNode({
  required FileTreeNode node,
  required int depth,
  required Set<String> expandedPaths,
  required String searchQuery,
  required SortMode sortMode,
  required String? currentFilePath,
  required List<FlattenedNode> result,
}) {
  // 搜索过滤：如果节点名称匹配，或子树中有匹配节点则保留
  if (searchQuery.isNotEmpty) {
    final matches = _nodeMatchesSearch(node, searchQuery);
    if (!matches) return;
  }

  // 标记当前编辑文件
  final isCurrentFile = currentFilePath != null && node.path == currentFilePath;
  final displayNode = node.isCurrentFile != isCurrentFile
      ? node.copyWith(isCurrentFile: isCurrentFile)
      : node;

  final isExpanded = expandedPaths.contains(node.path);
  final hasChildren = node.children.isNotEmpty;

  result.add(
    FlattenedNode(
      node: displayNode,
      depth: depth,
      isExpanded: isExpanded,
      hasChildren: hasChildren,
    ),
  );

  // 如果展开，递归添加子节点
  if (isExpanded && hasChildren) {
    // 排序子节点
    final sortedChildren = _sortChildren(node.children, sortMode);
    for (final child in sortedChildren) {
      _flattenNode(
        node: child,
        depth: depth + 1,
        expandedPaths: expandedPaths,
        searchQuery: searchQuery,
        sortMode: sortMode,
        currentFilePath: currentFilePath,
        result: result,
      );
    }
  }
}

/// 检查节点或子树是否匹配搜索
bool _nodeMatchesSearch(FileTreeNode node, String query) {
  final lowerQuery = query.toLowerCase();
  if (node.name.toLowerCase().contains(lowerQuery)) return true;
  for (final child in node.children) {
    if (_nodeMatchesSearch(child, lowerQuery)) return true;
  }
  return false;
}

/// 对子节点排序
List<FileTreeNode> _sortChildren(List<FileTreeNode> children, SortMode mode) {
  final sorted = List<FileTreeNode>.from(children);
  switch (mode) {
    case SortMode.byName:
      sorted.sort((a, b) {
        // 文件夹排在前面
        if (a.isFolder && !b.isFolder) return -1;
        if (!a.isFolder && b.isFolder) return 1;
        return a.name.compareTo(b.name);
      });
      break;
    case SortMode.byModified:
      sorted.sort((a, b) {
        if (a.isFolder && !b.isFolder) return -1;
        if (!a.isFolder && b.isFolder) return 1;
        final aTime = a.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime); // 最新的在前
      });
      break;
  }
  return sorted;
}

/// Explorer 状态 Provider（family by novelId）
final explorerStateProvider =
    StateNotifierProvider.family<ExplorerNotifier, ExplorerData, String>(
      (ref, novelId) => ExplorerNotifier(novelId),
    );

/// 写作统计 Provider
///
/// 统计当前作品的总字数、今日新增字数等。
final writingStatsProvider = Provider.family<WritingStats, String>((
  ref,
  novelId,
) {
  final explorer = ref.watch(explorerStateProvider(novelId));
  final root = explorer.rootNode;
  if (root == null) return const WritingStats();

  int totalWords = 0;
  int totalChapters = 0;
  final today = DateTime.now();

  _collectStats(root, today, (words, chapters) {
    totalWords += words;
    totalChapters += chapters;
  });

  return WritingStats(totalWords: totalWords, totalChapters: totalChapters);
});

void _collectStats(
  FileTreeNode node,
  DateTime today,
  void Function(int words, int chapters) accumulate,
) {
  if (node.isLeaf) {
    accumulate(node.wordCount ?? 0, 1);
  }
  for (final child in node.children) {
    _collectStats(child, today, accumulate);
  }
}

/// 写作统计数据
class WritingStats {
  const WritingStats({
    this.totalWords = 0,
    this.totalChapters = 0,
    this.todayWords = 0,
    this.todayGoalPercent = 0.0,
  });

  final int totalWords;
  final int totalChapters;
  final int todayWords;
  final double todayGoalPercent;

  WritingStats copyWith({
    int? totalWords,
    int? totalChapters,
    int? todayWords,
    double? todayGoalPercent,
  }) {
    return WritingStats(
      totalWords: totalWords ?? this.totalWords,
      totalChapters: totalChapters ?? this.totalChapters,
      todayWords: todayWords ?? this.todayWords,
      todayGoalPercent: todayGoalPercent ?? this.todayGoalPercent,
    );
  }
}
