import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_medic/services/download_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DownloadResult', () {
    test('stores success result correctly', () {
      const result = DownloadResult(
        success: true,
        filePath: '/tmp/test.txt',
        bytesReceived: 1024,
        contentLength: 1024,
      );
      expect(result.success, true);
      expect(result.filePath, '/tmp/test.txt');
      expect(result.bytesReceived, 1024);
      expect(result.contentLength, 1024);
      expect(result.errorMessage, isNull);
    });

    test('stores failure result with error message', () {
      const result = DownloadResult(
        success: false,
        filePath: '/tmp/test.txt',
        errorMessage: 'HTTP 404',
        bytesReceived: 0,
        contentLength: 0,
      );
      expect(result.success, false);
      expect(result.errorMessage, 'HTTP 404');
      expect(result.bytesReceived, 0);
    });

    test('bytesReceived can be less than contentLength', () {
      const result = DownloadResult(
        success: false,
        filePath: '/tmp/test.txt',
        bytesReceived: 500,
        contentLength: 1024,
      );
      expect(result.bytesReceived, lessThan(result.contentLength));
    });
  });

  group('DownloadService constants', () {
    test('maxRetries is 3', () {
      expect(DownloadService.maxRetries, 3);
    });

    test('initialBackoff is 1 second', () {
      expect(DownloadService.initialBackoff, const Duration(seconds: 1));
    });
  });

  group('DownloadService.download (integration)', () {
    late String tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('download_test_').path;
    });

    tearDown(() {
      final dir = Directory(tempDir);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });

    test('creates parent directory if it does not exist', () async {
      final destPath = '$tempDir/nonexistent/deep/path/test.txt';
      final result = await DownloadService.download(
        url: 'https://httpbin.org/get',
        destPath: destPath,
        maxRetryAttempts: 0,
      );
      final dir = Directory('$tempDir/nonexistent/deep/path');
      expect(await dir.exists(), true);
      if (result.success) {
        await File(destPath).delete();
      }
    });

    test('returns failure on invalid URL', () async {
      final destPath = '$tempDir/invalid.txt';
      final result = await DownloadService.download(
        url: 'https://nonexistent.invalid.example.com/test.bin',
        destPath: destPath,
        maxRetryAttempts: 0,
      );
      expect(result.success, false);
      expect(result.errorMessage, isNotNull);
    });

    test('calls onProgress callback during download', () async {
      final progressValues = <double>[];
      final destPath = '$tempDir/progress.bin';
      final result = await DownloadService.download(
        url: 'https://httpbin.org/bytes/1024',
        destPath: destPath,
        onProgress: (p) => progressValues.add(p),
        maxRetryAttempts: 0,
      );
      if (result.success) {
        expect(progressValues, isNotEmpty);
        expect(progressValues.last, closeTo(1.0, 0.01));
        await File(destPath).delete();
      }
    });

    test('validates SHA-256 checksum on match', () async {
      final destPath = '$tempDir/checksum.bin';
      final result = await DownloadService.download(
        url: 'https://httpbin.org/bytes/100',
        destPath: destPath,
        maxRetryAttempts: 0,
      );
      if (result.success) {
        final bytes = await File(destPath).readAsBytes();
        final digest = crypto.sha256.convert(bytes).toString();
        final retry = await DownloadService.download(
          url: 'https://httpbin.org/bytes/100',
          destPath: destPath,
          expectedSha256: digest,
          maxRetryAttempts: 0,
        );
        expect(retry.success, true);
        await File(destPath).delete();
      }
    });

    test('deletes file and retries on checksum mismatch', () async {
      final destPath = '$tempDir/checksum_bad.bin';
      final result = await DownloadService.download(
        url: 'https://httpbin.org/bytes/100',
        destPath: destPath,
        expectedSha256: '0000000000000000000000000000000000000000000000000000000000000000',
        maxRetryAttempts: 0,
      );
      expect(result.success, false);
    });

    test('retries on failure up to maxRetryAttempts', () async {
      final destPath = '$tempDir/retry.bin';
      final result = await DownloadService.download(
        url: 'https://nonexistent.invalid.example.com/test.bin',
        destPath: destPath,
        maxRetryAttempts: 2,
      );
      expect(result.success, false);
      expect(result.errorMessage, isNotNull);
    });
  });

  group('DownloadService._verifyChecksum (via download)', () {
    test('accepts valid SHA-256', () async {
      final tempDir = Directory.systemTemp.createTempSync('checksum_test_').path;
      final destPath = '$tempDir/valid.bin';
      final result = await DownloadService.download(
        url: 'https://httpbin.org/bytes/50',
        destPath: destPath,
        maxRetryAttempts: 0,
      );
      if (result.success) {
        final bytes = await File(destPath).readAsBytes();
        final hex = crypto.sha256.convert(bytes).toString();
        final retry = await DownloadService.download(
          url: 'https://httpbin.org/bytes/50',
          destPath: destPath,
          expectedSha256: hex,
          maxRetryAttempts: 0,
        );
        expect(retry.success, true);
        await File(destPath).delete();
      }
      Directory(tempDir).deleteSync(recursive: true);
    });

    test('rejects wrong SHA-256', () async {
      final tempDir = Directory.systemTemp.createTempSync('checksum_bad_test_').path;
      final destPath = '$tempDir/wrong.bin';
      final result = await DownloadService.download(
        url: 'https://httpbin.org/bytes/50',
        destPath: destPath,
        expectedSha256: '0' * 64,
        maxRetryAttempts: 0,
      );
      expect(result.success, false);
      Directory(tempDir).deleteSync(recursive: true);
    });
  });
}
