import 'package:flutter/material.dart';
import '../../auth/screens/login_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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

    final online = await hasInternet();

    if (online) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      if (!mounted) return;
      _showNoInternetDialog();
    }
  }

  Future<bool> hasInternet() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("No Internet Connection"),
        content: const Text(
          "Please check your internet connection and try again.",
        ),
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
