import 'package:flutter/material.dart';
import 'package:my_fyp/screens/splash_screen.dart';
//import 'screens/speech_screen.dart'; // optional
//import 'services/gemini.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Change this to SpeechScreen() if needed
    );
  }
}
