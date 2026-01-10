import 'package:flutter/material.dart';
import 'dart:async';
import '../services/gemini.dart';
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

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _checkInternetAndNavigate();
  }

  Future<void> _checkInternetAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    final online = await hasInternet();

    if (!mounted) return;

    if (online) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GeminiDemo()),
      );
    } else {
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _controller,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.mic_rounded, size: 90, color: Colors.blueAccent),
              SizedBox(height: 16),
              Text(
                "VoiceNoteX",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Speak. Think. Create.",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
