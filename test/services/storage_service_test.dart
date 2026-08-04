import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_medic/services/storage_service.dart';

void main() {
  group('StorageService.formatBytes', () {
    test('formats bytes correctly', () {
      expect(StorageService.formatBytes(0), '0 B');
      expect(StorageService.formatBytes(512), '512 B');
      expect(StorageService.formatBytes(1023), '1023 B');
    });

    test('formats kilobytes correctly', () {
      expect(StorageService.formatBytes(1024), '1.0 KB');
      expect(StorageService.formatBytes(1536), '1.5 KB');
      expect(StorageService.formatBytes(1024 * 1023), '1023.0 KB');
    });

    test('formats megabytes correctly', () {
      expect(StorageService.formatBytes(1024 * 1024), '1.0 MB');
      expect(StorageService.formatBytes(1024 * 1024 * 256), '256.0 MB');
    });

    test('formats gigabytes correctly', () {
      expect(StorageService.formatBytes(1024 * 1024 * 1024), '1.0 GB');
      expect(StorageService.formatBytes(1024 * 1024 * 1024 * 2), '2.0 GB');
    });

    test('formats fractional gigabytes', () {
      expect(StorageService.formatBytes((1024 * 1024 * 1024 * 1.5).round()), '1.5 GB');
    });
  });

  group('StorageInfo', () {
    test('usagePercentage is zero when totalBytes is zero', () {
      const info = StorageInfo(
        totalBytes: 0,
        freeBytes: 0,
        usedBytes: 0,
        modelDownloadUrl: '',
        regionDownloadBaseUrl: '',
      );
      expect(info.usagePercentage, 0.0);
    });

    test('usagePercentage computes correctly', () {
      const info = StorageInfo(
        totalBytes: 1000,
        freeBytes: 500,
        usedBytes: 500,
        modelDownloadUrl: '',
        regionDownloadBaseUrl: '',
      );
      expect(info.usagePercentage, 0.5);
    });

    test('hasEnoughSpaceForModel is true when free > 3GB', () {
      const info = StorageInfo(
        totalBytes: 10 * 1024 * 1024 * 1024,
        freeBytes: 4 * 1024 * 1024 * 1024,
        usedBytes: 6 * 1024 * 1024 * 1024,
        modelDownloadUrl: '',
        regionDownloadBaseUrl: '',
      );
      expect(info.hasEnoughSpaceForModel, true);
    });

    test('hasEnoughSpaceForModel is false when free < 3GB', () {
      const info = StorageInfo(
        totalBytes: 5 * 1024 * 1024 * 1024,
        freeBytes: 2 * 1024 * 1024 * 1024,
        usedBytes: 3 * 1024 * 1024 * 1024,
        modelDownloadUrl: '',
        regionDownloadBaseUrl: '',
      );
      expect(info.hasEnoughSpaceForModel, false);
    });

    test('hasEnoughSpaceForRegion is true when free > 300MB', () {
      const info = StorageInfo(
        totalBytes: 1000 * 1024 * 1024,
        freeBytes: 500 * 1024 * 1024,
        usedBytes: 500 * 1024 * 1024,
        modelDownloadUrl: '',
        regionDownloadBaseUrl: '',
      );
      expect(info.hasEnoughSpaceForRegion, true);
    });

    test('hasEnoughSpaceForRegion is false when free < 300MB', () {
      const info = StorageInfo(
        totalBytes: 500 * 1024 * 1024,
        freeBytes: 200 * 1024 * 1024,
        usedBytes: 300 * 1024 * 1024,
        modelDownloadUrl: '',
        regionDownloadBaseUrl: '',
      );
      expect(info.hasEnoughSpaceForRegion, false);
    });

    test('freeSpaceFormatted uses GB when >= 1GB', () {
      const info = StorageInfo(
        totalBytes: 10 * 1024 * 1024 * 1024,
        freeBytes: 4 * 1024 * 1024 * 1024,
        usedBytes: 6 * 1024 * 1024 * 1024,
        modelDownloadUrl: '',
        regionDownloadBaseUrl: '',
      );
      expect(info.freeSpaceFormatted, '4.0 GB free');
    });

    test('freeSpaceFormatted uses MB when < 1GB', () {
      const info = StorageInfo(
        totalBytes: 500 * 1024 * 1024,
        freeBytes: 200 * 1024 * 1024,
        usedBytes: 300 * 1024 * 1024,
        modelDownloadUrl: '',
        regionDownloadBaseUrl: '',
      );
      expect(info.freeSpaceFormatted, '200 MB free');
    });

    test('modelSha256 can be null', () {
      const info = StorageInfo(
        totalBytes: 0,
        freeBytes: 0,
        usedBytes: 0,
        modelDownloadUrl: '',
        modelSha256: null,
        regionDownloadBaseUrl: '',
      );
      expect(info.modelSha256, isNull);
    });

    test('modelSha256 can be set', () {
      const info = StorageInfo(
        totalBytes: 0,
        freeBytes: 0,
        usedBytes: 0,
        modelDownloadUrl: '',
        modelSha256: 'abc123',
        regionDownloadBaseUrl: '',
      );
      expect(info.modelSha256, 'abc123');
    });
  });

  group('StorageService constants', () {
    test('modelDownloadUrl is set', () {
      expect(StorageService.modelDownloadUrl, isNotEmpty);
      expect(StorageService.modelDownloadUrl, endsWith('.litertlm'));
    });

    test('regionDownloadBaseUrl ends with slash', () {
      expect(StorageService.regionDownloadBaseUrl, endsWith('/'));
    });
  });
}
