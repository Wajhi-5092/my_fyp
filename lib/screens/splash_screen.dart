import 'package:flutter/material.dart';
import 'package:my_fyp/screens/login_screen.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Animation controller for fade-in effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    _checkInternetAndNavigate();
  }

  Future<void> _checkInternetAndNavigate() async {
    // Splash screen delay
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: Center(
        child: FadeTransition(
          opacity: _controller,
          child: Image.asset(
            'assets/icon/app_icon1.png',
            width: 320,
            height: 320,
          ),
        ),
      ),
    );
  }
}
