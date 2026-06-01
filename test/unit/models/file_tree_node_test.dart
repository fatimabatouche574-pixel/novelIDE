import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:novel_ide/data/models/file_tree_node.dart';

void main() {
  // ----------------------------------------------------------------
  // Helper: create a minimal FileTreeNode for tests
  // ----------------------------------------------------------------
  FileTreeNode _makeNode({
    String id = 'id-1',
    String name = 'node',
    String? path,
    String? parentPath,
    List<FileTreeNode> children = const [],
    bool isFolder = false,
    bool isRoot = false,
    String? fileType,
    DateTime? lastModified,
    int? wordCount,
    bool isModified = false,
    bool isCurrentFile = false,
  }) {
    return FileTreeNode(
      id: id,
      name: name,
      path: path ?? p.join('/project', id),
      parentPath: parentPath,
      children: children,
      isFolder: isFolder,
      isRoot: isRoot,
      fileType: fileType,
      lastModified: lastModified,
      wordCount: wordCount,
      isModified: isModified,
      isCurrentFile: isCurrentFile,
    );
  }

  group('FileTreeNode', () {
    // ============================================================
    // copyWith
    // ============================================================
    group('copyWith', () {
      test('returns new instance with single field changed', () {
        // Arrange
        final original = _makeNode(name: 'original');

        // Act
        final copy = original.copyWith(name: 'updated');

        // Assert
        expect(copy.name, 'updated');
        expect(copy.id, original.id);
        expect(copy.path, original.path);
      });

      test('returns new instance with multiple fields changed', () {
        // Arrange
        final original = _makeNode(
          name: 'ch1',
          wordCount: 100,
          isModified: false,
        );

        // Act
        final copy = original.copyWith(
          name: 'ch1-edited',
          wordCount: 200,
          isModified: true,
        );

        // Assert
        expect(copy.name, 'ch1-edited');
        expect(copy.wordCount, 200);
        expect(copy.isModified, isTrue);
      });

      test('preserves all fields when no arguments provided', () {
        // Arrange
        final now = DateTime(2026, 1, 15);
        final original = _makeNode(
          name: 'chapter',
          wordCount: 500,
          lastModified: now,
          isModified: true,
          isCurrentFile: true,
        );

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.path, original.path);
        expect(copy.wordCount, original.wordCount);
        expect(copy.lastModified, original.lastModified);
        expect(copy.isModified, original.isModified);
        expect(copy.isCurrentFile, original.isCurrentFile);
      });
    });

    // ============================================================
    // Immutability
    // ============================================================
    group('immutability', () {
      test('original instance remains unchanged after copyWith', () {
        // Arrange
        final original = _makeNode(name: 'before', wordCount: 10);

        // Act
        original.copyWith(name: 'after', wordCount: 99);

        // Assert
        expect(original.name, 'before');
        expect(original.wordCount, 10);
      });

      test('original children list is not mutated when copy uses new list', () {
        // Arrange
        final child1 = _makeNode(id: 'c1', name: 'child1');
        final original = _makeNode(
          id: 'root',
          name: 'root',
          children: [child1],
          isFolder: true,
        );

        // Act
        final child2 = _makeNode(id: 'c2', name: 'child2');
        final copy = original.copyWith(children: [child1, child2]);

        // Assert
        expect(original.children.length, 1);
        expect(copy.children.length, 2);
      });
    });

    // ============================================================
    // isLeaf
    // ============================================================
    group('isLeaf', () {
      test('returns true when isFolder is false', () {
        // Arrange & Act
        final node = _makeNode(isFolder: false);

        // Assert
        expect(node.isLeaf, isTrue);
      });

      test('returns false when isFolder is true', () {
        // Arrange & Act
        final node = _makeNode(isFolder: true);

        // Assert
        expect(node.isLeaf, isFalse);
      });
    });

    // ============================================================
    // totalChildCount
    // ============================================================
    group('totalChildCount', () {
      test('returns 0 when node has no children', () {
        // Arrange & Act
        final node = _makeNode(children: []);

        // Assert
        expect(node.totalChildCount, 0);
      });

      test('counts direct children only', () {
        // Arrange
        final c1 = _makeNode(id: 'c1', name: 'c1');
        final c2 = _makeNode(id: 'c2', name: 'c2');
        final parent = _makeNode(
          id: 'p',
          name: 'parent',
          isFolder: true,
          children: [c1, c2],
        );

        // Act & Assert
        expect(parent.totalChildCount, 2);
      });

      test('counts nested children recursively', () {
        // Arrange
        final grandchild = _makeNode(id: 'gc', name: 'gc');
        final child = _makeNode(
          id: 'c',
          name: 'child',
          isFolder: true,
          children: [grandchild],
        );
        final parent = _makeNode(
          id: 'p',
          name: 'parent',
          isFolder: true,
          children: [child],
        );

        // Act & Assert
        expect(parent.totalChildCount, 2); // child + grandchild
      });
    });

    // ============================================================
    // totalWordCount
    // ============================================================
    group('totalWordCount', () {
      test('returns own wordCount when leaf node', () {
        // Arrange & Act
        final node = _makeNode(wordCount: 42, isFolder: false);

        // Assert
        expect(node.totalWordCount, 42);
      });

      test('returns 0 when leaf node has null wordCount', () {
        // Arrange & Act
        final node = _makeNode(wordCount: null, isFolder: false);

        // Assert
        expect(node.totalWordCount, 0);
      });

      test('sums word counts of all leaf descendants', () {
        // Arrange
        final ch1 = _makeNode(
          id: 'ch1',
          name: 'ch1',
          wordCount: 100,
          isFolder: false,
        );
        final ch2 = _makeNode(
          id: 'ch2',
          name: 'ch2',
          wordCount: 200,
          isFolder: false,
        );
        final volume = _makeNode(
          id: 'vol',
          name: 'vol',
          isFolder: true,
          children: [ch1, ch2],
        );

        // Act & Assert
        expect(volume.totalWordCount, 300);
      });

      test('sums nested word counts recursively', () {
        // Arrange
        final leaf = _makeNode(
          id: 'leaf',
          name: 'leaf',
          wordCount: 50,
          isFolder: false,
        );
        final child = _makeNode(
          id: 'child',
          name: 'child',
          isFolder: true,
          children: [leaf],
        );
        final root = _makeNode(
          id: 'root',
          name: 'root',
          isFolder: true,
          children: [child],
        );

        // Act & Assert
        expect(root.totalWordCount, 50);
      });
    });

    // ============================================================
    // Equality
    // ============================================================
    group('equality', () {
      test('two nodes with same id and path are equal', () {
        // Arrange
        final a = _makeNode(id: 'same', path: p.join('/a', 'same'));
        final b = _makeNode(id: 'same', path: p.join('/a', 'same'));

        // Act & Assert
        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('nodes with different id are not equal', () {
        // Arrange
        final a = _makeNode(id: 'a', path: p.join('/a', 'x'));
        final b = _makeNode(id: 'b', path: p.join('/a', 'x'));

        // Act & Assert
        expect(a, isNot(equals(b)));
      });

      test('nodes with different isModified are not equal', () {
        // Arrange
        final a = _makeNode(
          id: 'x',
          path: p.join('/p', 'x'),
          isModified: false,
        );
        final b = _makeNode(id: 'x', path: p.join('/p', 'x'), isModified: true);

        // Act & Assert
        expect(a, isNot(equals(b)));
      });

      test('identical instance is equal to itself', () {
        // Arrange
        final node = _makeNode();

        // Act & Assert
        expect(node, equals(node));
      });
    });

    // ============================================================
    // fromFileSystem
    // ============================================================
    group('fromFileSystem', () {
      late String rootPath;

      setUp(() {
        rootPath = p.join('/test', 'novel_project');
      });

      test('builds root node with isRoot=true and isFolder=true', () {
        // Arrange
        final volumes = <VolumeData>[];
        final chapters = <ChapterData>[];

        // Act
        final root = FileTreeNode.fromFileSystem(
          rootPath: rootPath,
          volumes: volumes,
          chapters: chapters,
        );

        // Assert
        expect(root.isRoot, isTrue);
        expect(root.isFolder, isTrue);
        expect(root.path, rootPath);
        expect(root.name, p.basename(rootPath));
        expect(root.children, isEmpty);
      });

      test('builds volume node containing its chapters', () {
        // Arrange
        final volumes = [
          const VolumeData(id: 'vol-1', title: 'Volume 1', orderIndex: 0),
        ];
        final chapters = [
          ChapterData(
            id: 'ch-1',
            title: 'Chapter 1',
            volumeId: 'vol-1',
            wordCount: 1000,
            orderIndex: 0,
            updatedAt: DateTime(2026, 1, 10),
          ),
          ChapterData(
            id: 'ch-2',
            title: 'Chapter 2',
            volumeId: 'vol-1',
            wordCount: 1500,
            orderIndex: 1,
            updatedAt: DateTime(2026, 1, 12),
          ),
        ];

        // Act
        final root = FileTreeNode.fromFileSystem(
          rootPath: rootPath,
          volumes: volumes,
          chapters: chapters,
        );

        // Assert
        expect(root.children.length, 1);
        final vol = root.children.first;
        expect(vol.isFolder, isTrue);
        expect(vol.name, 'Volume 1');
        expect(vol.children.length, 2);
        expect(vol.children[0].name, 'Chapter 1');
        expect(vol.children[0].isLeaf, isTrue);
        expect(vol.children[0].fileType, 'md');
        expect(vol.children[0].wordCount, 1000);
        expect(vol.children[1].name, 'Chapter 2');
        expect(vol.children[1].wordCount, 1500);
      });

      test('sorts chapters within a volume by orderIndex', () {
        // Arrange
        final volumes = [
          const VolumeData(id: 'vol-1', title: 'Vol', orderIndex: 0),
        ];
        final chapters = [
          ChapterData(
            id: 'ch-b',
            title: 'B',
            volumeId: 'vol-1',
            wordCount: 0,
            orderIndex: 2,
            updatedAt: DateTime(2026),
          ),
          ChapterData(
            id: 'ch-a',
            title: 'A',
            volumeId: 'vol-1',
            wordCount: 0,
            orderIndex: 1,
            updatedAt: DateTime(2026),
          ),
        ];

        // Act
        final root = FileTreeNode.fromFileSystem(
          rootPath: rootPath,
          volumes: volumes,
          chapters: chapters,
        );

        // Assert
        final vol = root.children.first;
        expect(vol.children[0].name, 'A');
        expect(vol.children[1].name, 'B');
      });

      test('places orphan chapters into default volume', () {
        // Arrange
        final volumes = <VolumeData>[];
        final chapters = [
          ChapterData(
            id: 'orphan-1',
            title: 'Orphan Chapter',
            volumeId: '',
            wordCount: 500,
            orderIndex: 0,
            updatedAt: DateTime(2026),
          ),
        ];

        // Act
        final root = FileTreeNode.fromFileSystem(
          rootPath: rootPath,
          volumes: volumes,
          chapters: chapters,
        );

        // Assert
        expect(root.children.length, 1);
        final defaultVol = root.children.first;
        expect(defaultVol.id, '__default_volume__');
        expect(defaultVol.name, '默认卷');
        expect(defaultVol.isFolder, isTrue);
        expect(defaultVol.children.length, 1);
        expect(defaultVol.children[0].name, 'Orphan Chapter');
      });

      test('assigns correct parent paths', () {
        // Arrange
        final volumes = [
          const VolumeData(id: 'vol-1', title: 'Vol', orderIndex: 0),
        ];
        final chapters = [
          ChapterData(
            id: 'ch-1',
            title: 'Ch',
            volumeId: 'vol-1',
            wordCount: 0,
            orderIndex: 0,
            updatedAt: DateTime(2026),
          ),
        ];

        // Act
        final root = FileTreeNode.fromFileSystem(
          rootPath: rootPath,
          volumes: volumes,
          chapters: chapters,
        );

        // Assert
        final vol = root.children.first;
        expect(vol.parentPath, rootPath);
        expect(vol.children.first.parentPath, p.join(rootPath, 'vol-1'));
      });

      test('chapter file paths are under chapters/ directory', () {
        // Arrange
        final volumes = [
          const VolumeData(id: 'vol-1', title: 'Vol', orderIndex: 0),
        ];
        final chapters = [
          ChapterData(
            id: 'abc-123',
            title: 'Test',
            volumeId: 'vol-1',
            wordCount: 0,
            orderIndex: 0,
            updatedAt: DateTime(2026),
          ),
        ];

        // Act
        final root = FileTreeNode.fromFileSystem(
          rootPath: rootPath,
          volumes: volumes,
          chapters: chapters,
        );

        // Assert
        final ch = root.children.first.children.first;
        expect(ch.path, p.join(rootPath, 'chapters', 'abc-123.md'));
      });

      test('handles multiple volumes', () {
        // Arrange
        final volumes = [
          const VolumeData(id: 'vol-1', title: 'Vol 1', orderIndex: 0),
          const VolumeData(id: 'vol-2', title: 'Vol 2', orderIndex: 1),
        ];
        final chapters = <ChapterData>[];

        // Act
        final root = FileTreeNode.fromFileSystem(
          rootPath: rootPath,
          volumes: volumes,
          chapters: chapters,
        );

        // Assert
        expect(root.children.length, 2);
        expect(root.children[0].name, 'Vol 1');
        expect(root.children[1].name, 'Vol 2');
      });

      test('volume with no chapters has empty children', () {
        // Arrange
        final volumes = [
          const VolumeData(id: 'vol-1', title: 'Empty Vol', orderIndex: 0),
        ];

        // Act
        final root = FileTreeNode.fromFileSystem(
          rootPath: rootPath,
          volumes: volumes,
          chapters: const [],
        );

        // Assert
        expect(root.children.length, 1);
        expect(root.children.first.children, isEmpty);
      });
    });
  });
}
