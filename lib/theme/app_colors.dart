import 'package:flutter/material.dart';

class AppColors {
  // ── BRAND PALETTE ──
  static const Color primarySeed = Color(0xFF1A2D5A); // Deep corporate blue
  static const Color darkSlate = Color(
    0xFF0F1B35,
  ); // Soft midnight shadow & main text color
  static const Color accentOrange = Color(0xFFF97316); // Brand primary orange
  static const Color accentOrangeLight = Color(
    0xFFFB923C,
  ); // Brand soft orange highlight
  static const Color accentViolet = Color(0xFF6366F1); // Violet secondary
  static const Color accentVioletLight = Color(0xFF818CF8); // Violet highlight

  // ── THEME SCAFFOLD & CARDS ──
  static const Color lightScaffold = Color(0xFFF4F5F8);
  static const Color lightCard = Colors.white;
  static const Color darkScaffold = Color(0xFF0B0F19); // Obsidian
  static const Color darkCard = Color(0xFF151B2D); // Midnight Navy

  // ── SLATE / NEUTRAL SPECTRUM ──
  static const Color slate50 = Color(0xFFF8F9FB);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8); // Subtitle dark mode
  static const Color slate600 = Color(0xFF6B7A99); // Subtitle light mode
  static const Color slate700 = Color(0xFF334155); // Dark track background
  static const Color slate800 = Color(0xFF1E293B); // Dark divider / modal bg
  static const Color slate900 = Color(0xFF0F172A);

  // ── INDIGO PALETTE ──
  static const Color indigoAccent = Color(0xFF4338CA); // Card Indigo Accent
  static const Color indigoBg = Color(0xFF312E81); // Card Indigo Background

  // ── STATUS & CATEGORY PALETTE ──
  // Green / Income / Positive Growth
  static const Color greenAccent = Color(0xFF16A34A);
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color greenGrowth = Color(
    0xFF4ADE80,
  ); // Pastel green for positive growth badge

  // Red / Dining / Expense
  static const Color redAccent = Color(0xFFDC2626);
  static const Color redBg = Color(0xFFFEE2E2);

  // Yellow / Food
  static const Color yellowAccent = Color(0xFFD97706);
  static const Color yellowBg = Color(0xFFFEF3C7);

  // Purple / Transport
  static const Color purpleAccent = Color(0xFF7C3AED);
  static const Color purpleBg = Color(0xFFEDE9FE);

  // Sky Blue / Others
  static const Color blueAccent = Color(0xFF0284C7);
  static const Color blueBg = Color(0xFFE0F2FE);

  // Custom interface dark support color
  static const Color darkInterfaceColor = Color(0xFF222E45);
  static const Color darkBorderColor = Color(0xFF2E3B52);
  static const Color darkBarBg = Color(0xFF223047); // Dark bar chart background
  static const Color darkBarFg = Color(0xFF2A3A54); // Dark bar chart foreground
}
