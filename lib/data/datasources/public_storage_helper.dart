import 'dart:io';
import 'package:path/path.dart' as p;

/// 公共存储路径工具
/// 将用户数据存储在公共目录，卸载重装不丢失
class PublicStorageHelper {
  /// 公共存储根目录
  /// Android: /storage/emulated/0/NovelIDE/
  static Directory get publicRoot {
    return Directory('/storage/emulated/0/NovelIDE');
  }
  
  /// 确保目录存在
  static Future<Directory> _ensureDir(String subPath) async {
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