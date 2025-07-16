import 'package:flutter/material.dart';

class ColorUtils {
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Common opacity values as constants
  static const double opacity05 = 0.05;
  static const double opacity07 = 0.07;
  static const double opacity10 = 0.1;
  static const double opacity13 = 0.13;
  static const double opacity18 = 0.18;
  static const double opacity20 = 0.2;
  static const double opacity30 = 0.3;
  static const double opacity50 = 0.5;
  static const double opacity60 = 0.6;
  static const double opacity70 = 0.7;
  static const double opacity80 = 0.8;

  /// Predefined colors with common opacity values
  static Color blackWithOpacity05 = Colors.black.withValues(alpha: opacity05);
  static Color blackWithOpacity20 = Colors.black.withValues(alpha: opacity20);
  static Color whiteWithOpacity70 = Colors.white.withValues(alpha: opacity70);
  static Color whiteWithOpacity80 = Colors.white.withValues(alpha: opacity80);

  /// IITD OAE brand colors with opacity
  static Color primaryWithOpacity05 = const Color(
    0xFF2A2075,
  ).withValues(alpha: opacity05);
  static Color primaryWithOpacity07 = const Color(
    0xFF2A2075,
  ).withValues(alpha: opacity07);
  static Color primaryWithOpacity10 = const Color(
    0xFF2A2075,
  ).withValues(alpha: opacity10);
  static Color primaryWithOpacity13 = const Color(
    0xFF2A2075,
  ).withValues(alpha: opacity13);
  static Color primaryWithOpacity18 = const Color(
    0xFF2A2075,
  ).withValues(alpha: opacity18);
  static Color primaryWithOpacity30 = const Color(
    0xFF2A2075,
  ).withValues(alpha: opacity30);
  static Color primaryWithOpacity60 = const Color(
    0xFF2A2075,
  ).withValues(alpha: opacity60);
  static Color primaryWithOpacity70 = const Color(
    0xFF2A2075,
  ).withValues(alpha: opacity70);

  static Color grayWithOpacity60 = const Color(
    0xFF666666,
  ).withValues(alpha: opacity60);
  static Color grayWithOpacity70 = const Color(
    0xFF666666,
  ).withValues(alpha: opacity70);
}
