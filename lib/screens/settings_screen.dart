import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../services/settings_service.dart';
import 'emergency_screen.dart';
import 'storage_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _offlineMode = true;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final offline = await SettingsService.getOfflineMode();
    final lang = await SettingsService.getLanguage();
    setState(() {
      _offlineMode = offline;
      _language = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              color: AppTokens.text,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              value: _offlineMode,
              onChanged: (val) async {
                await SettingsService.setOfflineMode(val);
                setState(() => _offlineMode = val);
              },
              title: const Text('Offline-only mode'),
              subtitle: const Text('No cloud calls in final architecture'),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language'),
              subtitle: Text(_language == 'en' ? 'English' : _language.toUpperCase()),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language selector planned.')),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Safety disclaimer'),
              subtitle: const Text('Shown on every result'),
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Safety Notice'),
                    content: const Text(
                      'Pocket Medic gives offline field and first-aid guidance only. '
                      'It is not a substitute for professional medical care, '
                      'certified foraging, or official rescue services.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: const Text('Storage'),
              subtitle: const Text('Manage downloaded data'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StorageManagementScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTokens.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                );
              },
              icon: const Icon(Icons.sos),
              label: const Text('Open Emergency Actions'),
            ),
          ),
        ],
      ),
    );
  }
}
