import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  static const String _prefKey = "app_theme_mode";

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString(_prefKey);
    themeMode.value = (saved == "dark") ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode == ThemeMode.dark ? "dark" : "light");
  }
}
