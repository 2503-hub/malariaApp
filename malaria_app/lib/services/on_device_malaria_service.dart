import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/detection_result.dart';

class OnDeviceMalariaService {
  OnDeviceMalariaService._();

  static final OnDeviceMalariaService instance = OnDeviceMalariaService._();

  static const String _modelAssetPath =
      'assets/models/malaria_classifier.tflite';
  static const String _labelsAssetPath = 'assets/models/labels.txt';
  static const List<String> _fallbackLabels = <String>[
    'Parasitized',
    'Uninfected',
    'Not Cell Image',
  ];
  static const double _confidenceThreshold = 0.60;

  Interpreter? _interpreter;
  List<String> _labels = _fallbackLabels;
  int? _modelLoadingTimeMs;
  File? _cachedModelFile;

  Future<DetectionResult> predict(XFile image) async {
    await _ensureLoaded();

    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('On-device interpreter is not available.');
    }

    final inputTensor = interpreter.getInputTensor(0);
    final outputTensor = interpreter.getOutputTensor(0);
    final inputShape = inputTensor.shape;
    final outputShape = outputTensor.shape;

    if (inputShape.length != 4) {
      throw StateError(
        'Unexpected input tensor shape: ${inputShape.join('x')}',
      );
    }

    final stopwatch = Stopwatch()..start();
    final resized = await _prepareImage(
      image,
      width: inputShape[2],
      height: inputShape[1],
    );

    final input = _buildInputBuffer(
      resized,
      channels: inputShape[3],
      useFloatInput: inputTensor.type == TensorType.float32,
    );

    final outputSize = outputShape.isEmpty ? 1 : outputShape.last;
    final output = List.generate(
      1,
      (_) => List<double>.filled(outputSize, 0.0),
    );

    interpreter.run(input, output);
    stopwatch.stop();

    final decoded = _decodeScores(output.first);
    return DetectionResult(
      prediction: decoded.prediction,
      confidence: decoded.confidence,
      processingTimeMs: stopwatch.elapsedMilliseconds,
      mode: DetectionMode.offline,
      modelLoadingTimeMs: _modelLoadingTimeMs,
      detail: decoded.detail,
    );
  }

  Future<List<DetectionResult>> predictMany(List<XFile> images) async {
    final results = <DetectionResult>[];
    for (final image in images) {
      results.add(await predict(image));
    }
    return results;
  }

  Future<void> _ensureLoaded() async {
    if (_interpreter != null) return;

    final stopwatch = Stopwatch()..start();
    final options = InterpreterOptions()..threads = 2;

    try {
      _interpreter = await _loadInterpreter(options);
      _labels = await _loadLabels();
      stopwatch.stop();
      _modelLoadingTimeMs = stopwatch.elapsedMilliseconds;
    } catch (e) {
      final hint = StringBuffer()
        ..writeln('Unable to create TFLite interpreter for "$_modelAssetPath".')
        ..writeln('Possible causes:')
        ..writeln('- The model file is missing from assets or not listed in pubspec.yaml.')
        ..writeln('- The asset path is incorrect. Confirm the path matches your asset entry.')
        ..writeln('- The model file is corrupt or incompatible with the platform ABI.')
        ..writeln('- The app is running on an emulator that lacks the required native libraries. Try a different device/emulator.')
        ..writeln('- The model uses unsupported operators relative to the Flutter TFLite runtime version.');

      throw StateError('${e.toString()}\n${hint.toString()}');
    }
  }

  Future<Interpreter> _loadInterpreter(InterpreterOptions options) async {
    try {
      final modelFile = await _ensureModelFile();
      return Interpreter.fromFile(modelFile, options: options);
    } catch (_) {
      final buffer = await rootBundle.load(_modelAssetPath);
      final modelBytes = buffer.buffer.asUint8List(
        buffer.offsetInBytes,
        buffer.lengthInBytes,
      );
      return Interpreter.fromBuffer(modelBytes, options: options);
    }
  }

  Future<File> _ensureModelFile() async {
    final cached = _cachedModelFile;
    if (cached != null && await cached.exists()) {
      return cached;
    }

    final buffer = await rootBundle.load(_modelAssetPath);
    final modelBytes = buffer.buffer.asUint8List(
      buffer.offsetInBytes,
      buffer.lengthInBytes,
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}malaria_classifier.tflite');
    await file.writeAsBytes(modelBytes, flush: true);
    _cachedModelFile = file;
    return file;
  }

  Future<List<String>> _loadLabels() async {
    try {
      final raw = await rootBundle.loadString(_labelsAssetPath);
      final labels = raw
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      return labels.isEmpty ? _fallbackLabels : labels;
    } catch (_) {
      return _fallbackLabels;
    }
  }

  Future<img.Image> _prepareImage(
    XFile image, {
    required int width,
    required int height,
  }) async {
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Unable to decode the selected image.');
    }

    return img.copyResize(
      decoded,
      width: width,
      height: height,
      interpolation: img.Interpolation.average,
    );
  }

  dynamic _buildInputBuffer(
    img.Image image, {
    required int channels,
    required bool useFloatInput,
  }) {
    final width = image.width;
    final height = image.height;

    if (useFloatInput) {
      return List.generate(1, (_) {
        return List.generate(height, (y) {
          return List.generate(width, (x) {
            final pixel = image.getPixel(x, y);
            return _pixelToFloatList(pixel, channels);
          });
        });
      });
    }

    return List.generate(1, (_) {
      return List.generate(height, (y) {
        return List.generate(width, (x) {
          final pixel = image.getPixel(x, y);
          return _pixelToIntList(pixel, channels);
        });
      });
    });
  }

  List<double> _pixelToFloatList(img.Pixel pixel, int channels) {
    return _pixelValues(pixel, channels).map((value) => value.toDouble()).toList();
  }

  List<int> _pixelToIntList(img.Pixel pixel, int channels) {
    return _pixelValues(pixel, channels);
  }

  List<int> _pixelValues(img.Pixel pixel, int channels) {
    final values = <int>[
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
    ];

    if (channels == 1) {
      final gray = (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b)
          .round();
      return <int>[gray];
    }

    if (channels <= 3) {
      return values.take(channels).toList();
    }

    if (channels == 4) {
      return <int>[pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), 255];
    }

    return List<int>.filled(channels, 0)..setAll(0, values);
  }

  _DecodedResult _decodeScores(List<double> scores) {
    if (scores.length == 1) {
      final positive = _clampProbability(scores.first);
      final isUninfected = positive >= 0.5;
      final prediction = isUninfected ? 'Uninfected' : 'Parasitized';
      final confidence = isUninfected ? positive : 1 - positive;

      return _DecodedResult(
        prediction: _applyThreshold(prediction, confidence),
        confidence: confidence * 100,
        detail: confidence < _confidenceThreshold
            ? 'The model is not confident enough to make a reliable call.'
            : null,
      );
    }

    final probabilities = _softmax(scores);
    final bestIndex = _argMax(probabilities);
    final predicted = _labels[bestIndex.clamp(0, _labels.length - 1).toInt()];
    final confidence = probabilities[bestIndex];

    if (predicted == 'Not Cell Image') {
      return _DecodedResult(
        prediction: predicted,
        confidence: confidence * 100,
        detail:
            'The uploaded image does not appear to be a blood smear cell image.',
      );
    }

    if (confidence < _confidenceThreshold) {
      return _DecodedResult(
        prediction: 'Uncertain',
        confidence: confidence * 100,
        detail:
            'The model is not confident enough to make a reliable call.',
      );
    }

    return _DecodedResult(
      prediction: predicted,
      confidence: confidence * 100,
    );
  }

  String _applyThreshold(String prediction, double confidence) {
    if (prediction == 'Not Cell Image') return prediction;
    if (confidence < _confidenceThreshold) return 'Uncertain';
    return prediction;
  }

  double _clampProbability(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    return value.clamp(0, 1).toDouble();
  }

  List<double> _softmax(List<double> values) {
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final exps = values.map((value) => _safeExp(value - maxValue)).toList();
    final sum = exps.fold<double>(0, (a, b) => a + b);
    if (sum == 0) {
      return List<double>.filled(values.length, 1 / values.length);
    }

    return exps.map((value) => value / sum).toList();
  }

  double _safeExp(double value) {
    if (value < -50) return 0;
    if (value > 50) return math.exp(50);
    return math.exp(value);
  }

  int _argMax(List<double> values) {
    var bestIndex = 0;
    var bestValue = values.first;
    for (var index = 1; index < values.length; index++) {
      if (values[index] > bestValue) {
        bestValue = values[index];
        bestIndex = index;
      }
    }
    return bestIndex;
  }
}

class _DecodedResult {
  const _DecodedResult({
    required this.prediction,
    required this.confidence,
    this.detail,
  });

  final String prediction;
  final double confidence;
  final String? detail;
}
