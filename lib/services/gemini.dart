import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:my_fyp/widgets/login_signup_widget.dart';
import 'api_service.dart';

class GeminiScreen extends StatefulWidget {
  final String? initialPrompt;
  const GeminiScreen({super.key, this.initialPrompt});

  @override
  State<GeminiScreen> createState() => _GeminiScreenState();
}

class _GeminiScreenState extends State<GeminiScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String result = "";
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _controller.text = widget.initialPrompt!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        generate();
      });
    }
  }

  Future<void> generate() async {
    if (_controller.text.isEmpty) return;

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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "AI Assistant",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Result Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00E5FF),
                          ),
                        )
                      : result.isEmpty
                      ? const Center(
                          child: Text(
                            "Ask me anything...",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : Markdown(
                          controller: _scrollController,
                          data: result,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.5,
                            ),
                            h1: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            h3: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            h4: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            h5: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            h6: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            em: const TextStyle(
                              color: Colors.white,
                              fontStyle: FontStyle.italic,
                            ),
                            strong: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            listBullet: const TextStyle(color: Colors.white),
                            blockquote: const TextStyle(color: Colors.white70),
                            code: TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              fontFamily: 'monospace',
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          selectable: true,
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Input Area
              CustomTextField(
                hint: "What's on your mind?",
                icon: Icons.auto_awesome_outlined,
                controller: _controller,
              ),
              const SizedBox(height: 15),

              // Generate Button
              GradientButton(
                label: loading ? "GENERATING..." : "GENERATE",
                onTap: loading ? () {} : generate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
