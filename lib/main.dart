import 'package:flutter/material.dart';
import 'features/splash/screens/splash_screen.dart';
//import 'screens/speech_screen.dart'; // optional
//import 'services/gemini.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 254, 250),
          brightness: Brightness.light ,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
