import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/device_connection.dart';
import 'package:mobile/services/inference_service.dart';

void main() {
  test('parseSweepLine reads first 40 CSV values', () {
    final line = '${List.generate(40, (i) => '$i').join(',')},detection';
    final values = InferenceService.parseSweepLine(line);

    expect(values.length, 40);
    expect(values.first, 0);
    expect(values.last, 39);
  });

  test('isSweepCsvLine requires at least 40 values', () {
    expect(isSweepCsvLine('1,2,3'), false);
    expect(isSweepCsvLine(List.generate(40, (i) => '$i').join(',')), true);
  });
}
