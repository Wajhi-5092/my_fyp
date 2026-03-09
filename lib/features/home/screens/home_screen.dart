import 'package:flutter/material.dart';
import '../../../core/services/style_service.dart';
import 'package:my_fyp/features/home/widgets/style_dialog.dart';
import '../../speech_ai/screens/speech_screen.dart';
import 'ai_screen.dart';
import '../../auth/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> get _selectedStyles => StyleService.selectedStyles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Welcome Back!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Choose a feature to continue",
                style: TextStyle(color: Colors.white54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Feature Card 1: AI Assistant
              _buildFeatureCard(
                context,
                "AI Assistant",
                "Chat with advanced AI",
                Icons.auto_awesome,
                const Color(0xFFFFB300),
                () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AiAssistantScreen(),
                    ),
                  );
                  // Refresh state once the screen is popped to show style updates
                  setState(() {});
                },
              ),

              const SizedBox(height: 20),

              _buildFeatureCard(
                context,
                "Select style",
                _selectedStyles.isNotEmpty
                    ? "Selected: ${_selectedStyles.map((s) => s[0].toUpperCase() + s.substring(1)).join(', ')}"
                    : "Select style for your Question",
                Icons.style,
                const Color(0xFFFFB300),
                () => showDialog(
                  context: context,
                  builder: (context) => StyleDialog(
                    initialStyles: _selectedStyles,
                    onApply: (List<String> styles) async {
                      await StyleService.saveStyles(styles);
                      setState(() {});
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Feature Card 2: Speech to Text
              _buildFeatureCard(
                context,
                "Speech to Text",
                "Convert voice to text instantly",
                Icons.mic,
                const Color(0xFF536DFE),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SpeechScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1F32),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
