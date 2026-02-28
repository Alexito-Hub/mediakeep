import 'package:flutter/material.dart';

/// Platform configuration data
class PlatformConfig {
  final String name;
  final String displayName;
  final IconData icon;
  final Color color;
  final Color badgeColor;
  final String? iconAsset; // Optional SVG or image path for future

  const PlatformConfig({
    required this.name,
    required this.displayName,
    required this.icon,
    required this.color,
    required this.badgeColor,
    this.iconAsset,
  });
}

/// Centralized platform configurations
class PlatformConfigs {
  static const Map<String, PlatformConfig> platforms = {
    'tiktok': PlatformConfig(
      name: 'tiktok',
      displayName: 'TikTok',
      icon: Icons.music_note,
      color: Color(0xFFEE1D52),
      badgeColor: Color(0xFFEE1D52),
    ),
    'facebook': PlatformConfig(
      name: 'facebook',
      displayName: 'Facebook',
      icon: Icons.facebook,
      color: Color(0xFF1877F2),
      badgeColor: Color(0xFF1877F2),
    ),
    'spotify': PlatformConfig(
      name: 'spotify',
      displayName: 'Spotify',
      icon: Icons.audiotrack,
      color: Color(0xFF1DB954),
      badgeColor: Color(0xFF1DB954),
    ),
    'threads': PlatformConfig(
      name: 'threads',
      displayName: 'Threads',
      icon: Icons.alternate_email,
      color: Colors.black,
      badgeColor: Colors.black,
    ),
    'youtube': PlatformConfig(
      name: 'youtube',
      displayName: 'YouTube',
      icon: Icons.play_circle_filled,
      color: Color(0xFFFF0000),
      badgeColor: Color(0xFFFF0000),
    ),
    'bilibili': PlatformConfig(
      name: 'bilibili',
      displayName: 'Bilibili',
      icon: Icons.live_tv,
      color: Color(0xFF00A1D6),
      badgeColor: Color(0xFF00A1D6),
    ),
    'instagram': PlatformConfig(
      name: 'instagram',
      displayName: 'Instagram',
      icon: Icons.camera_alt,
      color: Color(0xFFE4405F),
      badgeColor: Color(0xFFE4405F),
    ),
    'twitter': PlatformConfig(
      name: 'twitter',
      displayName: 'Twitter',
      icon: Icons.tag,
      color: Color(0xFF1DA1F2),
      badgeColor: Color(0xFF1DA1F2),
    ),
  };

  /// Get platform config by name
  static PlatformConfig? getConfig(String platform) {
    return platforms[platform.toLowerCase()];
  }

  /// Get all platform names
  static List<String> getAllPlatformNames() {
    return platforms.keys.toList();
  }

  /// Get icon for platform (with fallback)
  static IconData getIcon(String platform, {bool isDark = false}) {
    final config = getConfig(platform);
    return config?.icon ?? Icons.link_rounded;
  }

  /// Get color for platform (with fallback)
  static Color getColor(String platform, {bool isDark = false}) {
    final config = getConfig(platform);
    if (config == null) return Colors.grey;

    // Special handling for black icons in dark mode
    if (config.color == Colors.black && isDark) {
      return Colors.white;
    }
    return config.color;
  }

  /// Get badge color for platform
  static Color getBadgeColor(String platform) {
    final config = getConfig(platform);
    return config?.badgeColor ?? Colors.grey;
  }

  /// Get display name for platform
  static String getDisplayName(String platform) {
    final config = getConfig(platform);
    return config?.displayName ?? platform.toUpperCase();
  }
}
