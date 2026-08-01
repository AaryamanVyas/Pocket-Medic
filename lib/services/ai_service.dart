import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ask_response.dart';

class AiService {
  static bool _initialized = false;
  static bool _modelReady = false;
  static Chat? _chat;

  static bool get isReady => _modelReady;

  static Future<void> initialize() async {
    if (_initialized) return;

    await FlutterGemma.initialize(
      inferenceEngines: [LiteRtLmEngine()],
    );

    _initialized = true;
  }

  static Future<bool> loadModel() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelPath = '${appDir.path}/gemma-4-E2B-it.litertlm';
      final modelFile = File(modelPath);

      if (!await modelFile.exists()) {
        // Try to find it in Downloads
        final downloadPath = '/storage/emulated/0/Download/gemma-4-E2B-it.litertlm';
        final downloadFile = File(downloadPath);
        if (await downloadFile.exists()) {
          await downloadFile.copy(modelPath);
        } else {
          return false;
        }
      }

      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(modelPath).install();

      _modelReady = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _ensureChat() async {
    if (_chat != null) return;

    final model = await FlutterGemma.getActiveModel(
      maxTokens: 4096,
      preferredBackend: PreferredBackend.gpu,
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
      final userMessage = _buildUserPrompt(category, query, hasImage);

      await _chat!.addQueryChunk(Message.text(
        text: '$systemPrompt\n\n$userMessage',
        isUser: true,
      ));

      final response = await _chat!.generateChatResponse();

      return _parseModelResponse(response, category, query, hasImage);
    } catch (e) {
      // Fallback to mock if model fails
      return MockAskResponse.fromInput(
        category: category,
        query: query,
        hasImage: hasImage,
      );
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
  ) {
    final categoryContext = {
      AskCategory.medical: 'Medical/first-aid question',
      AskCategory.food: 'Food/edibility identification',
      AskCategory.water: 'Water source and purification',
      AskCategory.wildlife: 'Wildlife safety',
      AskCategory.locate: 'Location/navigation help',
    };

    return '''Category: ${categoryContext[category]}
${hasImage ? 'User has attached a photo.' : ''}
Query: $query''';
  }

  static MockAskResponse _parseModelResponse(
    String response,
    AskCategory category,
    String query,
    bool hasImage,
  ) {
    try {
      // Try to extract JSON from response
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}');
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonStr = response.substring(jsonStart, jsonEnd + 1);
        // Basic JSON parsing without external package
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

    // Fallback: return raw response as summary
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
