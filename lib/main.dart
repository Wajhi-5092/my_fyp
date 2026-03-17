import 'package:flutter/material.dart';
import 'core/services/style_service.dart';
import 'features/splash/screens/splash_screen.dart';
//import 'screens/speech_screen.dart'; // optional
//import 'services/gemini.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StyleService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
