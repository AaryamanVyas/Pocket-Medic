import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ask_response.dart';
import '../theme/app_tokens.dart';
import 'knowledge_service.dart';
import 'download_service.dart';
import 'storage_service.dart';
import 'logger_service.dart';

typedef ModelDownloadProgress = void Function(double progress);

class AiService {
  static bool _initialized = false;
  static bool _modelReady = false;
  static InferenceChat? _chat;
  static String? lastError;

  static bool get isReady => _modelReady;
  static String? get error => lastError;
  static String get modelFileName => 'gemma-4-E2B-it.litertlm';

  static Future<void> initialize() async {
    if (_initialized) return;

    await FlutterGemma.initialize(
      inferenceEngines: const [LiteRtLmEngine()],
    );

    _initialized = true;
  }

  static Future<String> _getModelPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/models/gemma-4-E2B-it.litertlm';
  }

  static Future<bool> isModelDownloaded() async {
    final modelPath = await _getModelPath();
    return File(modelPath).exists();
  }

  static Future<bool> downloadModel({ModelDownloadProgress? onProgress}) async {
    final storage = await StorageService.getStorageInfo();

    if (!storage.hasEnoughSpaceForModel) {
      lastError = 'Not enough storage: ${storage.freeSpaceFormatted} available, need ~3GB for model';
      Logger.error('Insufficient storage for model download', tag: 'AiService');
      return false;
    }

    final modelPath = await _getModelPath();
    final parentDir = Directory(modelPath).parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    final result = await DownloadService.download(
      url: StorageService.modelDownloadUrl,
      destPath: modelPath,
      expectedSha256: StorageService.modelSha256,
      onProgress: onProgress,
    );

    if (result.success) {
      Logger.log('Model downloaded: ${StorageService.formatBytes(result.contentLength)}', tag: 'AiService');
      return true;
    } else {
      lastError = result.errorMessage;
      Logger.error('Model download failed', tag: 'AiService', error: result.errorMessage);
      return false;
    }
  }

  static Future<bool> loadModel() async {
    try {
      final modelPath = await _getModelPath();
      final modelFile = File(modelPath);

      if (!await modelFile.exists()) {
        Logger.log('Model not found at $modelPath', tag: 'AiService');
        return false;
      }

      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(modelPath).install();

      _modelReady = true;
      lastError = null;
      return true;
    } catch (e) {
      lastError = e.toString();
      Logger.error('Model load failed', tag: 'AiService', error: e);
      return false;
    }
  }

  static Future<void> _ensureChat() async {
    if (_chat != null) return;

    final model = await FlutterGemma.getActiveModel(
      maxTokens: 4096,
    );

    _chat = await model.createChat(temperature: 0.7, topK: 1);
  }

  static Future<MockAskResponse> ask({
    required AskCategory category,
    required String query,
    required bool hasImage,
  }) async {
    if (!_modelReady) {
      return MockAskResponse.fromInput(
        category: category,
        query: query,
        hasImage: hasImage,
      );
    }

    try {
      await _ensureChat();

      final systemPrompt = _buildSystemPrompt(category);
      final ragContext = await _retrieveRagContext(query, category);
      final userMessage = _buildUserPrompt(category, query, hasImage, ragContext);

      await _chat!.addQueryChunk(Message.text(
        text: '$systemPrompt\n\n$userMessage',
        isUser: true,
      ));

      final modelResponse = await _chat!.generateChatResponse();
      if (modelResponse is TextResponse) {
        return _parseModelResponse(modelResponse.token, category, query, hasImage);
      }
      return _parseModelResponse(modelResponse.toString(), category, query, hasImage);
    } catch (e) {
      lastError = e.toString();
      Logger.error('AI ask failed', tag: 'AiService', error: e);
      return MockAskResponse.fromInput(
        category: category,
        query: query,
        hasImage: hasImage,
      );
    }
  }

  static Future<String> _retrieveRagContext(String query, AskCategory category) async {
    try {
      final results = await KnowledgeService.retrieve(query, limit: 3);
      if (results.isEmpty) return '';

      final buffer = StringBuffer();
      buffer.writeln('Relevant knowledge from your field guide:');
      for (final row in results) {
        buffer.writeln('--- ${row['title']} (${row['category']}) ---');
        buffer.writeln(row['content']);
      }
      return buffer.toString();
    } catch (e) {
      Logger.error('RAG context retrieval failed', tag: 'AiService', error: e);
      return '';
    }
  }

  static String _buildSystemPrompt(AskCategory category) {
    return '''You are Pocket Medic, an offline survival and first-aid assistant. 
You provide safe, conservative guidance for emergency situations.

IMPORTANT RULES:
- Always err on the side of caution
- Recommend seeking professional help when uncertain
- Never recommend treatments that could be dangerous
- Keep responses concise and actionable
- Include urgency level (low/medium/high)
- If something is life-threatening, always say HIGH urgency

Respond in this exact JSON format:
{
  "urgency": "low|medium|high",
  "title": "Brief title",
  "summary": "1-2 sentence summary",
  "steps": ["Step 1", "Step 2", "Step 3"],
  "escalate": true/false,
  "escalateText": "When to seek professional help"
}''';
  }

  static String _buildUserPrompt(
    AskCategory category,
    String query,
    bool hasImage,
    String ragContext,
  ) {
    final categoryContext = {
      AskCategory.medical: 'Medical/first-aid question',
      AskCategory.food: 'Food/edibility identification',
      AskCategory.water: 'Water source and purification',
      AskCategory.wildlife: 'Wildlife safety',
      AskCategory.locate: 'Location/navigation help',
    };

    final imageNote = hasImage ? 'User has attached a photo.' : '';
    final contextNote = ragContext.isNotEmpty ? '\n\nContext from field guide:\n$ragContext' : '';

    return '''Category: ${categoryContext[category]}
$imageNote
Query: $query$contextNote''';
  }

  static MockAskResponse _parseModelResponse(
    String response,
    AskCategory category,
    String query,
    bool hasImage,
  ) {
    try {
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd + 1);
        final urgency = _extractField(jsonStr, 'urgency') ?? 'medium';
        final title = _extractField(jsonStr, 'title') ?? 'AI Guidance';
        final summary = _extractField(jsonStr, 'summary') ?? response;
        final escalate = jsonStr.contains('"escalate": true');
        final escalateText = _extractField(jsonStr, 'escalateText') ?? 'Seek professional help if unsure.';
        final steps = _extractList(jsonStr, 'steps');

        return MockAskResponse(
          urgency: urgency,
          title: title,
          summary: summary,
          steps: steps.isNotEmpty ? steps : ['Follow the guidance above.'],
          escalate: escalate,
          escalateText: escalateText,
          disclaimer: 'AI-generated guidance. Not a substitute for professional care. If unsure, escalate and stay safe.',
        );
      }
    } catch (_) {}

    return MockAskResponse(
      urgency: 'medium',
      title: 'AI Guidance',
      summary: response.length > 200 ? '${response.substring(0, 200)}...' : response,
      steps: ['Follow the AI guidance above.'],
      escalate: true,
      escalateText: 'AI guidance is advisory. Seek professional help for serious conditions.',
      disclaimer: 'AI-generated guidance. Not a substitute for professional care.',
    );
  }

  static String? _extractField(String json, String field) {
    final pattern = RegExp('"$field"\\s*:\\s*"([^"]*)"');
    final match = pattern.firstMatch(json);
    return match?.group(1);
  }

  static List<String> _extractList(String json, String field) {
    final pattern = RegExp('"$field"\\s*:\\s*\\[([^\\]]*)\\]');
    final match = pattern.firstMatch(json);
    if (match == null) return [];
    final content = match.group(1)!;
    final itemPattern = RegExp('"([^"]*)"');
    return itemPattern.allMatches(content).map((m) => m.group(1)!).toList();
  }

  static Future<void> close() async {
    await _chat?.close();
    _chat = null;
  }
}
