import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:novel_ide/data/models/ai_config_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'novel_ide.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE novels (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        author TEXT,
        description TEXT,
        category TEXT,
        total_word_count INTEGER DEFAULT 0,
        chapter_count INTEGER DEFAULT 0,
        cover_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        status TEXT DEFAULT 'draft'
      )
    ''');

    await db.execute('''
      CREATE TABLE volumes (
        id TEXT PRIMARY KEY,
        novel_id TEXT NOT NULL,
        title TEXT NOT NULL,
        order_index INTEGER DEFAULT 0,
        summary TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (novel_id) REFERENCES novels(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE chapters (
        id TEXT PRIMARY KEY,
        novel_id TEXT NOT NULL,
        volume_id TEXT NOT NULL,
        title TEXT NOT NULL,
        word_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'draft',
        order_index INTEGER DEFAULT 0,
        summary TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (novel_id) REFERENCES novels(id) ON DELETE CASCADE,
        FOREIGN KEY (volume_id) REFERENCES volumes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE chapter_snapshots (
        id TEXT PRIMARY KEY,
        chapter_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (chapter_id) REFERENCES chapters(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_configs (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        api_url TEXT NOT NULL,
        model_name TEXT NOT NULL,
        temperature REAL DEFAULT 1.0,
        max_tokens INTEGER DEFAULT 4096,
        is_local INTEGER DEFAULT 0,
        protocol TEXT DEFAULT 'openaiCompatible',
        model_type TEXT DEFAULT 'text',
        top_p REAL DEFAULT 1.0,
        top_k INTEGER DEFAULT 0,
        presence_penalty REAL DEFAULT 0.0,
        frequency_penalty REAL DEFAULT 0.0,
        top_p_enabled INTEGER DEFAULT 0,
        top_k_enabled INTEGER DEFAULT 0,
        presence_penalty_enabled INTEGER DEFAULT 0,
        frequency_penalty_enabled INTEGER DEFAULT 0,
        context_length REAL DEFAULT 64.0,
        summary_token_threshold REAL DEFAULT 0.7,
        enable_summary INTEGER DEFAULT 1,
        enable_tool_call INTEGER DEFAULT 0,
        enable_claude_1h_prompt_cache INTEGER DEFAULT 0,
        enable_google_search INTEGER DEFAULT 0,
        request_limit_per_minute INTEGER DEFAULT 0,
        max_concurrent_requests INTEGER DEFAULT 0,
        custom_headers TEXT DEFAULT '{}'
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_chapters_novel ON chapters(novel_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_chapters_volume ON chapters(volume_id);
    ''');
    await db.execute('''
      CREATE INDEX idx_snapshots_chapter ON chapter_snapshots(chapter_id);
    ''');

    // V2: daily writing stats
    await _createDailyWordsTable(db);
    // V3: billing records
    await _createBillingTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createDailyWordsTable(db);
    }
    if (oldVersion < 3) {
      await _createBillingTable(db);
    }
    if (oldVersion < 4) {
      // 添加 protocol 字段到 ai_configs 表
      await db.execute(
        'ALTER TABLE ai_configs ADD COLUMN protocol TEXT DEFAULT "openaiCompatible"',
      );
    }
    if (oldVersion < 5) {
      // 添加 model_type 字段到 ai_configs 表
      await db.execute(
        'ALTER TABLE ai_configs ADD COLUMN model_type TEXT DEFAULT "text"',
      );
    }
    if (oldVersion < 6) {
      // V6: 添加高级模型配置字段
      await db.execute('ALTER TABLE ai_configs ADD COLUMN top_p REAL DEFAULT 1.0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN top_k INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN presence_penalty REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN frequency_penalty REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN top_p_enabled INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN top_k_enabled INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN presence_penalty_enabled INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN frequency_penalty_enabled INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN context_length REAL DEFAULT 64.0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN summary_token_threshold REAL DEFAULT 0.7');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN enable_summary INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN enable_tool_call INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN enable_claude_1h_prompt_cache INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN enable_google_search INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN request_limit_per_minute INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN max_concurrent_requests INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE ai_configs ADD COLUMN custom_headers TEXT DEFAULT "{}"');
    }
    if (oldVersion < 7) {
      // V7: 记忆系统表
      await _createMemoryTables(db);
    }
  }

  Future<void> _createDailyWordsTable(Database db) async {
    await db.execute('''
      CREATE TABLE daily_words (
        date TEXT NOT NULL,
        novel_id TEXT NOT NULL,
        word_count INTEGER DEFAULT 0,
        PRIMARY KEY (date, novel_id)
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_daily_words_date ON daily_words(date);
    ''');
  }

  Future<void> _createBillingTable(Database db) async {
    await db.execute('''
      CREATE TABLE billing_records (
        id TEXT PRIMARY KEY,
        config_id TEXT,
        model TEXT,
        task_type TEXT,
        token_count INTEGER DEFAULT 0,
        estimated_cost REAL DEFAULT 0.0,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_billing_created ON billing_records(created_at);
    ''');
  }

  /// V7: 创建记忆系统表
  Future<void> _createMemoryTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS memories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        novel_id TEXT,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        content_type TEXT NOT NULL DEFAULT 'text/plain',
        source TEXT NOT NULL DEFAULT 'unknown',
        credibility REAL NOT NULL DEFAULT 0.5,
        importance REAL NOT NULL DEFAULT 0.5,
        document_path TEXT,
        is_document_node INTEGER NOT NULL DEFAULT 0,
        chunk_index_file_path TEXT,
        folder_path TEXT,
        embedding BLOB,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_accessed_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        FOREIGN KEY (parent_id) REFERENCES memory_tags(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_tag_relations (
        memory_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (memory_id, tag_id),
        FOREIGN KEY (memory_id) REFERENCES memories(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES memory_tags(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source_id INTEGER NOT NULL,
        target_id INTEGER NOT NULL,
        type TEXT NOT NULL DEFAULT 'related',
        weight REAL NOT NULL DEFAULT 1.0,
        description TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (source_id) REFERENCES memories(id) ON DELETE CASCADE,
        FOREIGN KEY (target_id) REFERENCES memories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS memory_properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        memory_id INTEGER NOT NULL,
        key TEXT NOT NULL,
        value TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (memory_id) REFERENCES memories(id) ON DELETE CASCADE
      )
    ''');

    // 索引
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memories_novel_id ON memories(novel_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memories_folder_path ON memories(folder_path)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memories_uuid ON memories(uuid)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memory_links_source ON memory_links(source_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_memory_links_target ON memory_links(target_id)');
  }

  /// Close the database connection.
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  // --- AI Config CRUD ---

  Future<List<Map<String, dynamic>>> getAllAiConfigs() async {
    final db = await database;
    return await db.query('ai_configs');
  }

  Future<void> insertAiConfig(Map<String, dynamic> config) async {
    final db = await database;
    await db.insert(
      'ai_configs',
      config,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Map<String, dynamic> toDbMap(AiConfig config) {
    return {
      'id': config.id,
      'name': config.name,
      'api_url': config.apiUrl,
      'model_name': config.modelName,
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
      'is_local': config.isLocal ? 1 : 0,
      'protocol': config.protocol.name,
      'model_type': config.modelType.name,
      'top_p': config.topP,
      'top_k': config.topK,
      'presence_penalty': config.presencePenalty,
      'frequency_penalty': config.frequencyPenalty,
      'top_p_enabled': config.topPEnabled ? 1 : 0,
      'top_k_enabled': config.topKEnabled ? 1 : 0,
      'presence_penalty_enabled': config.presencePenaltyEnabled ? 1 : 0,
      'frequency_penalty_enabled': config.frequencyPenaltyEnabled ? 1 : 0,
      'context_length': config.contextLength,
      'summary_token_threshold': config.summaryTokenThreshold,
      'enable_summary': config.enableSummary ? 1 : 0,
      'enable_tool_call': config.enableToolCall ? 1 : 0,
      'enable_claude_1h_prompt_cache': config.enableClaude1hPromptCache ? 1 : 0,
      'enable_google_search': config.enableGoogleSearch ? 1 : 0,
      'request_limit_per_minute': config.requestLimitPerMinute,
      'max_concurrent_requests': config.maxConcurrentRequests,
      'custom_headers': config.customHeaders,
    };
  }

  /// 从数据库 map 转换为 AiConfig 对象
  AiConfig fromDbMap(Map<String, dynamic> map, String? apiKey) {
    // 转换 protocol 字符串为枚举
    ApiProtocol protocol = ApiProtocol.openaiCompatible;
    try {
      if (map['protocol'] != null) {
        protocol = ApiProtocol.values.firstWhere(
          (e) => e.name == map['protocol'],
          orElse: () => ApiProtocol.openaiCompatible,
        );
      }
    } catch (_) {
      // 无效值时使用默认
    }
    // 转换 modelType 字符串为枚举
    ModelType modelType = ModelType.text;
    try {
      if (map['model_type'] != null) {
        modelType = ModelType.values.firstWhere(
          (e) => e.name == map['model_type'],
          orElse: () => ModelType.text,
        );
      }
    } catch (_) {}
    return AiConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      apiUrl: map['api_url'] as String,
      modelName: map['model_name'] as String,
      apiKey: apiKey,
      temperature: (map['temperature'] as num).toDouble(),
      maxTokens: map['max_tokens'] as int,
      isLocal: (map['is_local'] as int) == 1,
      protocol: protocol,
      modelType: modelType,
      topP: (map['top_p'] as num?)?.toDouble() ?? 1.0,
      topK: (map['top_k'] as int?) ?? 0,
      presencePenalty: (map['presence_penalty'] as num?)?.toDouble() ?? 0.0,
      frequencyPenalty: (map['frequency_penalty'] as num?)?.toDouble() ?? 0.0,
      topPEnabled: (map['top_p_enabled'] as int?) == 1,
      topKEnabled: (map['top_k_enabled'] as int?) == 1,
      presencePenaltyEnabled: (map['presence_penalty_enabled'] as int?) == 1,
      frequencyPenaltyEnabled: (map['frequency_penalty_enabled'] as int?) == 1,
      contextLength: (map['context_length'] as num?)?.toDouble() ?? 64.0,
      summaryTokenThreshold: (map['summary_token_threshold'] as num?)?.toDouble() ?? 0.7,
      enableSummary: (map['enable_summary'] as int?) != 0,
      enableToolCall: (map['enable_tool_call'] as int?) == 1,
      enableClaude1hPromptCache: (map['enable_claude_1h_prompt_cache'] as int?) == 1,
      enableGoogleSearch: (map['enable_google_search'] as int?) == 1,
      requestLimitPerMinute: (map['request_limit_per_minute'] as int?) ?? 0,
      maxConcurrentRequests: (map['max_concurrent_requests'] as int?) ?? 0,
      customHeaders: (map['custom_headers'] as String?) ?? '{}',
    );
  }

  Future<void> deleteAiConfig(String id) async {
    final db = await database;
    await db.delete('ai_configs', where: 'id = ?', whereArgs: [id]);
  }

  // --- Daily Words CRUD ---

  /// Record word count for a day. Accumulates if already exists.
  Future<void> recordDailyWords(
    String date,
    String novelId,
    int wordCount,
  ) async {
    final db = await database;
    await db.rawInsert(
      '''
      INSERT INTO daily_words (date, novel_id, word_count)
      VALUES (?, ?, ?)
      ON CONFLICT(date, novel_id) DO UPDATE SET word_count = word_count + ?
    ''',
      [date, novelId, wordCount, wordCount],
    );
  }

  /// Get daily word counts for a date range.
  Future<List<Map<String, dynamic>>> getDailyWords({
    String? startDate,
    String? endDate,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> args = [];
    if (startDate != null) {
      where = 'date >= ?';
      args.add(startDate);
    }
    if (endDate != null) {
      where += (where.isEmpty ? '' : ' AND ') + 'date <= ?';
      args.add(endDate);
    }
    return await db.query(
      'daily_words',
      where: where.isEmpty ? null : where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date ASC',
    );
  }

  /// Get total word count across all days.
  Future<int> getTotalWords() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(word_count), 0) as total FROM daily_words',
    );
    return (result.first['total'] as int?) ?? 0;
  }

  /// Get today's word count.
  Future<int> getTodayWords(String date) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(word_count), 0) as total FROM daily_words WHERE date = ?',
      [date],
    );
    return (result.first['total'] as int?) ?? 0;
  }
}
