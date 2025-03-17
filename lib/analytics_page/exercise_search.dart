import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ExerciseSearchBar extends StatefulWidget {
  @override
  _ExerciseSearchBarState createState() => _ExerciseSearchBarState();
}

class _ExerciseSearchBarState extends State<ExerciseSearchBar> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _controller.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _controller.removeListener(_filterExercises);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    _exercises = await dbHelper.fetchExercisesWithIds();
    setState(() {
      _filteredExercises = _exercises; // Show all initially
    });
  }

  void _filterExercises() {
    final query = _controller.text.toLowerCase();
    setState(() {
      _filteredExercises = _exercises
          .where((exercise) =>
              exercise['exercise_title'].toLowerCase().contains(query))
          .toList();
    });
  }

  void _selectExercise(int exerciseId) {
    debugPrint("ID: $exerciseId"); // Return selected exercise ID
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SearchBar(
          hintText: "Search exercise",
          controller: _controller,
          onTapOutside: (event) =>
              WidgetsBinding.instance.focusManager.primaryFocus?.unfocus(),
          constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
          backgroundColor: WidgetStateProperty.all(const Color(0xFF1e2025)),
          leading: const Icon(Icons.search, color: Color(0xFFdee3e5)),
        ),
        if (_filteredExercises.isNotEmpty)
          Container(
            height: 200, // Limit dropdown height
            decoration: BoxDecoration(
              color: const Color(0xFF1e2025),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListView.builder(
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                return ListTile(
                  title: Text(exercise['exercise_title'],
                      style: const TextStyle(color: Colors.white)),
                  onTap: () => _selectExercise(exercise['id']),
                );
              },
            ),
          ),
      ],
    );
  }
}
