import 'package:flutter/material.dart';

class LectureDialog extends StatefulWidget {
  final Function(String title, String code, String instructor) onStart;

  const LectureDialog({super.key, required this.onStart});

  @override
  State<LectureDialog> createState() => _LectureDialogState();
}

class _LectureDialogState extends State<LectureDialog> {
  final _titleController = TextEditingController();
  final _codeController = TextEditingController();
  final _instructorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _titleFocus = FocusNode();
  final _codeFocus = FocusNode();
  final _instructorFocus = FocusNode();

  bool get _isValid => _titleController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    _titleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _instructorController.dispose();

    _titleFocus.dispose();
    _codeFocus.dispose();
    _instructorFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(
                  Icons.mic_none_rounded,
                  color: Color(0xFF2563EB),
                  size: 28,
                ),
                SizedBox(width: 10),
                Text(
                  "Start Lecture",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              "Add details to organize your lecture notes better",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),

        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 8),

                _buildCardField(
                  controller: _titleController,
                  focusNode: _titleFocus,
                  label: "Lecture Title *",
                  hint: "e.g. Introduction to AI",
                  icon: Icons.title_rounded,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? "Required" : null,
                ),

                const SizedBox(height: 12),

                _buildCardField(
                  controller: _codeController,
                  focusNode: _codeFocus,
                  label: "Course Code",
                  hint: "e.g. CS101",
                  icon: Icons.code_rounded,
                ),

                const SizedBox(height: 12),

                _buildCardField(
                  controller: _instructorController,
                  focusNode: _instructorFocus,
                  label: "Instructor",
                  hint: "e.g. Prof. Smith",
                  icon: Icons.person_outline_rounded,
                ),
              ],
            ),
          ),
        ),

        actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),

        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isValid
                        ? const Color(0xFF2563EB)
                        : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isValid
                      ? () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            widget.onStart(
                              _titleController.text.trim(),
                              _codeController.text.trim(),
                              _instructorController.text.trim(),
                            );
                          }
                        }
                      : null,
                  child: const Text(
                    "Start Lecture",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: focusNode.hasFocus
            ? const Color(0xFFEFF6FF)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: focusNode.hasFocus
              ? const Color(0xFF2563EB)
              : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        validator: validator,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
