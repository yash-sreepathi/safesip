import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sklite/ensemble/forest.dart';

class InferenceResult {
  const InferenceResult({required this.contaminant, required this.confidence});

  final String contaminant;
  final String confidence;
}

class InferenceService {
  static RandomForestClassifier? _model;
  static List<String> _classNames = [];

  static bool get isLoaded => _model != null && _classNames.isNotEmpty;

  static Future<void> init() async {
    if (_model != null) return;

    final modelJson = await rootBundle.loadString('assets/models/safesip_rf.json');
    final classesJson = await rootBundle.loadString('assets/models/safesip_classes.json');

    _model = RandomForestClassifier.fromMap(
      json.decode(modelJson) as Map<String, dynamic>,
    );
    _classNames = (json.decode(classesJson) as List<dynamic>)
        .map((name) => name as String)
        .toList();
  }

  // Device sends 40 values; model uses 36 (skips 1 kHz and 1.27 kHz).
  static List<double> toModelFeatures(List<double> sweepValues) {
    final features = <double>[];
    for (var i = 2; i <= 19; i++) {
      features.add(sweepValues[i * 2]);
    }
    for (var i = 2; i <= 19; i++) {
      features.add(sweepValues[i * 2 + 1]);
    }
    return features;
  }

  static InferenceResult run(List<double> sweepValues) {
    if (!isLoaded) {
      throw StateError('Model not loaded.');
    }
    if (sweepValues.length < 40) {
      throw StateError('Expected 40 sweep values, got ${sweepValues.length}.');
    }

    final classIndex = _model!.predict(toModelFeatures(sweepValues));
    if (classIndex < 0 || classIndex >= _classNames.length) {
      return const InferenceResult(contaminant: 'Unknown', confidence: 'Low');
    }

    return InferenceResult(
      contaminant: _classNames[classIndex],
      confidence: '—',
    );
  }

  static List<double> parseSweepLine(String csvLine) {
    final parts = csvLine.split(',');
    final values = <double>[];
    for (var i = 0; i < 40 && i < parts.length; i++) {
      values.add(double.tryParse(parts[i].trim()) ?? 0);
    }
    return values;
  }
}
