import 'package:flutter/material.dart';
import '../../../core/services/style_service.dart';
import '../widgets/ai/style_dialog.dart';
import '../../speech_ai/screens/speech_screen.dart';
import 'ai_screen.dart';
import '../../notes/screens/notes_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../widgets/lecture_dialog.dart';
import '../../../core/services/api_service.dart';
import 'package:intl/intl.dart';
import 'lecture_detail_screen.dart';

import '../widgets/home_header.dart';
import '../widgets/start_lecture_card.dart';
import '../widgets/quick_actions_row.dart';
import '../widgets/recent_lectures_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> get _selectedStyles => StyleService.selectedStyles;
  String? get userEmail => StyleService.currentUserEmail;

  List<dynamic> _lectures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLectures();
  }

  Future<void> _loadLectures() async {
    if (userEmail == null) return;

    setState(() => _isLoading = true);
    final res = await ApiService.getLectures(userEmail!);

    if (res["success"] == true) {
      setState(() {
        _lectures = res["data"];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteLecture(Map<String, dynamic> lecture) async {
    final lectureId = lecture["lecture_id"]?.toString();
    if (lectureId == null || lectureId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete lecture?"),
        content: Text(
          "This will remove \"${lecture["title"] ?? "Untitled"}\" from recent lectures.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await ApiService.deleteLecture(lectureId);
    if (!mounted) return;

    if (res["success"] == true) {
      await _loadLectures();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lecture deleted")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["error"] ?? "Failed to delete lecture")),
      );
    }
  }

  Future<void> _deleteAllLectures() async {
    final lectureIds = _lectures
        .map((lec) => lec["lecture_id"]?.toString() ?? "")
        .where((id) => id.isNotEmpty)
        .toList();

    if (lectureIds.isEmpty) return;

    setState(() => _isLoading = true);

    var deletedCount = 0;
    var failedCount = 0;

    for (final lectureId in lectureIds) {
      final res = await ApiService.deleteLecture(lectureId);
      if (res["success"] == true) {
        deletedCount++;
      } else {
        failedCount++;
      }
    }

    if (!mounted) return;

    await _loadLectures();
    if (!mounted) return;

    if (failedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deleted $deletedCount lecture(s)")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Deleted $deletedCount lecture(s), failed to delete $failedCount.",
          ),
        ),
      );
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return "Good morning ☀️";
    if (hour < 17) return "Good afternoon 🌤️";
    return "Good evening 🌙";
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return "Today, ${DateFormat('h:mm a').format(date)}";
      } else if (difference.inDays == 1) {
        return "Yesterday, ${DateFormat('h:mm a').format(date)}";
      } else {
        return DateFormat('d MMM, h:mm a').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    String namePref = userEmail?.split('@')[0] ?? "User";
    String name =
        namePref[0].toUpperCase() +
        namePref.substring(1).replaceAll(RegExp(r'[^a-zA-Z]'), ' ');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: RefreshIndicator(
        onRefresh: _loadLectures,
        color: const Color(0xFF1E3A8A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(
                greeting: _getGreeting(),
                name: name,
                lecturesCount: _lectures.length,
                onProfileTap: () => _showProfileMenu(context),
                onNotesTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotesScreen(),
                    ),
                  ).then((_) => _loadLectures());
                },
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StartLectureCard(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => LectureDialog(
                            onStart: (title, code, instructor) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SpeechScreen(
                                    lectureTitle: title,
                                    courseCode: code,
                                    instructor: instructor,
                                  ),
                                ),
                              ).then((_) => _loadLectures());
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    QuickActionsRow(
                      onAiAssistantTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AiAssistantScreen(),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      onStyleTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => StyleDialog(
                            initialStyles: _selectedStyles,
                            onApply: (List<String> styles) async {
                              await StyleService.saveStyles(styles);
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    RecentLecturesList(
                      isLoading: _isLoading,
                      lectures: _lectures,
                      onDelete: _deleteLecture,
                      onDeleteAll: _deleteAllLectures,
                      onTap: (lectureId) async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LectureDetailScreen(lectureId: lectureId),
                          ),
                        );
                        if (mounted) {
                          _loadLectures();
                        }
                      },
                      formatDate: _formatDate,
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF3B82F6),
                    child: Text(
                      userEmail?[0].toUpperCase() ?? "U",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userEmail?.split('@')[0].toUpperCase() ?? "USER",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          userEmail ?? "",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const SizedBox(height: 32),
              _buildBottomSheetItem(Icons.logout_rounded, "Sign Out", () async {
                await StyleService.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              }, isDanger: true),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDanger = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDanger
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDanger ? Colors.redAccent : const Color(0xFF1F2937),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDanger ? Colors.redAccent : const Color(0xFF1F2937),
          fontSize: 15,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey[300],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}
