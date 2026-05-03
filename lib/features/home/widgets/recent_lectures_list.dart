import 'package:flutter/material.dart';
import 'recent_lecture_item.dart';

class RecentLecturesList extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> lectures;
  final Function(Map<String, dynamic>) onDelete;
  final Function(String) onTap;
  final String Function(String) formatDate;

  const RecentLecturesList({
    super.key,
    required this.isLoading,
    required this.lectures,
    required this.onDelete,
    required this.onTap,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (lectures.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.history_outlined,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Text(
                  "No recent lectures yet",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          ...lectures.take(5).map(
                (lec) => RecentLectureItem(
                  title: lec["title"] ?? "Untitled",
                  subtitle:
                      "${formatDate(lec["created_at"]?.toString() ?? '')} · ${lec["course_code"] ?? lec["instructor"] ?? "No details"}${((lec["ai_response"] ?? "").toString().trim().isNotEmpty) ? " · AI ready" : ""}",
                  icon: Icons.auto_awesome,
                  onDelete: () => onDelete(lec),
                  onTap: () {
                    final lectureId = lec["lecture_id"]?.toString() ?? "";
                    if (lectureId.isNotEmpty) {
                      onTap(lectureId);
                    }
                  },
                ),
              ),
      ],
    );
  }
}
