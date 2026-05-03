import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';

class SpeechControlPanel extends StatelessWidget {
  final bool isListening;
  final bool showActionButtons;
  final VoidCallback onToggleListening;
  final VoidCallback onRetry;
  final VoidCallback onProceed;

  const SpeechControlPanel({
    super.key,
    required this.isListening,
    required this.showActionButtons,
    required this.onToggleListening,
    required this.onRetry,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showActionButtons)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionBtn(
                    label: "RETRY",
                    color: Colors.redAccent,
                    onTap: onRetry,
                    isOutline: true,
                  ),
                  const SizedBox(width: 20),
                  _buildActionBtn(
                    label: "PROCEED",
                    color: const Color(0xFFFFB300),
                    onTap: onProceed,
                    isOutline: false,
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                AvatarGlow(
                  animate: isListening,
                  glowColor: const Color(0xFFFFB300),
                  duration: const Duration(milliseconds: 2000),
                  repeat: true,
                  child: GestureDetector(
                    onTap: onToggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isListening
                              ? [
                                  const Color(0xFFFFB300),
                                  const Color(0xFFFF8F00),
                                ]
                              : [
                                  Colors.grey.shade800,
                                  Colors.grey.shade900,
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isListening
                                ? const Color(
                                    0xFFFFB300,
                                  ).withValues(alpha: 0.4)
                                : Colors.black45,
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  isListening ? "Listening..." : "Tap to Speak",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isOutline,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isOutline ? color.withValues(alpha: 0.1) : null,
            gradient: isOutline
                ? null
                : LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
            borderRadius: BorderRadius.circular(30),
            border: isOutline ? Border.all(color: color, width: 1.5) : null,
            boxShadow: isOutline
                ? []
                : [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0F111A),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
