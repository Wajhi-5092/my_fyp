import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/style_service.dart';
import 'pdf_viewer.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<dynamic> _notes = [];
  bool _isLoading = true;
  String? get userEmail => StyleService.currentUserEmail;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    if (userEmail == null) {
      setState(() {
        _notes = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final res = await ApiService.getLectures(userEmail!);

    if (res["success"] == true) {
      setState(() {
        _notes = res["data"];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('d MMM, yyyy · h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  List<String> _extractAssistantResponses(dynamic chatHistoryData) {
    if (chatHistoryData is! Map<String, dynamic>) return [];
    final messages = chatHistoryData["messages"];
    if (messages is! List) return [];

    return messages
        .whereType<Map>()
        .where((msg) => msg["role"]?.toString() == "assistant")
        .map((msg) => (msg["content"] ?? "").toString().trim())
        .where((content) => content.isNotEmpty)
        .toList();
  }

  Future<String?> _pickResponseForPdf(List<String> responses) async {
    if (responses.isEmpty) return null;
    if (responses.length == 1) return responses.first;

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  "Select AI Response for PDF",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: responses.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final response = responses[index];
                    final preview = response.length > 120
                        ? "${response.substring(0, 120)}..."
                        : response;
                    return ListTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFF141F46),
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(
                        "Response ${index + 1}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.pop(sheetContext, response),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPdf(dynamic note) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final detailRes = await ApiService.getLectureDetail(note["lecture_id"]);
      if (mounted) Navigator.pop(context); // hide loading

      if (detailRes["success"] == true) {
        final data = detailRes["data"];
        final lecturePrompt = (data["lecture_prompt"] ?? "").toString().trim();
        final savedAiResponse = (data["ai_response"] ?? "").toString().trim();
        final transcript = (data["transcript"] ?? "").toString().trim();
        final chatId = (data["chat_id"] ?? "").toString().trim();

        String selectedAiResponse = savedAiResponse;
        if (chatId.isNotEmpty) {
          final chatRes = await ApiService.getChatHistory(chatId);
          if (chatRes["success"] == true) {
            final allResponses = _extractAssistantResponses(chatRes["data"]);
            final picked = await _pickResponseForPdf(allResponses);
            if (picked == null) {
              return;
            }
            selectedAiResponse = picked.trim();
          }
        }

        final pdfContent = selectedAiResponse.isNotEmpty
            ? (lecturePrompt.isNotEmpty
                  ? "Lecture Prompt:\n$lecturePrompt\n\nAI Response:\n$selectedAiResponse"
                  : selectedAiResponse)
            : transcript;

        final pdfBytes = await PdfService.generateLecturePdfBytes(
          title: data["title"] ?? "Untitled",
          courseCode: data["course_code"],
          instructor: data["instructor"],
          transcript: pdfContent,
          date: _formatDate(data["created_at"]),
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              pdfBytes: pdfBytes,
              fileName: "${(data["title"] ?? "lecture").toString()}.pdf",
            ),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(detailRes["error"] ?? "Failed to load lecture"),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Only pop if the dialog is still showing (it might have been popped by Navigator.pop already)
        // But Navigator.pop(context) is safe if called more than once?
        // Actually, we should check if we already popped.
        // Let's use a try-pop pattern:
        if (Navigator.canPop(context)) Navigator.pop(context);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error opening PDF: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF141F46),
        title: const Text(
          "My Notes",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadNotes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : userEmail == null
          ? const Center(
              child: Text(
                "Please log in to view your notes",
                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
              ),
            )
          : _notes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notes_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "No notes saved yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.red,
                      ),
                    ),
                    title: Text(
                      note["title"] ?? "Untitled",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _formatDate(note["created_at"]?.toString() ?? ""),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () => _openPdf(note),
                  ),
                );
              },
            ),
    );
  }
}
