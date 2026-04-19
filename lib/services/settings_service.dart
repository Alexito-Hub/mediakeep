import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app settings
class SettingsService {
  static const String _themeKey = 'theme_mode';
  static const String _shareMessageKey = 'share_message';
  static const String _onboardingKey = 'has_completed_onboarding';
  static const String _tutorialKey = 'has_completed_tutorial';
  static const String _defaultShareMessage = 'Descargado con MediaKeep';

  /// Get current theme mode
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? 'system';

    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Set theme mode
  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeString;

    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }

    await prefs.setString(_themeKey, themeString);
  }

  /// Get custom share message
  static Future<String> getShareMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_shareMessageKey) ?? _defaultShareMessage;
  }

  /// Set custom share message
  static Future<void> setShareMessage(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_shareMessageKey, message);
  }

  /// Reset share message to default
  static Future<void> resetShareMessage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_shareMessageKey, _defaultShareMessage);
  }

  /// Get default share message
  static String get defaultShareMessage => _defaultShareMessage;

  /// Check if user has completed the onboarding flow
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Mark onboarding flow as completed
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  // --- TUTORIAL ---
  static Future<bool> hasCompletedTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialKey) ?? false; // false = haven't done it yet
  }

  static Future<void> completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
  }
}
