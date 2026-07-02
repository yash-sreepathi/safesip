import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:usb_serial/usb_serial.dart';

import '../theme/app_colors.dart';
import '../services/device_connection.dart';
import '../services/ble_connection.dart';
import '../services/usb_connection.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _connected = false;
  bool _connecting = false;
  String _transport = 'bluetooth';
  DeviceConnection? _connection;
  List<BluetoothDevice> _scannedDevices = [];
  bool _scanning = false;
  List<UsbDevice> _usbDevices = [];
  bool _loadingUsb = false;

  Future<void> _scanBle() async {
    setState(() {
      _scanning = true;
      _scannedDevices = [];
    });
    try {
      final devices = await BleDeviceConnection.scan(timeout: const Duration(seconds: 8));
      if (mounted) setState(() => _scannedDevices = devices);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _connectBle(BluetoothDevice device) async {
    setState(() => _connecting = true);
    try {
      final conn = BleDeviceConnection(device);
      await conn.connect();
      if (mounted) _setConnected(conn);
    } catch (e) {
      if (mounted) {
        setState(() => _connecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connect failed: $e')),
        );
      }
    }
  }

  Future<void> _refreshUsbDevices() async {
    if (!Platform.isAndroid) return;
    setState(() => _loadingUsb = true);
    try {
      final devices = await UsbDeviceConnection.listDevices();
      if (mounted) {
        setState(() {
          _usbDevices = devices;
          _loadingUsb = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingUsb = false);
    }
  }

  Future<void> _connectUsb([UsbDevice? device]) async {
    if (!Platform.isAndroid) return;
    setState(() => _connecting = true);
    try {
      final conn = await UsbDeviceConnection.connect(device: device);
      if (mounted && conn != null) {
        _setConnected(conn);
      } else if (mounted) {
        setState(() => _connecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No USB serial device found. Connect cable and try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _connecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('USB connect failed: $e')),
        );
      }
    }
  }

  void _setConnected(DeviceConnection conn) {
    currentConnection = conn;
    setState(() {
      _connection = conn;
      _connecting = false;
      _connected = true;
      _scannedDevices = [];
      _usbDevices = [];
    });
  }

  void _disconnect() async {
    await _connection?.disconnect();
    currentConnection = null;
    _connection = null;
    setState(() => _connected = false);
  }

  void _startDetection() {
    Navigator.pushNamed(context, '/detection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect device'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _connected ? _buildConnected() : _buildConnectOptions(),
        ),
      ),
    );
  }

  Widget _buildConnectOptions() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Text(
          'Choose connection',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'bluetooth', label: Text('Bluetooth'), icon: Icon(Icons.bluetooth)),
            ButtonSegment(value: 'usb', label: Text('USB cable'), icon: Icon(Icons.usb)),
          ],
          selected: {_transport},
          onSelectionChanged: (s) => setState(() => _transport = s.first),
        ),
        const SizedBox(height: 24),
        if (_transport == 'bluetooth') ..._buildBluetoothSection(),
        if (_transport == 'usb') ..._buildUsbSection(),
        if (_connecting)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  List<Widget> _buildBluetoothSection() {
    return [
      ElevatedButton.icon(
        onPressed: _scanning ? null : _scanBle,
        icon: _scanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.search),
        label: Text(_scanning ? 'Scanning for devices…' : 'Scan for devices'),
      ),
      const SizedBox(height: 20),
      Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Devices',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              if (_scanning && _scannedDevices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Scanning…', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else if (_scannedDevices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No devices found. Turn on SafeSip and Bluetooth, then scan again.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                )
              else
                ..._scannedDevices.map(
                  (d) => ListTile(
                    leading: const Icon(Icons.bluetooth),
                    title: Text(
                      d.platformName.isNotEmpty ? d.platformName : d.remoteId.toString(),
                    ),
                    subtitle: Text(
                      d.remoteId.toString(),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    onTap: _connecting ? null : () => _connectBle(d),
                  ),
                ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildUsbSection() {
    if (!Platform.isAndroid) {
      return [
        const Text(
          'USB is only supported on Android. Connect via Bluetooth or use an Android device.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ];
    }
    return [
      Text(
        'Connect USB cable (phone to ESP32), then tap a device or "Connect via USB".',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _loadingUsb || _connecting ? null : _refreshUsbDevices,
        icon: _loadingUsb
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.usb),
        label: Text(_loadingUsb ? 'Checking for devices…' : 'Refresh USB devices'),
      ),
      if (_usbDevices.isNotEmpty) ...[
        const SizedBox(height: 16),
        Card(
          color: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'USB devices',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                ..._usbDevices.map(
                  (d) => ListTile(
                    leading: const Icon(Icons.usb),
                    title: Text(d.productName ?? d.deviceName),
                    subtitle: Text(
                      d.manufacturerName ?? 'USB serial',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    onTap: _connecting ? null : () => _connectUsb(d),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _connecting ? null : () => _connectUsb(),
        child: const Text('Connect via USB (first device)'),
      ),
    ];
  }

  Widget _buildConnected() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: AppColors.safe.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.safe, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'SafeSip connected',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _startDetection,
          child: const Text('Start detection'),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _disconnect,
          child: const Text('Disconnect'),
        ),
      ],
    );
  }
}
