import 'dart:async';

abstract class DeviceConnection {
  bool get isConnected;
  Future<void> disconnect();
  Future<String> runDetection({Duration timeout = const Duration(seconds: 60)});
}

DeviceConnection? currentConnection;

bool isSweepCsvLine(String line) => line.split(',').length >= 40;

void feedSerialByte(int byte, List<int> buffer, void Function(String line) onLine) {
  if (byte == 10 || byte == 13) {
    final line = String.fromCharCodes(buffer).trim();
    buffer.clear();
    if (line.isNotEmpty) onLine(line);
    return;
  }
  buffer.add(byte);
}

Future<String> waitForSweepLine(
  Stream<String> lines, {
  required Duration timeout,
}) {
  return lines.firstWhere(isSweepCsvLine).timeout(timeout);
}
