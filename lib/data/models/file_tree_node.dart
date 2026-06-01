import 'package:path/path.dart' as p;

/// 不可变的文件树节点数据模型
///
/// 用于写作侧边栏（ExplorerPanel）展示卷/章/文件夹的层级结构。
/// 所有字段 final，通过 [copyWith] 创建新副本。
class FileTreeNode {
  const FileTreeNode({
    required this.id,
    required this.name,
    required this.path,
    this.parentPath,
    this.children = const [],
    this.isFolder = false,
    this.isRoot = false,
    this.fileType,
    this.lastModified,
    this.content,
    this.wordCount,
    this.isModified = false,
    this.isCurrentFile = false,
  });

  /// 唯一标识（UUID 或卷ID）
  final String id;

  /// 显示名称（章节标题 / 卷名 / 文件夹名）
  final String name;

  /// 文件系统绝对路径（用于文件操作）
  final String path;

  /// 父节点路径
  final String? parentPath;

  /// 子节点列表
  final List<FileTreeNode> children;

  /// 是否为文件夹（卷 = 文件夹，章节 = 叶子）
  final bool isFolder;

  /// 是否为根节点（作品根目录）
  final bool isRoot;

  /// 文件类型扩展名（如 'md'、'txt'），null 表示文件夹
  final String? fileType;

  /// 最后修改时间
  final DateTime? lastModified;

  /// 文件内容（仅叶子节点按需加载）
  final String? content;

  /// 字数统计
  final int? wordCount;

  /// 是否有未保存的修改
  final bool isModified;

  /// 是否为当前正在编辑的文件
  final bool isCurrentFile;

  /// 叶子节点判断
  bool get isLeaf => !isFolder;

  /// 递归统计子节点数量
  int get totalChildCount {
    int count = children.length;
    for (final child in children) {
      count += child.totalChildCount;
    }
    return count;
  }

  /// 递归统计所有叶子节点字数
  int get totalWordCount {
    if (isLeaf) return wordCount ?? 0;
    int total = 0;
    for (final child in children) {
      total += child.totalWordCount;
    }
    return total;
  }

  /// 不可变 copyWith
  FileTreeNode copyWith({
    String? id,
    String? name,
    String? path,
    String? parentPath,
    List<FileTreeNode>? children,
    bool? isFolder,
    bool? isRoot,
    String? fileType,
    DateTime? lastModified,
    String? content,
    int? wordCount,
    bool? isModified,
    bool? isCurrentFile,
  }) {
    return FileTreeNode(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      parentPath: parentPath ?? this.parentPath,
      children: children ?? this.children,
      isFolder: isFolder ?? this.isFolder,
      isRoot: isRoot ?? this.isRoot,
      fileType: fileType ?? this.fileType,
      lastModified: lastModified ?? this.lastModified,
      content: content ?? this.content,
      wordCount: wordCount ?? this.wordCount,
      isModified: isModified ?? this.isModified,
      isCurrentFile: isCurrentFile ?? this.isCurrentFile,
    );
  }

  /// 从文件系统构建树
  ///
  /// [rootPath] 作品根目录路径
  /// [volumes] 从数据库获取的卷列表
  /// [chapters] 从数据库获取的章节列表
  static FileTreeNode fromFileSystem({
    required String rootPath,
    required List<VolumeData> volumes,
    required List<ChapterData> chapters,
  }) {
    final chaptersDir = p.join(rootPath, 'chapters');

    // 构建卷 → 章节的映射
    final volumeMap = <String, List<ChapterData>>{};
    final orphanChapters = <ChapterData>[];

    for (final chapter in chapters) {
      if (chapter.volumeId.isNotEmpty) {
        volumeMap.putIfAbsent(chapter.volumeId, () => []);
        volumeMap[chapter.volumeId]!.add(chapter);
      } else {
        orphanChapters.add(chapter);
      }
    }

    // 构建子节点
    final children = <FileTreeNode>[];

    // 卷节点
    for (final volume in volumes) {
      final volumeChapters = volumeMap[volume.id] ?? [];
      volumeChapters.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

      final chapterNodes = volumeChapters.map((ch) {
        return FileTreeNode(
          id: ch.id,
          name: ch.title,
          path: p.join(chaptersDir, '${ch.id}.md'),
          parentPath: p.join(rootPath, volume.id),
          isFolder: false,
          fileType: 'md',
          wordCount: ch.wordCount,
          lastModified: ch.updatedAt,
          isModified: false,
          isCurrentFile: false,
        );
      }).toList();

      children.add(
        FileTreeNode(
          id: volume.id,
          name: volume.title,
          path: p.join(rootPath, volume.id),
          parentPath: rootPath,
          isFolder: true,
          children: chapterNodes,
        ),
      );
    }

    // 未分卷的章节放入默认卷
    if (orphanChapters.isNotEmpty) {
      orphanChapters.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      final defaultChildren = orphanChapters.map((ch) {
        return FileTreeNode(
          id: ch.id,
          name: ch.title,
          path: p.join(chaptersDir, '${ch.id}.md'),
          parentPath: p.join(rootPath, '__default_volume__'),
          isFolder: false,
          fileType: 'md',
          wordCount: ch.wordCount,
          lastModified: ch.updatedAt,
        );
      }).toList();

      // 只有存在默认卷时才添加默认卷节点
      if (orphanChapters.isNotEmpty) {
        children.add(
          FileTreeNode(
            id: '__default_volume__',
            name: '默认卷',
            path: p.join(rootPath, '__default_volume__'),
            parentPath: rootPath,
            isFolder: true,
            children: defaultChildren,
          ),
        );
      }
    }

    // 按卷 orderIndex 排序
    // （volumes 已从数据库按 orderIndex 排序，这里保持原序）

    return FileTreeNode(
      id: rootPath,
      name: p.basename(rootPath),
      path: rootPath,
      isFolder: true,
      isRoot: true,
      children: children,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileTreeNode &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          path == other.path &&
          isModified == other.isModified &&
          isCurrentFile == other.isCurrentFile &&
          wordCount == other.wordCount;

  @override
  int get hashCode =>
      Object.hash(id, path, isModified, isCurrentFile, wordCount);
}

/// 卷信息数据类
class VolumeData {
  const VolumeData({
    required this.id,
    required this.title,
    required this.orderIndex,
  });
  final String id;
  final String title;
  final int orderIndex;
}

/// 章节信息数据类
class ChapterData {
  const ChapterData({
    required this.id,
    required this.title,
    required this.volumeId,
    required this.wordCount,
    required this.orderIndex,
    required this.updatedAt,
  });
  final String id;
  final String title;
  final String volumeId;
  final int wordCount;
  final int orderIndex;
  final DateTime updatedAt;
}
