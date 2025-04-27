import 'package:flutter/material.dart';
import 'tutorial_settings_page.dart'; // Import the next tutorial page
import 'app_tutorial_keys.dart'; // Import keys if needed for this page (optional)

class TutorialWelcomePage extends StatelessWidget {
  const TutorialWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: Center(
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
                // key: AppTutorialKeys.welcomeNextButton, // Assign key if showcasing this button
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}