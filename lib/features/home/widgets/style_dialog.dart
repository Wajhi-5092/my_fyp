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
  ];

  @override
  void initState() {
    super.initState();
    tempSelected = List.from(widget.initialStyles);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      title: const Column(
        children: [
          Icon(Icons.auto_awesome, color: Color(0xFFFFB300), size: 30),
          SizedBox(height: 10),
          Text(
            "Response Style",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          Text(
            "How should the AI talk to you?",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white54,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: allStyles.map((style) {
            final isSelected = tempSelected.contains(style.toLowerCase());
            return FilterChip(
              label: Text(style),
              selected: isSelected,
              showCheckmark: true,
              selectedColor: const Color(0xFFFFB300).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFFFFB300),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFFFB300) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFFFFB300)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    tempSelected.add(style.toLowerCase());
                  } else {
                    tempSelected.remove(style.toLowerCase());
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white54),
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: const Color(0xFF0F111A),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
