import 'package:flutter/material.dart';
import '../database/database_helper.dart';
//todo: make keybioard come up automatically here
class ExerciseDropdown extends StatefulWidget {

  ExerciseDropdown({super.key});

  @override
  State<ExerciseDropdown> createState() => _ExerciseDropdownState();
}

class _ExerciseDropdownState extends State<ExerciseDropdown> {
  List<Map<String, dynamic>> _exercises = []; // Store both ID & Title
  final dbHelper = DatabaseHelper.instance;
  final FocusNode _dropDownFocus = FocusNode();
  final TextEditingController _dropDownTEC = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_dropDownFocus);
    });
        _loadExercisesFromDatabase(); 
    //Future.delayed(const Duration(milliseconds: 500));
    //_dropDownTEC.clear();

    
  }

    @override
  void dispose() {
    _dropDownFocus.dispose(); 
    _dropDownTEC.dispose();
    super.dispose();
  }

  Future<void> _loadExercisesFromDatabase() async {
    // Fetch exercises as a list of maps [{id: 1, title: "Bench Press"}, ...]
    _exercises = await dbHelper.fetchExercisesWithIds();
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight;
    final menuHeight = availableHeight * 0.7 - 124; // Ensures some padding remains above

    return StatefulBuilder(
      builder: (BuildContext context, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min, // Adjust height to content
          children: [
            SizedBox(
              width: double.infinity, // Full-width dropdown
              child: DropdownMenu<int>( // Change type to int (exercise ID)
              focusNode: _dropDownFocus,
              controller: _dropDownTEC,
              
              //errorText: "THIS IS RED ERROR TEXT",
              //expandedInsets: EdgeInsets.symmetric(vertical: 20),
              //menuStyle: MenuStyle(fixedSize: WidgetStatePropertyAll(Size(50, 200)) ),
                width: MediaQuery.of(context).size.width - 32,
                // TODO: this is not responsive and will not work on smaller screens
                // need to make responsive
                menuHeight: menuHeight, // Limit menu height for better UX
                enableFilter: true,
                requestFocusOnTap: true,
                leadingIcon: const Icon(Icons.search),
                label: const Text('Search Exercises'),
                inputDecorationTheme: const InputDecorationTheme(
                  filled: true,
                  
                  contentPadding: EdgeInsets.symmetric(vertical: 5.0),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)), // Adjust the radius as needed
                      borderSide: BorderSide.none, // Removes the border if you want only the filled background
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)), // For non-focused state
                      borderSide: BorderSide(color: Colors.grey), // Optional border color
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)), // For focused state
                      borderSide: BorderSide(color: Colors.blue, width: 2.0), // Optional focus border
                    ),
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
