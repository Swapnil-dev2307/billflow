import 'package:flutter/material.dart';

/// Corporate & Vibrant Palette for BillFlow Smart Billing App
class AppColors {
  // Primary Palette (Deep Navy / Royal Tech)
  static const Color primary = Color(0xFF1E293B);      // Slate 800
  static const Color primaryDark = Color(0xFF0F172A);  // Slate 900
  static const Color primaryLight = Color(0xFF334155); // Slate 700

  // Accent / Action Colors
  static const Color accent = Color(0xFF2563EB);       // Indigo Blue
  static const Color accentHover = Color(0xFF1D4ED8);
  
  // Financial & Status Colors
  static const Color success = Color(0xFF10B981);      // Emerald Green (Paid / Positive)
  static const Color warning = Color(0xFFF59E0B);      // Amber (Low Stock / Partial)
  static const Color danger = Color(0xFFEF4444);       // Coral Red (Unpaid / Out of Stock)
  static const Color info = Color(0xFF06B6D4);         // Cyan

  // Surface & Backgrounds
  static const Color background = Color(0xFFF8FAFC);   // Off-white / Cool Grey
  static const Color cardBackground = Colors.white;
  static const Color surfaceMuted = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color inputBorder = Color(0xFFCBD5E1);

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardHeaderGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
