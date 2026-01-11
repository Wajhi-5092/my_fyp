import 'package:flutter/material.dart';
import 'package:my_fyp/screens/login_screen.dart';
//import 'package:my_fyp/services/gemini.dart';
import 'dart:async';

import '../utils/internet_check.dart';

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
    // ⏱ Increase this duration to increase animation time
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // WAS 2 seconds
    )..forward();

    // Check internet and navigate after splash delay
    _checkInternetAndNavigate();
  }

  Future<void> _checkInternetAndNavigate() async {
    // ⏱ Splash screen delay
    // Increase this to keep splash screen longer
    await Future.delayed(const Duration(seconds: 4)); // WAS 2 seconds

    // Check internet connection
    final online = await hasInternet();

    if (!mounted) return;

    if (online) {
      // Navigate to main screen if internet is available
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      // Show dialog if no internet
      _showNoInternetDialog();
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("No Internet"),
        content: const Text("Please connect to the internet to continue."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Retry internet check
              _checkInternetAndNavigate();
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Dispose animation controller to avoid memory leak
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App logo (transparent PNG)
                  Image.asset(
                    'assets/icon/app_icon1.png',
                    width: 320,
                    height: 320,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
