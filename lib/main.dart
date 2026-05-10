import 'package:flutter/material.dart';
import 'core/services/style_service.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StyleService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Listen for force-logout events from ApiService
    StyleService.logoutNotifier.addListener(_handleLogout);
  }

  @override
  void dispose() {
    StyleService.logoutNotifier.removeListener(_handleLogout);
    super.dispose();
  }

  void _handleLogout() {
    if (StyleService.logoutNotifier.value == true) {
      // Clear local session
      StyleService.logout();
      
      // Navigate to login screen and clear stack
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      
      // Reset notifier
      StyleService.logoutNotifier.value = false;
      
      // Show alert if possible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Session expired or User deleted. Please login again."),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
