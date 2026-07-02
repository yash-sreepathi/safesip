import 'package:flutter/material.dart';
import '../widgets/safesip_text_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const SafeSipTextLogo(
                fontSize: 120,
                showTagline: true,
                logoPath: 'assets/images/SafeSip_Logo.png',
                logoSize: 200,
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 64),
                    textStyle: const TextStyle(fontSize: 22),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/connection'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Get Started'),
                      const Icon(Icons.rocket_launch, size: 30),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 64),
                    textStyle: const TextStyle(fontSize: 22),
                  ),
                  onPressed: () => Navigator.pushNamed(context, '/map'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('View Contamination Map'),
                      const Icon(Icons.map, size: 30),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
