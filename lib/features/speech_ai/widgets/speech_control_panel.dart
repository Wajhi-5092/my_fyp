import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';

class SpeechControlPanel extends StatelessWidget {
  final bool isListening;
  final bool isNoiseCancelEnabled;
  final bool showActionButtons;
  final VoidCallback onToggleListening;
  final VoidCallback onToggleNoiseCancel;
  final VoidCallback onRetry;
  final VoidCallback onProceed;

  const SpeechControlPanel({
    super.key,
    required this.isListening,
    required this.isNoiseCancelEnabled,
    required this.showActionButtons,
    required this.onToggleListening,
    required this.onToggleNoiseCancel,
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildActionBtn(
                      label: "RETRY",
                      color: Colors.redAccent,
                      onTap: onRetry,
                      isOutline: true,
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: _buildMicButton(showText: false, small: true),
                  ),
                  Expanded(
                    flex: 5,
                    child: _buildActionBtn(
                      label: "PROCEED",
                      color: const Color(0xFFFFB300),
                      onTap: onProceed,
                      isOutline: false,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Expanded(child: SizedBox()), // Balance spacer
                  _buildMicButton(showText: true, small: false),
                  Expanded(
                    child: Center(
                      child: _buildNoiseCancelToggle(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoiseCancelToggle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onToggleNoiseCancel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isNoiseCancelEnabled
                  ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: isNoiseCancelEnabled
                    ? const Color(0xFFFFB300).withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              isNoiseCancelEnabled ? Icons.graphic_eq : Icons.multiline_chart,
              color:
                  isNoiseCancelEnabled ? const Color(0xFFFFB300) : Colors.grey,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "NOISE CANCEL",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: isNoiseCancelEnabled ? const Color(0xFFFFB300) : Colors.grey,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildMicButton({required bool showText, required bool small}) {
    final double size = small ? 60 : 80;
    final double iconSize = small ? 28 : 38;

    return Column(
      mainAxisSize: MainAxisSize.min,
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
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isListening
                      ? [const Color(0xFFFFB300), const Color(0xFFFF8F00)]
                      : [Colors.grey.shade800, Colors.grey.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isListening
                        ? const Color(0xFFFFB300).withValues(alpha: 0.4)
                        : Colors.black45,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.pause : Icons.mic,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
        if (showText) ...[
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
        ] else ...[
          const SizedBox(height: 8),
          Text(
            "RESUME",
            style: TextStyle(
              color: const Color.fromARGB(255, 7, 7, 7).withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionBtn({
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isOutline,
  }) {
    return InkWell(
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
              fontSize: 13,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}
