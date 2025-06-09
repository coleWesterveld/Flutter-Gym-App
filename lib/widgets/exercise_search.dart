import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'custom_exercise_form.dart';

class ExerciseSearchWidget extends StatefulWidget {
  const ExerciseSearchWidget({
    super.key,
    this.onExerciseSelected,
    this.onSearchModeChanged,
    required this.theme,
  });

  /// Called when an exercise is selected.
  final void Function(Map<String, dynamic> exercise)? onExerciseSelected;

  /// Called when the search mode changes. True means active search mode.
  final void Function(bool isSearching)? onSearchModeChanged;

  final ThemeData theme;

  @override
  State<ExerciseSearchWidget> createState() => _ExerciseSearchWidgetState();
}

class _ExerciseSearchWidgetState extends State<ExerciseSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  String _searchQuery = "";
  List<Map<String, dynamic>> _exercises = [];
  bool _showCustomMaker = false;

  @override
  void initState() {
    super.initState();
    _loadExercisesFromDatabase();

    // Automatically focus the search field when the widget appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
    _searchFocus.addListener(() {
      widget.onSearchModeChanged?.call(_searchFocus.hasFocus);
    });
  }

  Future<void> _loadExercisesFromDatabase() async {
    _exercises = await dbHelper.fetchExercisesWithIds();
    setState(() {});
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = "";
      _searchController.clear();
      _searchFocus.unfocus();
    });
    widget.onSearchModeChanged?.call(false);
  }

  Widget _buildFullScreenSearch(List<Map<String, dynamic>> filteredExercises) {
    return _showCustomMaker ? CustomExerciseForm(
      height: MediaQuery.of(context).size.height-MediaQuery.of(context).viewInsets.bottom,
      exit: ()=> setState(() {
        _showCustomMaker=false;
        
      }),
      onDone: (exercise) {
        widget.onExerciseSelected?.call(exercise);
        _clearSearch();
      },

      theme: widget.theme,
    ): 
    Positioned.fill(
      child: GestureDetector(
        onTap: _clearSearch,
        child: Material(
          child: Container(
            color: Colors.black.withOpacity(0.8),
            child: Column(
              children: [
                // Search bar row with back arrow.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _clearSearch,
                      ),
                      Expanded(
                        child: TextField(
                          autofocus: true,
                          showCursor: true,
                          cursorColor: Colors.white,
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: (query) {
                            setState(() {
                              _searchQuery = query;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Search exercise",
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        )
          
                      ),
                    ],
                  ),
                ),
                // Expanded list view for exercises.
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = filteredExercises[index];
                      return ListTile(
                        title: Text(
                          exercise['exercise_title'],
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          _searchController.text = exercise['exercise_title'];
                          final modifiedExercise = Map<String, dynamic>.from(exercise);
            
                          // Rename 'id' to 'exercise_id'
                          // this is remnant of old bad naming convention that should prolly be solved at the root at some point
                          modifiedExercise['exercise_id'] = modifiedExercise.remove('id');
                          
                          // Call the callback with the modified exercise
                          widget.onExerciseSelected?.call(modifiedExercise);
                          _clearSearch();
                        },
                      );
                    },
                  ),
                ),
                // Footer button: always visible at the bottom.
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ButtonTheme(
                      minWidth: double.infinity,
                      child: ElevatedButton(
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          backgroundColor: WidgetStateProperty.all(const Color(0xFF007aff)),
                        ),
                        onPressed: () {
                          // Prevent the outer GestureDetector from handling this tap.
                          // Call your custom logic to show a modal or add a new exercise.
                          setState(()=>_showCustomMaker = true);
                        },
                        child: const Text(
                          'Add New Exercise',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Filter exercises based on the search query.
    List<Map<String, dynamic>> filteredExercises = _exercises
        .where((exercise) => exercise['exercise_title']
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    return _buildFullScreenSearch(filteredExercises);
  }
}

