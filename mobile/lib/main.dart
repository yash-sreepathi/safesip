import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/connection_screen.dart';
import 'screens/detection_screen.dart';
import 'screens/result_screen.dart';
import 'screens/map_screen.dart';
import 'services/inference_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase optional until google-services.json is added
  }
  try {
    await InferenceService.init();
  } catch (error) {
    debugPrint('Model load failed: $error');
  }
  runApp(const SafeSipApp());
}

class SafeSipApp extends StatelessWidget {
  const SafeSipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/connection': (context) => const ConnectionScreen(),
        '/detection': (context) => const DetectionScreen(),
        '/result': (context) => const ResultScreen(),
        '/map': (context) => const MapScreen(),
      },
    );
  }
}
