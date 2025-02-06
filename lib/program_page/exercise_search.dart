import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ExerciseDropdown extends StatefulWidget {

  ExerciseDropdown({super.key});

  @override
  State<ExerciseDropdown> createState() => _ExerciseDropdownState();
}

class _ExerciseDropdownState extends State<ExerciseDropdown> {
  List<Map<String, dynamic>> _exercises = []; // Store both ID & Title
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadExercisesFromDatabase(); // Load exercises on startup
  }

  Future<void> _loadExercisesFromDatabase() async {
    // Fetch exercises as a list of maps [{id: 1, title: "Bench Press"}, ...]
    _exercises = await dbHelper.fetchExercisesWithIds();
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (BuildContext context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min, // Adjust height to content
          children: [
            SizedBox(
              width: double.infinity, // Full-width dropdown
              child: DropdownMenu<int>( // Change type to int (exercise ID)
              //errorText: "THIS IS RED ERROR TEXT",
              //expandedInsets: EdgeInsets.symmetric(vertical: 20),
              //menuStyle: MenuStyle(fixedSize: WidgetStatePropertyAll(Size(50, 200)) ),
                width: MediaQuery.of(context).size.width - 32,
                // TODO: this is not responsive and will not work on smaller screens
                // need to make responsive
                menuHeight: 300, // Limit menu height for better UX
                enableFilter: true,
                requestFocusOnTap: true,
                leadingIcon: const Icon(Icons.search),
                label: const Text('Search Exercises'),
                inputDecorationTheme: const InputDecorationTheme(
                  filled: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                ),
                onSelected: (int? exerciseId) {
                  if (exerciseId != null) {
                    Navigator.of(context).pop(exerciseId); // Return ID instead of title
                  }
                },
                dropdownMenuEntries: _exercises.map((exercise) {
                  return DropdownMenuEntry<int>(
                    label: exercise['exercise_title'], // Display title
                    value: exercise['id'], // Store ID as value
                  );
                }).toList(),
              ),
            ),

            //Container(height: 250, color: Colors.red)
          ],
        );
      },
    );
  }
}
