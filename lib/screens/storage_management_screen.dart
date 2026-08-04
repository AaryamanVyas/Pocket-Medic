import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_tokens.dart';
import '../services/storage_service.dart';
import '../services/region_service.dart';
import '../services/ai_service.dart';

class StorageManagementScreen extends StatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  State<StorageManagementScreen> createState() => _StorageManagementScreenState();
}

class _StorageManagementScreenState extends State<StorageManagementScreen> {
  StorageInfo? _storageInfo;
  bool _isLoading = true;
  bool _isModelDownloading = false;
  double _modelDownloadProgress = 0;
  bool _isModelDownloaded = false;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    final info = await StorageService.getStorageInfo();
    final modelExists = await AiService.isModelDownloaded();
    if (mounted) {
      setState(() {
        _storageInfo = info;
        _isLoading = false;
        _isModelDownloaded = modelExists;
      });
    }
  }

  Future<void> _downloadModel() async {
    if (_isModelDownloading) return;
    setState(() {
      _isModelDownloading = true;
      _modelDownloadProgress = 0;
    });

    final success = await AiService.downloadModel(
      onProgress: (progress) {
        if (mounted) setState(() => _modelDownloadProgress = progress);
      },
    );

    if (success) {
      final loaded = await AiService.loadModel();
      if (mounted) {
        setState(() {
          _isModelDownloading = false;
          _isModelDownloaded = loaded;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model downloaded and loaded.')),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isModelDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${AiService.lastError}')),
        );
      }
    }
  }

  Future<void> _deleteModel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete AI Model?'),
        content: const Text('This will free ~3GB. The app will use fallback responses until you download again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File('${appDir.path}/models/gemma-4-E2B-it.litertlm');
      if (await modelFile.exists()) {
        await modelFile.delete();
      }
      if (mounted) {
        setState(() => _isModelDownloaded = false);
        await _loadStorageInfo();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage'),
        backgroundColor: AppTokens.surface,
        surfaceTintColor: AppTokens.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStorageBar(),
                const SizedBox(height: 24),
                _buildModelSection(),
                const SizedBox(height: 16),
                _buildRegionsSection(),
              ],
            ),
    );
  }

  Widget _buildStorageBar() {
    if (_storageInfo == null) return const SizedBox.shrink();
    final usage = _storageInfo!.usagePercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Device Storage',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  _storageInfo!.freeSpaceFormatted,
                  style: TextStyle(
                    color: _storageInfo!.hasEnoughSpaceForModel
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: usage,
              backgroundColor: AppTokens.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                usage > 0.9
                    ? Colors.red
                    : usage > 0.7
                        ? AppTokens.warning
                        : AppTokens.accent,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '${StorageService.formatBytes(_storageInfo!.usedBytes)} used by Pocket Medic',
              style: const TextStyle(fontSize: 12, color: AppTokens.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology_outlined, size: 20),
                SizedBox(width: 8),
                Text('AI Model (Gemma 4)', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            if (_isModelDownloaded) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  const Text('Downloaded (~3GB)'),
                  const Spacer(),
                  TextButton(
                    onPressed: _deleteModel,
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ] else if (_isModelDownloading) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(value: _modelDownloadProgress),
                  const SizedBox(height: 8),
                  Text('${(_modelDownloadProgress * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ] else ...[
              const Text(
                'Required for AI-powered responses. ~3GB download.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _downloadModel,
                  icon: const Icon(Icons.download),
                  label: const Text('Download Model'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTokens.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegionsSection() {
    final regions = RegionService.availableRegions;
    final active = RegionService.activeRegionId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map_outlined, size: 20),
                SizedBox(width: 8),
                Text('Map Regions', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ...regions.map((region) {
              final isDownloaded = RegionService.isRegionDownloaded(region.id);
              final isActive = active == region.id;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  isActive
                      ? Icons.location_on
                      : isDownloaded
                          ? Icons.check_circle_outline
                          : Icons.cloud_download_outlined,
                  color: isActive
                      ? AppTokens.accent
                      : isDownloaded
                          ? Colors.green
                          : AppTokens.text,
                  size: 20,
                ),
                title: Text(region.name, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  '${region.totalSizeMb} MB',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: isDownloaded
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteRegion(region),
                      )
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRegion(RegionInfo region) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${region.name}?'),
        content: Text('This will free ${region.totalSizeMb}MB.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true) {
      await RegionService.deleteRegion(region.id);
      await _loadStorageInfo();
    }
  }
}
