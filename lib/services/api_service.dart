import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return "http://192.168.100.58:8000"; // Web must use LAN IP
    if (Platform.isAndroid)return "http://10.0.2.2:8000"; // Android emulator / MuMu
    if (Platform.isIOS) return "http://localhost:8000"; // iOS simulator
    return "http://192.168.100.58:8000"; // Fallback / real device
  }

  static Future<String> generate(String prompt) async {
    final response = await http.post(
      Uri.parse("$baseUrl/generate"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"prompt": prompt}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["text"];
    } else {
      throw Exception(
        "Failed to generate content: ${response.statusCode} ${response.body}",
      );
    }
  }
}
