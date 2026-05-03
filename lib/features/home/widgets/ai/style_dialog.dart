import 'package:flutter/material.dart';

class StyleDialog extends StatefulWidget {
  final List<String> initialStyles;
  final Function(List<String>) onApply;

  const StyleDialog({
    super.key,
    required this.initialStyles,
    required this.onApply,
  });

  @override
  State<StyleDialog> createState() => _StyleDialogState();
}

class _StyleDialogState extends State<StyleDialog> {
  late List<String> tempSelected;

  final List<String> allStyles = [
    "Short",
    "Descriptive",
    "Long",
    "Professional",
    "Bulletpoints",
  ];

  @override
  void initState() {
    super.initState();
    tempSelected = List.from(widget.initialStyles);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      // TITLE
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(
                227,
                61,
                80,
                225,
              ).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color.fromARGB(255, 9, 52, 112),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Response Style",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Color.fromARGB(255, 0, 0, 0),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "How should the AI talk to you?",
            style: TextStyle(
              fontSize: 14,
              color: Color.fromARGB(153, 0, 0, 0),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),

      // CONTENT
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: allStyles.map((style) {
              final isSelected = tempSelected.contains(style.toLowerCase());

              return FilterChip(
                label: Text(style),
                selected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      tempSelected.add(style.toLowerCase());
                    } else {
                      tempSelected.remove(style.toLowerCase());
                    }
                  });
                },
                showCheckmark: true,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.black87
                      : const Color.fromARGB(179, 0, 0, 0),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                  fontSize: 15,
                ),
                selectedColor: const Color.fromARGB(167, 69, 163, 245),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              );
            }).toList(),
          ),
        ),
      ),

      // ACTIONS
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Color.fromARGB(249, 0, 0, 0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  widget.onApply(tempSelected);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Apply",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
