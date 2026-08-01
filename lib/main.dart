import 'package:flutter/material.dart';
import 'theme/app_tokens.dart';
import 'screens/main_shell.dart';
import 'services/history_store.dart';
import 'services/ai_service.dart';
import 'services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PermissionService.requestAll();
  await HistoryStore.load();
  await AiService.initialize();
  AiService.loadModel();
  runApp(const PocketMedicApp());
}

class PocketMedicApp extends StatelessWidget {
  const PocketMedicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocket Medic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTokens.accent,
          surface: AppTokens.surface,
        ),
        scaffoldBackgroundColor: AppTokens.surface,
        textTheme: const TextTheme(
          headlineLarge: AppTokens.heading,
          titleLarge: AppTokens.title,
          bodyLarge: AppTokens.body,
          bodyMedium: AppTokens.bodyRegular,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radius),
            side: const BorderSide(color: AppTokens.border, width: 1),
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}
