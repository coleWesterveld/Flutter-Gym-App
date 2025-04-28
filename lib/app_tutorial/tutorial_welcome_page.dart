import 'package:flutter/material.dart';
import 'tutorial_settings_page.dart'; // Import the next tutorial page
// Assuming app_tutorial_keys.dart is still needed for other parts, keep import if necessary

class TutorialWelcomePage extends StatefulWidget {
  const TutorialWelcomePage({super.key});

  @override
  _TutorialWelcomePageState createState() => _TutorialWelcomePageState();
}

class _TutorialWelcomePageState extends State<TutorialWelcomePage> with SingleTickerProviderStateMixin {
  // AnimationController to manage the animation progress
  late AnimationController _controller;
  // Animation for fading in the content
  late Animation<double> _fadeAnimation;
  // Animation for sliding the content up
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize the AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800), // Duration of the animation
      vsync: this, // the SingleTickerProviderStateMixin
    );

    // Define the fade animation
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn, // Use an ease-in curve for a smooth fade
    );

    // Define the slide animation
    // Tweens define the start and end values of the animation
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Start slightly below the final position
      end: Offset.zero, // End at the original position
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic, // Use a different curve for the slide
    ));

    // Start the animation when the widget is built
    _controller.forward();
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is removed to prevent memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Apply the animations to the content
    return Scaffold(
      
      body: Center(
        // Wrap the main content Column with FadeTransition and SlideTransition
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center, size: 80),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome to Your Fitness Tracker!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Let\'s get you set up and show you around.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    onPressed: () {
                      Navigator.pushReplacement( // Replace so user can't go back
                        context,
                        MaterialPageRoute(builder: (context) => const TutorialSettingsPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width:2
                      )
                    ),
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