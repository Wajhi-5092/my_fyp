import 'package:flutter/material.dart';
import '../../../core/services/style_service.dart';
import '../widgets/style_dialog.dart';
import '../../speech_ai/screens/speech_screen.dart';
import 'ai_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../widgets/stat_card.dart';
import '../widgets/recent_lecture_item.dart';
import '../widgets/lecture_dialog.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/api_service.dart';
import 'package:intl/intl.dart';

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER SECTION
            Container(
              padding: const EdgeInsets.only(
                top: 60,
                left: 24,
                right: 24,
                bottom: 40,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF141F46), Color(0xFF1E3A8A)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getGreeting(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Serif',
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showProfileMenu(context),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF3B82F6),
                          child: Text(
                            name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  /// STATS ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StatCard(value: _lectures.length.toString(), label: "Lectures"),
                      const StatCard(value: "38", label: "AI Notes"),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// START NEW LECTURE CARD
                  GestureDetector(
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
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Start New Lecture",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  "Record, transcribe & generate AI notes",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// QUICK ACTIONS
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSmallActionCard(
                          context,
                          "AI Assistant",
                          Icons.auto_awesome,
                          Colors.green,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AiAssistantScreen(),
                            ),
                          ).then((_) => setState(() {})),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSmallActionCard(
                          context,
                          "Select Style",
                          Icons.style,
                          Colors.orange,
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
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  /// RECENT LECTURES SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recent Lectures",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Row(
                          children: [
                            Text("See all"),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_lectures.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.history_outlined, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            "No recent lectures yet",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._lectures.take(5).map((lec) => RecentLectureItem(
                          title: lec["title"] ?? "Untitled",
                          subtitle: "${_formatDate(lec["created_at"])} · ${lec["course_code"] ?? lec["instructor"] ?? "No details"}",
                          icon: Icons.mic_rounded,
                          onTap: () async {
                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(child: CircularProgressIndicator()),
                            );

                            try {
                              final detailRes = await ApiService.getLectureDetail(lec["lecture_id"]);
                              if (context.mounted) Navigator.pop(context); // hide loading

                              if (detailRes["success"] == true) {
                                final data = detailRes["data"];
                                await PdfService.generateAndOpenLecturePdf(
                                  title: data["title"] ?? "Untitled",
                                  courseCode: data["course_code"],
                                  instructor: data["instructor"],
                                  transcript: data["transcript"] ?? "",
                                  date: _formatDate(data["created_at"]),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context); // hide loading if still there
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error opening PDF: $e")),
                                );
                              }
                            }
                          },
                        )),
                  const SizedBox(height: 20),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
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

  Widget _buildSmallActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
