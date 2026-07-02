import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/readings_repository.dart';
import '../theme/app_colors.dart';

bool isSafeResult(String contaminant) {
  return contaminant == 'None' || contaminant.toLowerCase().contains('baseline');
}

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final contaminant = args?['contaminant'] as String? ?? 'Unknown';
    final confidence = args?['confidence'] as String? ?? '—';
    final safe = isSafeResult(contaminant);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: safe
                    ? AppColors.safe.withValues(alpha: 0.15)
                    : AppColors.warning.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        safe ? Icons.check_circle : Icons.warning_amber_rounded,
                        size: 64,
                        color: safe ? AppColors.safe : AppColors.warning,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        safe ? 'Water appears safe' : 'Possible contaminant: $contaminant',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (!safe) ...[
                        const SizedBox(height: 8),
                        Text('Confidence: $confidence', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _uploadToMap(context, contaminant),
                child: const Text('Upload to map'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/map'),
                child: const Text('View on map'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/detection'),
                child: const Text('Run another detection'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.settings.name == '/connection'),
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadToMap(BuildContext context, String contaminant) async {
    final upload = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add to map?'),
        content: const Text(
          'Add this result to the SafeSip map? Only approximate location is shared.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes')),
        ],
      ),
    );
    if (upload != true || !context.mounted) return;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission needed')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      final lat = (pos.latitude * 100).round() / 100;
      final lng = (pos.longitude * 100).round() / 100;
      final label = isSafeResult(contaminant) ? 'Safe' : contaminant;

      await ReadingsRepository().addReading(lat: lat, lng: lng, contaminant: label);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Result uploaded to map')),
      );
      Navigator.pushNamed(context, '/map');
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $error')),
        );
      }
    }
  }
}
