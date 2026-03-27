import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/style_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../home/widgets/recent_lecture_item.dart';

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
    if (userEmail == null) return;

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
        await PdfService.generateAndOpenLecturePdf(
          title: data["title"] ?? "Untitled",
          courseCode: data["course_code"],
          instructor: data["instructor"],
          transcript: data["transcript"] ?? "",
          date: _formatDate(data["created_at"]),
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
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: RecentLectureItem(
                    title: note["title"] ?? "Untitled",
                    subtitle: _formatDate(note["created_at"]),
                    icon: Icons.picture_as_pdf_rounded,
                    onTap: () => _openPdf(note),
                  ),
                );
              },
            ),
    );
  }
}
