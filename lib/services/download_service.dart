import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'logger_service.dart';

typedef ProgressCallback = void Function(double progress);

class DownloadResult {
  final bool success;
  final String filePath;
  final String? errorMessage;
  final int bytesReceived;
  final int contentLength;

  const DownloadResult({
    required this.success,
    required this.filePath,
    this.errorMessage,
    required this.bytesReceived,
    required this.contentLength,
  });
}

class DownloadService {
  static const int maxRetries = 3;
  static const Duration initialBackoff = Duration(seconds: 1);

  static Future<DownloadResult> download({
    required String url,
    required String destPath,
    String? expectedSha256,
    ProgressCallback? onProgress,
    int maxRetryAttempts = maxRetries,
  }) async {
    final file = File(destPath);
    final parentDir = file.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    Exception? lastError;

    for (int attempt = 0; attempt <= maxRetryAttempts; attempt++) {
      try {
        if (attempt > 0) {
          final backoff = initialBackoff * pow(2, attempt - 1);
          Logger.log('Download attempt $attempt failed, retrying in ${backoff.inSeconds}s', tag: 'DownloadService');
          await Future.delayed(backoff);
        }

        final result = await _downloadOnce(url, destPath, onProgress);

        if (result.success) {
          if (expectedSha256 != null) {
            final verified = await _verifyChecksum(destPath, expectedSha256);
            if (!verified) {
              lastError = Exception('Checksum mismatch for $destPath');
              Logger.error('Checksum mismatch', tag: 'DownloadService');
              await file.delete();
              continue;
            }
            Logger.log('Checksum verified for $destPath', tag: 'DownloadService');
          }
          return result;
        } else {
          lastError = Exception(result.errorMessage ?? 'Download failed');
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        Logger.error('Download attempt $attempt threw', tag: 'DownloadService', error: e);
      }
    }

    return DownloadResult(
      success: false,
      filePath: destPath,
      errorMessage: lastError?.toString() ?? 'Download failed after $maxRetryAttempts retries',
      bytesReceived: 0,
      contentLength: 0,
    );
  }

  static Future<DownloadResult> _downloadOnce(
    String url,
    String destPath,
    ProgressCallback? onProgress,
  ) async {
    final request = http.Request('GET', Uri.parse(url));
    final response = await http.Client().send(request);

    if (response.statusCode != 200) {
      return DownloadResult(
        success: false,
        filePath: destPath,
        errorMessage: 'HTTP ${response.statusCode}',
        bytesReceived: 0,
        contentLength: response.contentLength ?? 0,
      );
    }

    final contentLength = response.contentLength ?? 0;
    int received = 0;
    final sink = File(destPath).openWrite(mode: FileMode.write);

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress?.call(received / contentLength);
        }
      }
      await sink.close();
    } catch (e) {
      await sink.close();
      rethrow;
    }

    return DownloadResult(
      success: true,
      filePath: destPath,
      bytesReceived: received,
      contentLength: contentLength,
    );
  }

  static Future<bool> _verifyChecksum(String filePath, String expectedSha256) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    final bytes = await file.readAsBytes();
    final digest = crypto.sha256.convert(bytes);
    final actual = digest.toString();
    return actual.toLowerCase() == expectedSha256.toLowerCase();
  }

}
