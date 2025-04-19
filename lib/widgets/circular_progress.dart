// Displays a circular progress bar - used for goal progress widget

import 'package:flutter/material.dart';
import 'dart:math';

class ThickCircularProgress extends StatelessWidget {
  // Progress as a value between 0 and 1
  final double progress;
  final double completedStrokeWidth;
  final double backgroundStrokeWidth;
  final Color completedColor;
  final Color backgroundColor;
  final double size;

  const ThickCircularProgress({
    required this.progress,
    this.completedStrokeWidth = 10.0,
    this.backgroundStrokeWidth = 4.0,
    required this.completedColor,
    required this.backgroundColor,
    required this.size,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: CircularProgressPainter(
        progress: progress,
        completedStrokeWidth: completedStrokeWidth,
        backgroundStrokeWidth: backgroundStrokeWidth,
        completedColor: completedColor,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

// Custom painter for circles used in progress indicator
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double completedStrokeWidth;
  final double backgroundStrokeWidth;
  final Color completedColor;
  final Color backgroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.completedStrokeWidth,
    required this.backgroundStrokeWidth,
    required this.completedColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - max(completedStrokeWidth, backgroundStrokeWidth)/2;

    // Draw the background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = backgroundStrokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw the completed arc
    final completedPaint = Paint()
      ..color = completedColor
      ..strokeWidth = completedStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Optional: Rounded ends
    final sweepAngle = progress * 2 * 3.14159265359;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265359 / 2, // Start angle (top of the circle)
      sweepAngle,
      false,
      completedPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
