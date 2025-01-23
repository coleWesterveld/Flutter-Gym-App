import 'package:flutter/material.dart';
// import 'package:dropdown_search/dropdown_search.dart';
//import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class ExerciseDropdown extends StatefulWidget {
  const ExerciseDropdown({super.key});

  @override
  State<ExerciseDropdown> createState() => _ExerciseDropdownState();
}

class _ExerciseDropdownState extends State<ExerciseDropdown> {

  List<String> _exercises = []; // Initial exercise list
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadExercisesFromDatabase(); // Load exercises on startup
  }

  Future<void> _loadExercisesFromDatabase() async {
    // Open database and fetch exercises

    // Query all exercises
    _exercises = await dbHelper.fetchExerciseTitlesFromAll();
    
    setState(() {});
  }

  // Future<void> _addCustomExercise({required String newExercise, String musclesWorked = '', String persistentNote = ''}) async {
  //   // Insert the new exercise into the database
  //   await dbHelper.insertCustomExercise(exerciseTitle: newExercise, musclesWorked: musclesWorked, persistentNote: persistentNote);

  //   // Reload the exercise list
  //   await _loadExercisesFromDatabase();
  // }


  @override
  Widget build(BuildContext context) {
    // FocusNode dropDownFocus = FocusNode();
    // TextEditingController dropDownController = TextEditingController();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   dropDownFocus.requestFocus();
    // });
    return StatefulBuilder(
        builder: (BuildContext context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min, // Adjusts height to content
            children: [
              SizedBox(
                width: double.infinity, // Full-width dropdown
                child: DropdownMenu<String>(
                  //focusNode: dropDownFocus,

                  width: MediaQuery.of(context).size.width - 32, // Full-width minus padding
                  menuHeight: MediaQuery.of(context).size.height - 200, // Limit menu height for better UX
                  enableFilter: true,
                  //controller: dropDownController,
                  requestFocusOnTap: true,
                  leadingIcon: const Icon(Icons.search),
                  
                  label: const Text('Search Exercises'),
                  
                  inputDecorationTheme: const InputDecorationTheme(
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                  ),
                  
                  onSelected: (String? exercise) {
                    Navigator.of(context).pop(exercise);
                  },
                  dropdownMenuEntries: _exercises.map((String exercise) {
                    return DropdownMenuEntry<String>(
                      label: exercise,
                      value: exercise,

                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      );
  }
}