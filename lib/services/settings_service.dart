import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyOfflineMode = 'offline_mode';
  static const _keyLanguage = 'language';
  static const _keyModelPath = 'model_path';

  static Future<bool> getOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOfflineMode) ?? true;
  }

  static Future<void> setOfflineMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOfflineMode, value);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'en';
  }

  static Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, lang);
  }

  static Future<String?> getModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyModelPath);
  }

  static Future<void> setModelPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyModelPath, path);
  }
}
