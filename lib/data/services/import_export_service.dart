import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:novel_ide/data/services/novel_import_service.dart';
import 'package:novel_ide/data/services/docx_export_service.dart';
import 'package:novel_ide/data/services/epub_export_service.dart';
import 'package:novel_ide/data/datasources/database_helper.dart';
import 'package:novel_ide/data/datasources/local_file_datasource.dart';
import 'package:novel_ide/data/models/novel_model.dart';
import 'package:novel_ide/data/models/chapter_model.dart';

/// 导出结果
class ExportResult {
  final bool success;
  final String? filePath;
  final String? error;

  const ExportResult({
    required this.success,
    this.filePath,
    this.error,
  });
}

/// 文件选择+预览结果
class PickPreviewResult {
  final String filePath;
  final ImportPreview preview;

  const PickPreviewResult({
    required this.filePath,
    required this.preview,
  });
}

/// 导入/导出格式枚举
enum ExportFormat {
  txt('TXT', 'txt'),
  md('Markdown', 'md'),
  json('JSON', 'json'),
  docx('DOCX', 'docx'),
  epub('EPUB', 'epub');

  final String label;
  final String extension;
  const ExportFormat(this.label, this.extension);
}

/// 统一导入/导出服务
/// 整合现有 NovelImportService / DocxExportService / EpubExportService
class ImportExportService {
  final _importService = NovelImportService();
  final _docxService = DocxExportService();
  final _epubService = EpubExportService();

  // ════════════════════════════════════════════════════════════════
  //  导入
  // ════════════════════════════════════════════════════════════════

  /// 用 file_picker 选择文件并预览
  Future<PickPreviewResult?> pickAndPreview() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'docx', 'epub', 'json'],
    );
    if (result == null || result.files.isEmpty) return null;

    final filePath = result.files.single.path;
    if (filePath == null) return null;

    final preview = await _importService.previewImport(filePath);
    return PickPreviewResult(filePath: filePath, preview: preview);
  }

  /// 用 file_picker 选择文件并导入
  Future<ImportResult> pickAndImport({
    String? novelId,
    String? novelTitle,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'docx', 'epub', 'json'],
    );
    if (result == null || result.files.isEmpty) {
      return ImportResult(success: false, error: '未选择文件');
    }

    final filePath = result.files.single.path;
    if (filePath == null) {
      return ImportResult(success: false, error: '无法读取文件路径');
    }

    return _importService.importFromFile(
      novelId: novelId,
      novelTitle: novelTitle,
      filePath: filePath,
    );
  }

  /// 从指定路径导入（用于预览后的确认导入）
  Future<ImportResult> importFromPath({
    required String filePath,
    String? novelId,
    String? novelTitle,
  }) async {
    return _importService.importFromFile(
      novelId: novelId,
      novelTitle: novelTitle,
      filePath: filePath,
    );
  }

  /// 从文件夹批量导入（扫描 .md/.txt 文件）
  Future<ImportResult> importFromFolder({
    String? novelId,
    String? novelTitle,
  }) async {
    final folderPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择导入文件夹',
    );
    if (folderPath == null) {
      return ImportResult(success: false, error: '未选择文件夹');
    }

    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      return ImportResult(success: false, error: '文件夹不存在');
    }

    final files = <File>[];
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (ext == '.txt' || ext == '.md') {
          files.add(entity);
        }
      }
    }

    if (files.isEmpty) {
      return ImportResult(
        success: false,
        error: '文件夹中没有找到 .txt 或 .md 文件',
      );
    }

    files.sort((a, b) => a.path.compareTo(b.path));

    int totalImported = 0;
    int totalWords = 0;
    String? firstNovelId;

    for (final file in files) {
      final result = await _importService.importFromFile(
        novelId: novelId,
        novelTitle: novelTitle,
        filePath: file.path,
      );
      if (result.success) {
        totalImported += result.chapterCount;
        totalWords += result.totalWords;
        firstNovelId ??= result.novelId;
      }
    }

    if (totalImported == 0) {
      return ImportResult(success: false, error: '未能导入任何章节');
    }

    return ImportResult(
      success: true,
      chapterCount: totalImported,
      totalWords: totalWords,
      novelId: firstNovelId,
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  导出
  // ════════════════════════════════════════════════════════════════

  /// 导出小说到指定格式
  Future<ExportResult> exportNovel({
    required Novel novel,
    required ExportFormat format,
    List<Chapter>? selectedChapters,
  }) async {
    try {
      switch (format) {
        case ExportFormat.txt:
          return await _exportTxt(novel, selectedChapters);
        case ExportFormat.md:
          return await _exportMd(novel, selectedChapters);
        case ExportFormat.json:
          return await _exportJson(novel, selectedChapters);
        case ExportFormat.docx:
          return await _exportDocx(novel, selectedChapters);
        case ExportFormat.epub:
          return await _exportEpub(novel, selectedChapters);
      }
    } catch (e) {
      return ExportResult(success: false, error: '导出失败: $e');
    }
  }

  // ── TXT 导出 ──

  Future<ExportResult> _exportTxt(
    Novel novel,
    List<Chapter>? chapters,
  ) async {
    final content = await _buildTextContent(novel, chapters);
    final safeTitle = _safeFileName(novel.title);
    final fileName = '$safeTitle.txt';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '保存 TXT 文件',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (savePath == null) {
      return const ExportResult(success: false, error: '未选择保存位置');
    }

    await File(savePath).writeAsString(content, encoding: utf8);
    return ExportResult(success: true, filePath: savePath);
  }

  // ── Markdown 导出 ──

  Future<ExportResult> _exportMd(
    Novel novel,
    List<Chapter>? chapters,
  ) async {
    final content = await _buildMarkdownContent(novel, chapters);
    final safeTitle = _safeFileName(novel.title);
    final fileName = '$safeTitle.md';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '保存 Markdown 文件',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['md'],
    );
    if (savePath == null) {
      return const ExportResult(success: false, error: '未选择保存位置');
    }

    await File(savePath).writeAsString(content, encoding: utf8);
    return ExportResult(success: true, filePath: savePath);
  }

  // ── JSON 导出 ──

  Future<ExportResult> _exportJson(
    Novel novel,
    List<Chapter>? chapters,
  ) async {
    final db = await DatabaseHelper().database;
    final fs = LocalFileDataSource();
    final projectPath = await fs.getProjectDir(novel.id, novel.title);

    final actualChapters = chapters ?? await _getAllChapters(novel.id);

    final volumeRows = await db.query(
      'volumes',
      where: 'novel_id = ?',
      whereArgs: [novel.id],
      orderBy: 'order_index ASC',
    );
    final volumes = volumeRows.map((r) => {
      'id': r['id'],
      'title': r['title'],
      'order_index': r['order_index'],
    }).toList();

    final chaptersJson = <Map<String, dynamic>>[];
    for (final ch in actualChapters) {
      final contentFile = File(
        p.join(projectPath, 'chapters', '${ch.id}.md'),
      );
      final content = await contentFile.exists()
          ? await contentFile.readAsString()
          : '';

      chaptersJson.add({
        'title': ch.title,
        'volume_id': ch.volumeId,
        'order_index': ch.orderIndex,
        'word_count': ch.wordCount,
        'content': content,
      });
    }

    final exportData = {
      'format_version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'novel': {
        'title': novel.title,
        'author': novel.author ?? '',
        'description': novel.description ?? '',
        'category': novel.category ?? '',
        'status': novel.status,
      },
      'volumes': volumes,
      'chapters': chaptersJson,
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
    final safeTitle = _safeFileName(novel.title);
    final fileName = '$safeTitle.json';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '保存 JSON 文件',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (savePath == null) {
      return const ExportResult(success: false, error: '未选择保存位置');
    }

    await File(savePath).writeAsString(jsonStr, encoding: utf8);
    return ExportResult(success: true, filePath: savePath);
  }

  // ── DOCX 导出（委托现有服务）──

  Future<ExportResult> _exportDocx(
    Novel novel,
    List<Chapter>? chapters,
  ) async {
    final chapterIds = chapters?.map((c) => c.id).toSet();

    final docxPath = await _docxService.exportNovel(
      novelId: novel.id,
      novelTitle: novel.title,
      selectedChapterIds: chapterIds,
    );

    final docxFile = File(docxPath);
    final bytes = await docxFile.readAsBytes();
    final safeTitle = _safeFileName(novel.title);
    final fileName = '$safeTitle.docx';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '保存 DOCX 文件',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['docx'],
      bytes: bytes,
    );

    try {
      if (await docxFile.exists()) await docxFile.delete();
    } catch (_) {}

    if (savePath == null) {
      return const ExportResult(success: false, error: '未选择保存位置');
    }
    return ExportResult(success: true, filePath: savePath);
  }

  // ── EPUB 导出（委托现有服务）──

  Future<ExportResult> _exportEpub(
    Novel novel,
    List<Chapter>? chapters,
  ) async {
    final chapterIds = chapters?.map((c) => c.id).toSet();

    final epubPath = await _epubService.exportNovel(
      novelId: novel.id,
      novelTitle: novel.title,
      selectedChapterIds: chapterIds,
    );

    final epubFile = File(epubPath);
    final bytes = await epubFile.readAsBytes();
    final safeTitle = _safeFileName(novel.title);
    final fileName = '$safeTitle.epub';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: '保存 EPUB 文件',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['epub'],
      bytes: bytes,
    );

    try {
      if (await epubFile.exists()) await epubFile.delete();
    } catch (_) {}

    if (savePath == null) {
      return const ExportResult(success: false, error: '未选择保存位置');
    }
    return ExportResult(success: true, filePath: savePath);
  }

  // ════════════════════════════════════════════════════════════════
  //  内容构建
  // ════════════════════════════════════════════════════════════════

  Future<String> _buildTextContent(
    Novel novel,
    List<Chapter>? chapters,
  ) async {
    final fs = LocalFileDataSource();
    final projectPath = await fs.getProjectDir(novel.id, novel.title);
    final actualChapters = chapters ?? await _getAllChapters(novel.id);

    final buffer = StringBuffer();
    buffer.writeln(novel.title);
    buffer.writeln('=' * 40);
    if (novel.author?.isNotEmpty == true) {
      buffer.writeln('作者: ${novel.author}');
    }
    buffer.writeln();

    for (final ch in actualChapters) {
      buffer.writeln('【${ch.title}】');
      buffer.writeln('-' * 30);

      final contentFile = File(
        p.join(projectPath, 'chapters', '${ch.id}.md'),
      );
      if (await contentFile.exists()) {
        final content = await contentFile.readAsString();
        buffer.writeln(content.trim());
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  Future<String> _buildMarkdownContent(
    Novel novel,
    List<Chapter>? chapters,
  ) async {
    final fs = LocalFileDataSource();
    final projectPath = await fs.getProjectDir(novel.id, novel.title);
    final actualChapters = chapters ?? await _getAllChapters(novel.id);

    final buffer = StringBuffer();
    buffer.writeln('# ${novel.title}');
    buffer.writeln();
    if (novel.author?.isNotEmpty == true) {
      buffer.writeln('**作者:** ${novel.author}');
      buffer.writeln();
    }
    if (novel.description?.isNotEmpty == true) {
      buffer.writeln('> ${novel.description}');
      buffer.writeln();
    }

    for (final ch in actualChapters) {
      buffer.writeln('## ${ch.title}');
      buffer.writeln();

      final contentFile = File(
        p.join(projectPath, 'chapters', '${ch.id}.md'),
      );
      if (await contentFile.exists()) {
        final content = await contentFile.readAsString();
        buffer.writeln(content.trim());
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  // ════════════════════════════════════════════════════════════════
  //  辅助方法
  // ════════════════════════════════════════════════════════════════

  /// 获取小说的全部章节（含内容）
  Future<List<Chapter>> _getAllChapters(String novelId) async {
    final db = await DatabaseHelper().database;
    final fs = LocalFileDataSource();

    final rows = await db.query(
      'chapters',
      where: 'novel_id = ?',
      whereArgs: [novelId],
      orderBy: 'order_index ASC',
    );

    final chapters = <Chapter>[];
    for (final r in rows) {
      final novelMaps = await db.query(
        'novels',
        where: 'id = ?',
        whereArgs: [r['novel_id']],
      );
      final novelTitle = novelMaps.isNotEmpty
          ? (novelMaps.first['title'] as String)
          : '';
      final projectPath = await fs.getProjectDir(novelId, novelTitle);
      final content = await fs.readChapterContent(
        projectPath,
        r['id'] as String,
      );

      chapters.add(Chapter(
        id: r['id'] as String,
        novelId: r['novel_id'] as String,
        volumeId: r['volume_id'] as String,
        title: r['title'] as String,
        content: content,
        wordCount: r['word_count'] as int? ?? 0,
        status: r['status'] as String? ?? 'draft',
        orderIndex: r['order_index'] as int? ?? 0,
        summary: r['summary'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          r['created_at'] as int,
        ),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          r['updated_at'] as int,
        ),
      ));
    }

    return chapters;
  }

  /// 文件名安全化
  String _safeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
