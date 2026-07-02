import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_connection.dart';

class BleDeviceConnection implements DeviceConnection {
  BleDeviceConnection(this._device);

  final BluetoothDevice _device;
  BluetoothCharacteristic? _writeChar;
  final StreamController<String> _lines = StreamController<String>.broadcast();
  final List<int> _buffer = [];
  bool _closed = false;

  @override
  bool get isConnected => !_closed && _device.isConnected;

  static Future<List<BluetoothDevice>> scan({Duration timeout = const Duration(seconds: 10)}) async {
    if (await FlutterBluePlus.isSupported == false) return [];
    try {
      await FlutterBluePlus.startScan(timeout: timeout);
      final devices = <BluetoothDevice>[];
      final sub = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final device = result.device;
          if (!devices.any((d) => d.remoteId == device.remoteId)) {
            devices.add(device);
          }
        }
      });
      await Future.delayed(timeout);
      await sub.cancel();
      await FlutterBluePlus.stopScan();
      return devices;
    } catch (_) {
      await FlutterBluePlus.stopScan();
      return [];
    }
  }

  Future<void> connect() async {
    await _device.connect();
    await _device.discoverServices();

    BluetoothCharacteristic? notifyChar;
    for (final service in _device.servicesList) {
      if (!service.uuid.toString().toLowerCase().contains('6e400001')) continue;
      for (final char in service.characteristics) {
        final id = char.characteristicUuid.toString().toLowerCase();
        if (id.contains('6e400002') &&
            (char.properties.write || char.properties.writeWithoutResponse)) {
          _writeChar = char;
        }
        if (id.contains('6e400003') &&
            (char.properties.notify || char.properties.indicate)) {
          notifyChar = char;
        }
      }
    }

    if (notifyChar != null) {
      await notifyChar.setNotifyValue(true);
      notifyChar.lastValueStream.listen(_onData);
    }
  }

  void _onData(List<int> data) {
    for (final byte in data) {
      feedSerialByte(byte, _buffer, _lines.add);
    }
  }

  @override
  Future<void> disconnect() async {
    _closed = true;
    await _device.disconnect();
    await _lines.close();
  }

  @override
  Future<String> runDetection({Duration timeout = const Duration(seconds: 60)}) async {
    final writeChar = _writeChar;
    if (writeChar == null) throw StateError('No write characteristic');

    final detection = waitForSweepLine(_lines.stream, timeout: timeout);
    final cmd = 'd\n'.codeUnits;
    if (writeChar.properties.write) {
      await writeChar.write(cmd);
    } else {
      await writeChar.write(cmd, withoutResponse: true);
    }
    return detection;
  }
}
