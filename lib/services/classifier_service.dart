import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ClassifierResult {
  final String label;
  final double confidence;
  final Map<String, double> probabilities;
  final bool isUncertain;

  const ClassifierResult({
    required this.label,
    required this.confidence,
    required this.probabilities,
    required this.isUncertain,
  });
}

class MushroomClassifier {
  static Interpreter? _interpreter;
  static List<String> _labels = [];
  static bool _loaded = false;

  static const double uncertainThreshold = 0.65;

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

  static Future<ClassifierResult> classify(File imageFile) async {
    if (!_loaded || _interpreter == null) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    final resized = img.copyResize(image, width: 224, height: 224);
    final input = _imageToNestedList(resized);

    final outputTensor = _interpreter!.getOutputTensor(0);
    final isFloatOutput = outputTensor.type == TensorType.float32 ||
        outputTensor.type == TensorType.float16;
    final numClasses = outputTensor.shape.last;

    List<double> probabilities;

    if (isFloatOutput) {
      final output = [List<double>.filled(numClasses, 0.0)];
      _interpreter!.run(input, output);
      if (numClasses == 1) {
        final sigmoidVal = output[0][0];
        probabilities = [1.0 - sigmoidVal, sigmoidVal];
      } else {
        probabilities = output[0];
      }
    } else {
      final output = [List<int>.filled(numClasses, 0)];
      _interpreter!.run(input, output);
      if (numClasses == 1) {
        final raw = output[0][0];
        final sigmoidVal = raw / 255.0;
        probabilities = [1.0 - sigmoidVal, sigmoidVal];
      } else {
        probabilities = output[0].map<double>((v) => v / 255.0).toList();
      }
    }

    final maxIdx = probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b));
    final confidence = probabilities[maxIdx];

    return ClassifierResult(
      label: _labels.length > maxIdx ? _labels[maxIdx] : 'unknown',
      confidence: confidence,
      probabilities: {
        for (int i = 0; i < _labels.length && i < probabilities.length; i++)
          _labels[i]: probabilities[i],
      },
      isUncertain: confidence < uncertainThreshold,
    );
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
