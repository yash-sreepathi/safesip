import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

import 'device_connection.dart';

class UsbDeviceConnection implements DeviceConnection {
  UsbDeviceConnection._(this._port);

  static const int _baud = 115200;

  final UsbPort _port;
  bool _closed = false;

  @override
  bool get isConnected => !_closed;

  static Future<List<UsbDevice>> listDevices() async {
    if (!Platform.isAndroid) return [];
    try {
      return await UsbSerial.listDevices();
    } catch (_) {
      return [];
    }
  }

  static Future<UsbDeviceConnection?> connect({UsbDevice? device}) async {
    if (!Platform.isAndroid) return null;
    try {
      final devices = await UsbSerial.listDevices();
      final target = device ?? (devices.isNotEmpty ? devices.first : null);
      if (target == null) return null;

      final port = await target.create();
      if (port == null) return null;
      if (!await port.open()) return null;

      await port.setDTR(true);
      await port.setRTS(true);
      await port.setPortParameters(
        _baud,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      return UsbDeviceConnection._(port);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> disconnect() async {
    _closed = true;
    await _port.close();
  }

  @override
  Future<String> runDetection({Duration timeout = const Duration(seconds: 60)}) async {
    final stream = _port.inputStream;
    if (stream == null) throw StateError('USB port has no input stream');

    final lines = StreamController<String>();
    final buffer = <int>[];
    final sub = stream.listen((Uint8List data) {
      for (final byte in data) {
        feedSerialByte(byte, buffer, lines.add);
      }
    });

    await _port.write(Uint8List.fromList('d\n'.codeUnits));
    try {
      return await waitForSweepLine(lines.stream, timeout: timeout);
    } finally {
      await sub.cancel();
      await lines.close();
    }
  }
}
