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

  /// ================= GENERATE =================
  static Future<String> generate(String prompt) async {
    final response = await http.post(
      Uri.parse("$baseUrl/generate"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"prompt": prompt}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["text"] ?? "";
    } else {
      final error = _parseError(response);
      throw Exception(error);
    }
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

  static String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data["detail"] ?? data["error"] ?? "Server Error";
    } catch (_) {
      return "Server Error ${response.statusCode}";
    }
  }
}
