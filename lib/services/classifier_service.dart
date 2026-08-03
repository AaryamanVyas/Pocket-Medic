import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class MushroomClassifier {
  static Interpreter? _interpreter;
  static List<String> _labels = [];
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  static Future<void> loadModel() async {
    if (_loaded && _interpreter != null) return;

    const modelAsset = 'assets/mushroom_classifier.tflite';
    const labelsAsset = 'assets/labels.txt';

    final modelData = await rootBundle.load(modelAsset);
    final modelBytes = modelData.buffer.asUint8List();
    final labelsText = await rootBundle.loadString(labelsAsset);

    _interpreter = Interpreter.fromBuffer(modelBytes);
    _labels = labelsText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    _loaded = true;
  }

  static Future<Map<String, dynamic>> classify(File imageFile) async {
    if (!_loaded || _interpreter == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(Uint8List.fromList(imageBytes));
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final resized = img.copyResize(image, width: 224, height: 224);
    final input = _imageToNestedList(resized);

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final numClasses = outputShape.last;
    final output = [List<int>.filled(numClasses, 0)];

    _interpreter!.run(input, output);

    List<double> probabilities;
    if (numClasses == 1) {
      final raw = output[0][0];
      final edibleProb = raw / 255.0;
      probabilities = [edibleProb, 1.0 - edibleProb];
    } else {
      probabilities = output[0].map<double>((v) => v / 255.0).toList();
    }

    final maxIdx = probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b));

    return {
      'label': _labels.length > maxIdx ? _labels[maxIdx] : 'unknown',
      'confidence': probabilities[maxIdx],
      'probabilities': {
        for (int i = 0; i < _labels.length && i < probabilities.length; i++)
          _labels[i]: probabilities[i],
      },
    };
  }

  static List<List<List<List<int>>>> _imageToNestedList(img.Image image) {
    final result = List.generate(1, (_) =>
      List.generate(224, (y) =>
        List.generate(224, (x) =>
          List.generate(3, (c) {
            final pixel = image.getPixel(x, y);
            switch (c) {
              case 0: return img.getRed(pixel);
              case 1: return img.getGreen(pixel);
              default: return img.getBlue(pixel);
            }
          })
        )
      )
    );
    return result;
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _loaded = false;
    _labels.clear();
  }
}
