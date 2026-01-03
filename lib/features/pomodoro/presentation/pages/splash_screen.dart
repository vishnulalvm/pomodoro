import 'dart:async';
import 'package:flutter/material.dart';
import '../../presentation/widgets/hue_cycle_background.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to Home Page after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MyHomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return HueCycleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            'Pomodoro',
            style: TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
