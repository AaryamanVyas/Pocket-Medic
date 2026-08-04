import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'logger_service.dart';

class StorageInfo {
  final int totalBytes;
  final int freeBytes;
  final int usedBytes;
  final String modelDownloadUrl;
  final String? modelSha256;
  final String regionDownloadBaseUrl;

  const StorageInfo({
    required this.totalBytes,
    required this.freeBytes,
    required this.usedBytes,
    required this.modelDownloadUrl,
    this.modelSha256,
    required this.regionDownloadBaseUrl,
  });

  double get usagePercentage => totalBytes > 0 ? usedBytes / totalBytes : 0;
  bool get hasEnoughSpaceForModel => freeBytes > 3000 * 1024 * 1024;
  bool get hasEnoughSpaceForRegion => freeBytes > 300 * 1024 * 1024;

  String get freeSpaceFormatted {
    if (freeBytes >= 1024 * 1024 * 1024) {
      return '${(freeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB free';
    }
    return '${(freeBytes / (1024 * 1024)).toStringAsFixed(0)} MB free';
  }
}

class StorageService {
  static const String modelDownloadUrl =
      'https://raw.githubusercontent.com/pocket-medic/models/main/gemma-4-E2B-it.litertlm';
  static const String? modelSha256 = null;
  static const String regionDownloadBaseUrl =
      'https://raw.githubusercontent.com/pocket-medic/maps/main/';

  static Future<StorageInfo> getStorageInfo() async {
    int totalBytes = 0;
    int freeBytes = 0;

    try {
      if (Platform.isAndroid) {
        final result = await _getAndroidStorageStats();
        totalBytes = result.totalBytes;
        freeBytes = result.freeBytes;
      } else if (Platform.isIOS) {
        final result = await _getIOSStorageStats();
        totalBytes = result.totalBytes;
        freeBytes = result.freeBytes;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final stat = await dir.stat();
        totalBytes = stat.size;
        freeBytes = stat.size;
      }
    } catch (e) {
      Logger.error('Failed to get storage info', tag: 'StorageService', error: e);
    }

    final appDir = await getApplicationDocumentsDirectory();
    int usedBytes = 0;
    if (await Directory('${appDir.path}/models').exists()) {
      usedBytes += await _calculateDirSize('${appDir.path}/models');
    }
    if (await Directory('${appDir.path}/regions').exists()) {
      usedBytes += await _calculateDirSize('${appDir.path}/regions');
    }

    return StorageInfo(
      totalBytes: totalBytes,
      freeBytes: freeBytes,
      usedBytes: usedBytes,
      modelDownloadUrl: modelDownloadUrl,
      modelSha256: modelSha256,
      regionDownloadBaseUrl: regionDownloadBaseUrl,
    );
  }

  static Future<({int totalBytes, int freeBytes})> _getAndroidStorageStats() async {
    int totalBytes = 0;
    int freeBytes = 0;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final storagePath = appDir.parent.parent.path;

      final storageDir = Directory(storagePath);
      if (await storageDir.exists()) {
        final stat = await storageDir.stat();
        totalBytes = stat.size;
      }

      final tempDir = await getTemporaryDirectory();
      final stat = await tempDir.stat();
      freeBytes = stat.size;
    } catch (e) {
      Logger.error('Android storage stats failed', tag: 'StorageService', error: e);
    }

    return (totalBytes: totalBytes, freeBytes: freeBytes);
  }

  static Future<({int totalBytes, int freeBytes})> _getIOSStorageStats() async {
    int totalBytes = 0;
    int freeBytes = 0;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final stat = await appDir.stat();
      totalBytes = stat.size;
      freeBytes = stat.size;
    } catch (e) {
      Logger.error('iOS storage stats failed', tag: 'StorageService', error: e);
    }

    return (totalBytes: totalBytes, freeBytes: freeBytes);
  }

  static Future<int> _calculateDirSize(String path) async {
    int total = 0;
    final dir = Directory(path);
    if (!await dir.exists()) return 0;

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  static Future<int> getModelSize() async {
    final appDir = await getApplicationDocumentsDirectory();
    final modelPath = '${appDir.path}/models/gemma-4-E2B-it.litertlm';
    final file = File(modelPath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  static Future<int> getRegionSize(String regionId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final regionPath = '${appDir.path}/regions/$regionId';
    return await _calculateDirSize(regionPath);
  }

  static String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}
