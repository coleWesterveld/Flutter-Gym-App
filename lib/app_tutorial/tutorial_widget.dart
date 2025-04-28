// this is the tooltip that comes up during the tutorial 
import 'package:firstapp/providers_and_settings/ui_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'app_tutorial_keys.dart';
import '../main.dart'; // Access MainScaffoldState
import '../workout_page/workout_selection_page.dart'; // Access WorkoutSelectionPageState
import 'package:provider/provider.dart';
import 'package:firstapp/providers_and_settings/settings_provider.dart';
import 'package:firstapp/app_tutorial/tutorial_manager.dart';
import 'package:firstapp/providers_and_settings/settings_page.dart';
// lib/app_tutorial/tutorial_widget.dart
// lib/app_tutorial/tutorial_widget.dart
// lib/app_tutorial/tutorial_widget.dart

import 'package:flutter/material.dart';
import 'package:firstapp/app_tutorial/tutorial_manager.dart';

/// A little “speech bubble” tooltip with Skip/Next buttons.
class TutorialWidget extends StatelessWidget {
  final String text;
  final TutorialManager manager;

  const TutorialWidget({
    Key? key,
    required this.text,
    required this.manager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We'll let Showcase.withWidget(width:…) decide the bubble width.
    // Internally we just cap at 80% of screen to avoid crazy over‐wide bubbles.
    final maxWidth = MediaQuery.of(context).size.width * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: SpeechBubble(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: manager.skipTutorial,
                        child: const Text("Skip"),
                      ),
                      TextButton(
                        onPressed: manager.advanceStep,
                        child: const Text("Next"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a white rounded‐rect plus a little triangular arrow
/// centered on the bottom edge.
class SpeechBubble extends StatelessWidget {
  final Widget child;
  final double arrowSize;
  final double borderRadius;
  final double borderWidth;

  const SpeechBubble({
    Key? key,
    required this.child,
    this.arrowSize = 12,
    this.borderRadius = 12,
    this.borderWidth = 1.5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(
        arrowSize: arrowSize,
        borderRadius: borderRadius,
        borderWidth: borderWidth,
      ),
      child: Padding(
        // We pad the bottom so content doesn’t overlap the arrow
        padding: EdgeInsets.only(bottom: arrowSize),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final double arrowSize;
  final double borderRadius;
  final double borderWidth;

  _BubblePainter({
    required this.arrowSize,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bubbleHeight = size.height - arrowSize;
    final fill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // 1) Rounded rectangle
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, bubbleHeight),
      Radius.circular(borderRadius),
    );
    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);

    // 2) Arrow: a triangle centered on the bottom edge
    final path = Path()
      ..moveTo(size.width * 0.5 - arrowSize, bubbleHeight)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(size.width * 0.5 + arrowSize, bubbleHeight)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
