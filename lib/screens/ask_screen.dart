import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../theme/app_tokens.dart';
import '../services/ai_service.dart';
import 'ask_result.dart';

class AskScreen extends StatelessWidget {
  final AskCategory? initialCategory;
  const AskScreen({super.key, this.initialCategory});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AskFormBody(initialCategory: initialCategory ?? AskCategory.medical),
    );
  }
}

class AskFormBody extends StatefulWidget {
  final AskCategory initialCategory;
  const AskFormBody({super.key, required this.initialCategory});

  @override
  State<AskFormBody> createState() => _AskFormBodyState();
}

class _AskFormBodyState extends State<AskFormBody> {
  late AskCategory _category;
  final TextEditingController _queryController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final SpeechToText _speech = SpeechToText();
  File? _imageFile;
  bool _isAnalyzing = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
  }

  @override
  void didUpdateWidget(covariant AskFormBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      _category = widget.initialCategory;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xFile = await _picker.pickImage(source: ImageSource.camera);
    if (xFile != null) {
      setState(() => _imageFile = File(xFile.path));
    }
  }

  Future<void> _startListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty) {
          _queryController.text = result.recognizedWords;
        }
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
      ),
    );
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Ask offline',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: AppTokens.text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pick a topic, describe what you see, optionally attach a photo.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppTokens.text,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Topic',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: AppTokens.text,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in AskCategory.values)
                      ChoiceChip(
                        label: Text(c.label),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                        selectedColor: const Color(0xFFCCFBF1),
                        labelStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          color: AppTokens.text,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _category == AskCategory.medical
                      ? 'Describe the situation'
                      : 'Your question',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: AppTokens.text,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _queryController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: _category.samplePrompts.first,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in _category.samplePrompts)
                      ActionChip(
                        label: Text(p),
                        onPressed: () => _queryController.text = p,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Photo (optional)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: AppTokens.text,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 152,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTokens.border,
                    borderRadius: BorderRadius.circular(AppTokens.radius),
                    border: Border.all(color: AppTokens.border),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppTokens.radius),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 32, color: AppTokens.text),
                            SizedBox(height: 8),
                            Text(
                              'Useful for plants, wounds, animal signs',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                color: AppTokens.text,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTokens.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.radius),
                      ),
                    ),
                    onPressed: _pickImage,
                    icon: Icon(_imageFile != null ? Icons.refresh : Icons.add_a_photo_outlined),
                    label: Text(_imageFile != null ? 'Retake photo' : 'Take photo'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Icon(
              _isListening ? Icons.mic : Icons.mic_none_outlined,
              color: _isListening ? AppTokens.accent : null,
            ),
            title: Text(
              _isListening ? 'Listening...' : 'Voice input',
              style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
            ),
            subtitle: Text(_isListening ? 'Tap to stop' : 'Local speech-to-text'),
            trailing: TextButton(
              onPressed: _startListening,
              child: Text(_isListening ? 'Stop' : 'Try'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radius),
              ),
            ),
            onPressed: _isAnalyzing ? null : _runAsk,
            child: _isAnalyzing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text('Analyzing offline...'),
                    ],
                  )
                : const Text(
                    'Get offline guidance',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                  ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _runAsk() async {
    final query = _queryController.text.trim().isEmpty
        ? _category.samplePrompts.first
        : _queryController.text.trim();
    setState(() => _isAnalyzing = true);
    final response = await AiService.ask(
      category: _category,
      query: query,
      hasImage: _imageFile != null,
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AskResultScreen(
          response: response,
          category: _category,
          inputType: _imageFile != null ? 'image' : 'text',
          summary: query.length <= 65 ? query : '${query.substring(0, 65)}...',
        ),
      ),
    );
    setState(() => _isAnalyzing = false);
  }
}
