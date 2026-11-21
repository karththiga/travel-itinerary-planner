import 'package:flutter/material.dart';

import '../core/theme/explore_lanka_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const duration = Duration(milliseconds: 850);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: exploreTeal,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: exploreOrange,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.landscape_outlined, size: 42),
              ),
              const SizedBox(height: 16),
              Text(
                exploreLankaName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
