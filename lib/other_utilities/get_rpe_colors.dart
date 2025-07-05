import 'package:flutter/material.dart';

Color getRpeColor(double rpe, BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  
  // Base colors that work well in both modes
  if (rpe <= 6) return isDark ? Colors.lightGreen : Colors.green.shade700;      // Easy
  if (rpe <= 7) return isDark ? Colors.lightBlue : Colors.blue.shade700;        // Moderate
  if (rpe <= 8) return isDark ? Colors.amber : Colors.orange.shade700;          // Challenging
  if (rpe <= 9) return isDark ? Colors.deepOrange : Colors.deepOrange.shade700; // Hard
  return isDark ? Colors.redAccent : Colors.red.shade700;                       // Max effort
}