import 'package:flutter/material.dart';

/// Responsive helper class for adaptive layouts
class Responsive {
  /// Mobile breakpoint (< 600px)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  /// Tablet breakpoint (600px - 1200px)
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  /// Desktop breakpoint (>= 1200px)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  /// Get maximum width constraint based on screen size
  static double getMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1400;
    if (isTablet(context)) return 1000;
    return double.infinity;
  }

  /// Standard desktop inner-content padding used across all screens.
  static const EdgeInsets kDesktop = EdgeInsets.symmetric(
    horizontal: 40,
    vertical: 32,
  );

  /// Get content padding based on screen size
  static EdgeInsets getContentPadding(BuildContext context) {
    if (isDesktop(context)) return kDesktop;
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  /// Get number of grid columns based on screen size
  static int getGridColumns(
    BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  /// Responsive value based on screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }
}
