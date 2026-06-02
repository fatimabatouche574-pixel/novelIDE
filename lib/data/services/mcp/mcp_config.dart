/// MCP 配置持久化层
/// 使用 Hive 存储服务器配置

import 'dart:developer' as developer;
import 'package:hive/hive.dart';

/// MCP 服务器类型
enum McpServerType {
  /// 本地进程通信
  local,

  /// HTTP REST API
  http,

  /// Server-Sent Events
  sse,
}

/// MCP 服务器配置模型
class McpServerConfig {
  /// 配置唯一标识
  final String id;

  /// 显示名称
  final String name;

  /// 服务器类型
  final McpServerType type;

  /// 服务器URL（http/sse类型必需）
  final String? url;

  /// 是否启用
  final bool enabled;

  /// 扩展元数据
  final Map<String, dynamic> metadata;

  /// 创建服务器配置
  const McpServerConfig({
    required this.id,
    required this.name,
    required this.type,
    this.url,
    this.enabled = true,
    this.metadata = const {},
  });

  /// 从 Map 创建配置
  factory McpServerConfig.fromMap(Map<String, dynamic> map) {
    return McpServerConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      type: McpServerType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => McpServerType.local,
      ),
      url: map['url'] as String?,
      enabled: map['enabled'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'url': url,
      'enabled': enabled,
      'metadata': metadata,
    };
  }

  /// 创建副本并修改部分字段
  McpServerConfig copyWith({
    String? id,
    String? name,
    McpServerType? type,
    String? url,
    bool? enabled,
    Map<String, dynamic>? metadata,
  }) {
    return McpServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      url: url ?? this.url,
      enabled: enabled ?? this.enabled,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'McpServerConfig($id: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is McpServerConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// MCP 配置管理器
///
/// 使用 Hive 进行本地持久化存储
class McpConfigManager {
  static const _boxName = 'mcp_servers';

  Box<Map>? _box;

  /// 初始化配置管理器
  ///
  /// 必须在使用前调用
  Future<void> init() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  /// 确保已初始化
  void _ensureInitialized() {
    if (_box == null) {
      throw StateError('McpConfigManager not initialized. Call init() first.');
    }
  }

  /// 加载所有服务器配置
  Future<List<McpServerConfig>> loadAll() async {
    _ensureInitialized();

    final configs = <McpServerConfig>[];
    for (final key in _box!.keys) {
      final map = _box!.get(key);
      if (map != null) {
        try {
          configs.add(McpServerConfig.fromMap(Map<String, dynamic>.from(map)));
        } catch (e) {
          developer.log('加载配置失败 key=$key: $e',
              name: 'McpConfigManager');
        }
      }
    }
    return configs;
  }

  /// 保存单个配置
  ///
  /// 如果已存在同ID配置，会覆盖
  Future<void> save(McpServerConfig config) async {
    _ensureInitialized();
    await _box!.put(config.id, config.toMap());
  }

  /// 批量保存配置
  Future<void> saveAll(List<McpServerConfig> configs) async {
    _ensureInitialized();
    final entries = <String, Map>{};
    for (final config in configs) {
      entries[config.id] = config.toMap();
    }
    await _box!.putAll(entries);
  }

  /// 删除指定ID的配置
  Future<void> delete(String id) async {
    _ensureInitialized();
    await _box!.delete(id);
  }

  /// 设置指定配置的启用状态
  Future<void> setEnabled(String id, bool enabled) async {
    _ensureInitialized();

    final map = _box!.get(id);
    if (map != null) {
      final configMap = Map<String, dynamic>.from(map);
      configMap['enabled'] = enabled;
      await _box!.put(id, configMap);
    }
  }

  /// 获取指定ID的配置
  Future<McpServerConfig?> get(String id) async {
    _ensureInitialized();

    final map = _box!.get(id);
    if (map != null) {
      return McpServerConfig.fromMap(Map<String, dynamic>.from(map));
    }
    return null;
  }

  /// 检查是否存在指定ID的配置
  Future<bool> exists(String id) async {
    _ensureInitialized();
    return _box!.containsKey(id);
  }

  /// 获取所有启用的配置
  Future<List<McpServerConfig>> loadEnabled() async {
    final all = await loadAll();
    return all.where((config) => config.enabled).toList();
  }

  /// 删除所有配置
  Future<void> deleteAll() async {
    _ensureInitialized();
    await _box!.clear();
  }

  /// 关闭配置管理器
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
