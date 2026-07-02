import 'package:flutter/material.dart';

import '../services/device_connection.dart';
import '../services/inference_service.dart';
import '../theme/app_colors.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  bool _failed = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _runDetection();
  }

  Future<void> _runDetection() async {
    final connection = currentConnection;
    if (connection == null || !connection.isConnected) {
      _showError('No device connected.');
      return;
    }
    if (!InferenceService.isLoaded) {
      _showError('Model failed to load.');
      return;
    }

    try {
      final csvLine = await connection.runDetection(timeout: const Duration(seconds: 30));
      final result = InferenceService.run(InferenceService.parseSweepLine(csvLine));
      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/result',
        arguments: {
          'contaminant': result.contaminant,
          'confidence': result.confidence,
        },
      );
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _failed = true;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detection')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _failed ? _buildError() : _buildLoading(context),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.error_outline, size: 64, color: AppColors.error),
        const SizedBox(height: 16),
        Text(_errorMessage, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _failed = false;
              _errorMessage = '';
            });
            _runDetection();
          },
          child: const Text('Retry'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to connection'),
        ),
      ],
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text('Running frequency sweep…', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          'Waiting for sensor data.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
