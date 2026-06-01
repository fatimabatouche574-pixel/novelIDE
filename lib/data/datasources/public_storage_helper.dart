import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// 公共存储路径工具
/// 将用户数据存储在公共目录，卸载重装不丢失
class PublicStorageHelper {
  static bool _permissionGranted = false;

  /// 公共存储根目录
  /// Android: /storage/emulated/0/NovelIDE/
  static Directory get publicRoot {
    return Directory('/storage/emulated/0/NovelIDE');
  }

  /// 请求管理所有文件的权限（Android 11+）
  /// 返回 true 表示已授权或不需要授权
  static Future<bool> requestStoragePermission() async {
    if (_permissionGranted) return true;
    if (!Platform.isAndroid) return true;

    // Android 11+ 需要 MANAGE_EXTERNAL_STORAGE
    if (await Permission.manageExternalStorage.isGranted) {
      _permissionGranted = true;
      return true;
    }

    try {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        _permissionGranted = true;
        return true;
      }
      debugPrint('MANAGE_EXTERNAL_STORAGE permission denied: $status');
      return false;
    } catch (e) {
      debugPrint('Permission request error: $e');
      return false;
    }
  }

  /// 确保目录存在（先检查权限）
  static Future<Directory> _ensureDir(String subPath) async {
    // 确保有存储权限
    await requestStoragePermission();

    final dir = Directory(p.join(publicRoot.path, subPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 作品区目录
  static Future<Directory> get worksDir => _ensureDir('作品区');

  /// 资料区目录
  static Future<Directory> get materialsDir => _ensureDir('资料区');

  /// 记忆包目录
  static Future<Directory> get memoryDir => _ensureDir('记忆包');

  /// 技能目录
  static Future<Directory> get skillDir => _ensureDir('Skill');

  /// Agent目录
  static Future<Directory> get agentDir => _ensureDir('Agent');

  /// 备份目录
  static Future<Directory> get backupDir => _ensureDir('备份');
}
