import 'package:flutter/material.dart';
import 'api_service.dart';

class GeminiDemo extends StatefulWidget {
  const GeminiDemo({super.key});

  @override
  State<GeminiDemo> createState() => _GeminiDemoState();
}

class _GeminiDemoState extends State<GeminiDemo> {
  final TextEditingController _controller = TextEditingController();
  String result = "";
  bool loading = false;

  Future<void> generate() async {
    setState(() {
      loading = true;
      result = "";
    });

    try {
      final response = await ApiService.generate(_controller.text);
      setState(() => result = response);
    } catch (e) {
      setState(() => result = "Error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flutter + Gemini")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Enter prompt",
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : generate,
              child: const Text("Generate"),
            ),
            const SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                child: Text(result),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
