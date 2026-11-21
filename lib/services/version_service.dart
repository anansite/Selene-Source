import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VersionService {
  static const String lanCdnUrl = 'https://cdn.205002.xyz/selene/latest.json';
  static const String githubRepoUrl = 'https://github.com/anansite/Selene-Source';
  static const String githubApiUrl = 'https://api.github.com/repos/anansite/Selene-Source/releases/latest';
  static const String acceleratorPrefix = 'https://ghfast.top/';
  static const String _lastCheckKey = 'last_version_check';
  static const String _dismissedVersionKey = 'dismissed_version';
  
  /// 检查是否有新版本
  static Future<VersionInfo?> checkForUpdate() async {
    try {
      // 获取当前版本
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // 1. 优先尝试家庭/局域网 CDN（1.5 秒快速超时，在家秒级响应）
      try {
        final lanResponse = await http.get(
          Uri.parse(lanCdnUrl),
        ).timeout(const Duration(milliseconds: 1500));
        
        if (lanResponse.statusCode == 200) {
          final data = json.decode(lanResponse.body);
          final tagName = (data['tagName'] ?? data['tag_name']) as String;
          final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;
          final releaseNotes = (data['releaseNotes'] ?? data['body']) as String? ?? '';
          final downloadUrl = data['downloadUrl'] as String?;
          
          if (_isNewerVersion(currentVersion, latestVersion)) {
            return VersionInfo(
              currentVersion: currentVersion,
              latestVersion: latestVersion,
              releaseNotes: releaseNotes,
              downloadUrl: downloadUrl,
            );
          }
          return null;
        }
      } catch (_) {
        // 局域网不可达或在室外，平滑回退走公网
      }

      // 2. 外部网络回退走 GitHub API
      final response = await http.get(
        Uri.parse(githubApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tagName = data['tag_name'] as String;
        final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;
        final releaseNotes = data['body'] as String? ?? '';
        
        // 比较版本号
        if (_isNewerVersion(currentVersion, latestVersion)) {
          return VersionInfo(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseNotes: releaseNotes,
          );
        }
      }
      
      return null;
    } catch (e) {
      print('检查版本更新失败: $e');
      return null;
    }
  }
  
  /// 获取 GitHub Release 页面 URL（默认启用国内镜像加速）
  static String getReleaseUrl(String version, {bool accelerated = true}) {
    final rawUrl = '$githubRepoUrl/releases/tag/v$version';
    return accelerated ? '$acceleratorPrefix$rawUrl' : rawUrl;
  }
  
  /// 比较版本号，判断是否有新版本
  static bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final latestPart = i < latestParts.length ? latestParts[i] : 0;
      
      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }
    
    return false;
  }
  
  /// 检查是否应该显示更新提示（避免频繁提示）
  static Future<bool> shouldShowUpdatePrompt(String version) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 检查用户是否已忽略此版本
    final dismissedVersion = prefs.getString(_dismissedVersionKey);
    if (dismissedVersion == version) {
      return false;
    }
    
    // 检查上次检查时间（每天最多提示一次）
    final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final dayInMs = 24 * 60 * 60 * 1000;
    
    if (now - lastCheck < dayInMs) {
      return false;
    }
    
    // 更新最后检查时间
    await prefs.setInt(_lastCheckKey, now);
    return true;
  }
  
  /// 标记用户已忽略某个版本
  static Future<void> dismissVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, version);
  }
  
  /// 清除忽略记录（用于测试或重置）
  static Future<void> clearDismissedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedVersionKey);
  }
}

class VersionInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String? downloadUrl;
  
  VersionInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    this.downloadUrl,
  });
}
