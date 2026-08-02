import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../services/region_service.dart';

class RegionPickerScreen extends StatefulWidget {
  const RegionPickerScreen({super.key});

  @override
  State<RegionPickerScreen> createState() => _RegionPickerScreenState();
}

class _RegionPickerScreenState extends State<RegionPickerScreen> {
  bool _loading = true;
  List<RegionInfo> _regions = [];
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _downloading = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await RegionService.init();
    setState(() {
      _regions = RegionService.availableRegions;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Regions')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTokens.accent))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _regions.length,
              itemBuilder: (_, index) {
                final region = _regions[index];
                final isDownloaded = RegionService.isRegionDownloaded(region.id);
                final isDownloading = _downloading[region.id] ?? false;
                final progress = _downloadProgress[region.id] ?? 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                region.name,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: AppTokens.text,
                                ),
                              ),
                            ),
                            if (isDownloaded)
                              const Chip(
                                avatar: Icon(Icons.check, size: 16, color: Colors.white),
                                label: Text('Downloaded', style: TextStyle(color: Colors.white, fontSize: 12)),
                                backgroundColor: AppTokens.accent,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Size: ~${region.totalSizeMb} MB • OSM Data: ${region.osmDate.isNotEmpty ? region.osmDate.substring(0, 10) : "Latest"}',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppTokens.text),
                        ),
                        const SizedBox(height: 12),
                        if (isDownloading) ...[
                          LinearProgressIndicator(
                            value: progress > 0 ? progress : null,
                            color: AppTokens.accent,
                            backgroundColor: AppTokens.border,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Downloading region data... ${(progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppTokens.text),
                          ),
                        ] else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isDownloaded)
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await RegionService.deleteRegion(region.id);
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('Delete'),
                                )
                              else
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(backgroundColor: AppTokens.accent),
                                  onPressed: () async {
                                    setState(() => _downloading[region.id] = true);
                                    final messenger = ScaffoldMessenger.of(context);
                                    final success = await RegionService.downloadRegion(
                                      region,
                                      onProgress: (p) {
                                        if (mounted) {
                                          setState(() => _downloadProgress[region.id] = p);
                                        }
                                      },
                                    );
                                    if (mounted) {
                                      setState(() {
                                        _downloading[region.id] = false;
                                      });
                                    }
                                    if (!mounted) return;
                                    if (success) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text('Activated ${region.name} for offline use')),
                                      );
                                      setState(() {});
                                    } else {
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text('Download failed. Check connection.')),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Download Region'),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
