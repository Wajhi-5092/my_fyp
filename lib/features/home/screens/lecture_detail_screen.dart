import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import 'ai_screen.dart';
import '../widgets/lecture_detail/lecture_section_card.dart';

class LectureDetailScreen extends StatefulWidget {
  final String lectureId;

  const LectureDetailScreen({super.key, required this.lectureId});

  @override
  State<LectureDetailScreen> createState() => _LectureDetailScreenState();
}

class _LectureDetailScreenState extends State<LectureDetailScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _lecture;
  List<String> _chatResponses = [];

  @override
  void initState() {
    super.initState();
    _loadLecture();
  }

  Future<void> _loadLecture() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await ApiService.getLectureDetail(widget.lectureId);
    if (!mounted) return;

    if (res["success"] == true) {
      final lecture = Map<String, dynamic>.from(res["data"]);
      final linkedChatId = (lecture["chat_id"] ?? "").toString().trim();
      final loadedResponses = <String>[];

      if (linkedChatId.isNotEmpty) {
        final chatRes = await ApiService.getChatHistory(linkedChatId);
        if (chatRes["success"] == true) {
          final messages = (chatRes["data"]["messages"] as List?) ?? [];
          for (final msg in messages) {
            if (msg is Map && msg["role"] == "assistant") {
              final text = (msg["text"] ?? msg["content"] ?? "")
                  .toString()
                  .trim();
              if (text.isNotEmpty) {
                loadedResponses.add(text);
              }
            }
          }
        }
      }

      setState(() {
        _lecture = lecture;
        _chatResponses = loadedResponses;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = res["error"] ?? "Failed to load lecture";
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM yyyy, h:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _fallbackAiTitle(String response) {
    final clean = response.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.isEmpty) return "AI Summary";
    if (clean.length <= 70) return clean;
    return "${clean.substring(0, 70)}...";
  }

  @override
  Widget build(BuildContext context) {
    final data = _lecture;
    final lectureTitle = data?["title"]?.toString() ?? "Lecture";
    final lecturePrompt = (data?["lecture_prompt"] ?? data?["transcript"] ?? "")
        .toString()
        .trim();
    final aiResponse = (data?["ai_response"] ?? "").toString().trim();
    final aiTitle = (data?["ai_title"] ?? "").toString().trim();
    final linkedChatId = (data?["chat_id"] ?? "").toString().trim();
    final displayAiTitle = aiTitle.isNotEmpty
        ? aiTitle
        : _fallbackAiTitle(aiResponse);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141F46),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Lecture View",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadLecture,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            )
          : data == null
          ? const Center(child: Text("Lecture not found"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lectureTitle,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(data["created_at"]?.toString()),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 18),
                  LectureSectionCard(
                    title: "Topic Title",
                    child: Text(
                      displayAiTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  LectureSectionCard(
                    title: "Prompt",
                    child: SelectableText(
                      lecturePrompt.isNotEmpty
                          ? lecturePrompt
                          : "No prompt saved for this lecture.",
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_chatResponses.isNotEmpty)
                    LectureSectionCard(
                      title: "AI Responses (${_chatResponses.length})",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _chatResponses
                            .asMap()
                            .entries
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Response ${entry.key + 1}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SelectableText(entry.value),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                  else
                    LectureSectionCard(
                      title: "AI Response",
                      child: SelectableText(
                        aiResponse.isNotEmpty
                            ? aiResponse
                            : "No AI response generated yet.",
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final followPrompt = lecturePrompt.isNotEmpty
                            ? "Continue this lecture and improve the response.\n\nPrompt:\n$lecturePrompt\n\nCurrent response:\n$aiResponse"
                            : "Continue from lecture title: $lectureTitle";
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AiAssistantScreen(
                              initialPrompt: linkedChatId.isEmpty
                                  ? followPrompt
                                  : null,
                              autoSendInitialPrompt: linkedChatId.isEmpty
                                  ? false
                                  : true,
                              initialChatId: linkedChatId.isNotEmpty
                                  ? linkedChatId
                                  : null,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text("Ask Follow-up in AI"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
