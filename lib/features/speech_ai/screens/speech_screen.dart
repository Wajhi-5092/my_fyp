import 'package:flutter/material.dart';
import '../../home/screens/ai_screen.dart';
import '../services/speech_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/style_service.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../widgets/speech_text_area.dart';
import '../widgets/speech_control_panel.dart';

class SpeechScreen extends StatefulWidget {
  final String? lectureTitle;
  final String? courseCode;
  final String? instructor;

  const SpeechScreen({
    super.key,
    this.lectureTitle,
    this.courseCode,
    this.instructor,
  });

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  final SpeechService _speechService = SpeechService();
  final TextEditingController _textController = TextEditingController(
    text: 'Tap the microphone to start listening...',
  );
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  bool _isRestarting = false;
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _startListening() async {
    if (_isRestarting && _isListening) return;
    _isRestarting = true;

    final available = await _speechService.init();

    if (available && mounted) {
      setState(() {
        _isListening = true;

        _isRestarting = false;
        if (_textController.text ==
            'Tap the microphone to start listening...') {
          _textController.clear();
          _previousText = '';
        } else {
          _previousText = _textController.text.trim();
        }
      });

      await _speechService.startListening((words) {
        if (!mounted) return;
        setState(() {
          String separator = _previousText.isNotEmpty && words.isNotEmpty
              ? ' '
              : '';
          _textController.text = _previousText + separator + words;
        });
        _scrollToBottom();
      });
    } else {
      setState(() => _isRestarting = false);
    }
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      await _startListening();
    } else {
      await _speechService.stopListening();
      setState(() => _isListening = false);
    }
  }

  void _handleRetry() {
    setState(() {
      _textController.text = 'Tap the microphone to start listening...';
      _previousText = '';
    });
  }

  Future<void> _handleProceed() async {
    final email = StyleService.currentUserEmail;
    if (email != null) {
      final res = await ApiService.saveLecture(
        email: email,
        title: widget.lectureTitle ?? "Untitled Lecture",
        courseCode: widget.courseCode,
        instructor: widget.instructor,
        transcript: _textController.text,
      );

      if (res["success"] == true) {
        final lectureId = res["data"]?["lecture_id"]?.toString();
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            "Lecture saved successfully!",
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AiAssistantScreen(
                initialPrompt: _textController.text,
                lectureId: lectureId,
                persistInitialResponseToLecture: true,
              ),
            ),
          );
        }
      } else {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            res["error"] ?? "Failed to save lecture",
            isError: true,
          );
        }
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AiAssistantScreen(
            initialPrompt: _textController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showActionButtons = _textController.text.isNotEmpty &&
        !_isListening &&
        _textController.text != 'Tap the microphone to start listening...';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.lectureTitle ?? "Voice Assistant",
          style: const TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SpeechTextArea(
                textController: _textController,
                scrollController: _scrollController,
                isListening: _isListening,
              ),
            ),
            SpeechControlPanel(
              isListening: _isListening,
              showActionButtons: showActionButtons,
              onToggleListening: _toggleListening,
              onRetry: _handleRetry,
              onProceed: _handleProceed,
            ),
          ],
        ),
      ),
    );
  }
}
