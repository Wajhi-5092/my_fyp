import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StyleService {
  static const String _key = 'selected_styles';
  static const String _userEmailKey = 'user_email';
  static List<String> _selectedStyles = [];
  static String? _currentUserEmail;
  
  // Broadcast logout events globally
  static final ValueNotifier<bool> logoutNotifier = ValueNotifier<bool>(false);

  static List<String> get selectedStyles => _selectedStyles;
  static String? get currentUserEmail => _currentUserEmail;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedStyles = prefs.getStringList(_key) ?? ["short"];
    _currentUserEmail = prefs.getString(_userEmailKey);
  }

  static Future<void> saveStyles(List<String> styles) async {
    final prefs = await SharedPreferences.getInstance();
    _selectedStyles = styles;
    await prefs.setStringList(_key, styles);
  }

  static Future<void> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = email;
    await prefs.setString(_userEmailKey, email);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = null;
    await prefs.remove(_userEmailKey);
  }
}
