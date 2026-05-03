import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1:8000";
    if (Platform.isAndroid) {
      return "http://192.168.100.199:8000"; // Use this for Android Emulator
      //return "http://192.168.18.65:8000"; // Use this for Physical Device
    }
    if (Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux) {
      return "http://127.0.0.1:8000";
    }
    return "http://192.168.100.58:8000"; // Fallback / real device
  }

  /// ================= SIGNUP =================
  static Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/signup"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );

    return _handleResponse(response);
  }

  /// ================= LOGIN =================
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    return _handleResponse(response);
  }

  /// ================= FORGOT PASSWORD =================
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return _handleResponse(response);
  }

  /// ================= RESET PASSWORD =================
  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "otp": otp,
        "new_password": newPassword,
      }),
    );

    return _handleResponse(response);
  }

  /// ================= CHAT =================
  static Future<Map<String, dynamic>> chat({
    required String prompt,
    required String email,
    required String chatId,
    List<Map<String, String>> history = const [],
    List<String> styles = const ["short"],
    bool codeRequest = false,
    bool onlyCode = false,
    String? language,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "prompt": prompt,
        "email": email,
        "chat_id": chatId,
        "history": history,
        "styles": styles,
        "code_request": codeRequest,
        "only_code": onlyCode,
        "language": language,
      }),
    );

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getChats(String email) async {
    final response = await http.get(Uri.parse("$baseUrl/chats/$email"));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getChatHistory(String chatId) async {
    final response = await http.get(Uri.parse("$baseUrl/chat-history/$chatId"));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> newChat(String email) async {
    final response = await http.post(
      Uri.parse("$baseUrl/new-chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> clearChats(String email) async {
    final response = await http.delete(Uri.parse("$baseUrl/chats/$email"));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteChat(String chatId) async {
    final response = await http.delete(Uri.parse("$baseUrl/chat/$chatId"));
    return _handleResponse(response);
  }

  /// ================= LECTURES =================
  static Future<Map<String, dynamic>> saveLecture({
    required String email,
    required String title,
    String? courseCode,
    String? instructor,
    required String transcript,
    String? lecturePrompt,
    String? aiResponse,
    String? aiTitle,
    String? chatId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/lectures"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "title": title,
        "course_code": courseCode,
        "instructor": instructor,
        "transcript": transcript,
        "lecture_prompt": lecturePrompt,
        "ai_response": aiResponse,
        "ai_title": aiTitle,
        "chat_id": chatId,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateLectureAiResponse({
    required String lectureId,
    required String aiResponse,
    String? lecturePrompt,
    String? aiTitle,
    String? chatId,
  }) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/lecture/$lectureId/ai-response"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "ai_response": aiResponse,
        "lecture_prompt": lecturePrompt,
        "ai_title": aiTitle,
        "chat_id": chatId,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getLectures(String email) async {
    final response = await http.get(Uri.parse("$baseUrl/lectures/$email"));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getLectureDetail(String lectureId) async {
    final response = await http.get(Uri.parse("$baseUrl/lecture/$lectureId"));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteLecture(String lectureId) async {
    final response = await http.delete(Uri.parse("$baseUrl/lecture/$lectureId"));
    return _handleResponse(response);
  }

  /// ================= COMMON RESPONSE HANDLER =================
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {"success": true, "data": data};
    } else {
      return {
        "success": false,
        "error": data["detail"] ?? data["error"] ?? "Something went wrong",
      };
    }
  }
}
