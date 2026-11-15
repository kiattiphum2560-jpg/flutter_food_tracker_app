import 'dart:async';

import 'package:flutter/material.dart';

import 'show_all_food_tracker_ui.dart';

class SplashScreenUi extends StatefulWidget {
  const SplashScreenUi({super.key});

  @override
  State<SplashScreenUi> createState() => _SplashScreenUiState();
}

class _SplashScreenUiState extends State<SplashScreenUi> {
  late final Timer _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const ShowAllFoodTrackerUi(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFFFFF36);

    return Scaffold(
      backgroundColor: const Color(0xFFF83E33),
      body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                height: 130,
                child: Image.asset(
                  'assets/icon/burger.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Food Tracker',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 4),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lunch_dining, color: Color(0xFFFFC107)),
                  SizedBox(width: 6),
                  Icon(Icons.fastfood, color: Color(0xFFFF9800)),
                  SizedBox(width: 6),
                  Icon(Icons.local_pizza, color: Color(0xFFFF7043)),
                  SizedBox(width: 6),
                  Icon(Icons.icecream, color: Color(0xFFFF80AB)),
                  SizedBox(width: 6),
                  Icon(Icons.cake, color: Color(0xFF90CAF9)),
                ],
              ),
              const SizedBox(height: 14),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: accentColor,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
      ),
    );
  }
}