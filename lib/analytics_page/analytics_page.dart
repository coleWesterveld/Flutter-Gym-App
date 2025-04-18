// View analytics, this weeks progress, goals, and history

// maybe cool idea: allow easy export as CSV
// goal is to have analytics on a few things, namely: 
// DOTS or other powerlifting scoring scores based off of SBD and bodyweight
// bodyweight
// estimated 1RM in lift of choice**
// training frequency by month/week or some kind of volume tracker?
// maybe something to do a spotify wrapped type thing
// should clearly show markers like stocks do or something ie. ^5% 
// show gains for this week and then long term
// maybe good to have a smart feature which puts graphs that are important at the top automatically
//  important could be "progressing exceptionally well/poorly"
// make sure one rep max is calculated from top set from last session

/* I want to allow the user to pin some calculated stats to the top, here are some ideas from deepseek/me:

DOTS Score (Relative Strength)
(Weight Lifted) * 500 / (-16.260 + 1.0552*x - 0.0022405*x² + 0.0000010076*x³) (x = body weight in kg)
Shows strength relative to body weight (great for tracking progress across weight classes)
Wilks Score (Alternative to DOTS for powerlifting)
SBD Total (Squat + Bench + Deadlift 1RMs)

Meet Predictor
Projects competition total based on training maxes
Attempt Selection Advisor
Suggests opener/2nd/3rd attempt weights based on training history

PR Heatmap
Calendar view highlighting personal record days

Plateau Detection
Flags lifts with no progress in X weeks

Add a "Random Stat of the Day" widget that shows:
"You've spent 42 hours under the squat bar this year"
"Your total volume = 17 Toyota Corollas"
*/



// TODO: bigger text maybe? or at least, option to scale it? I need old people for testing

import 'package:firstapp/widgets/history_session_view.dart';
import 'package:firstapp/widgets/target_weight_dialog.dart';
import 'package:firstapp/widgets/weekly_progress.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import "../providers_and_settings/program_provider.dart";
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../other_utilities/lightness.dart';
import '../widgets/exercise_search.dart';
import '../widgets/exercise_progress_chart.dart';
import '../database/profile.dart';
import '../widgets/info_popup.dart';
import '../providers_and_settings/settings_page.dart';
import 'package:firstapp/other_utilities/format_weekday.dart';
import 'package:firstapp/widgets/exercise_history_list.dart';
import 'package:firstapp/widgets/circular_progress.dart';
import 'package:firstapp/widgets/goal_progress.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  Map<String, dynamic>? _exercise;
  bool _isSearching = false;
  bool _displayChart = false;
  List<List<SetRecord>> _exerciseHistory = [];
  List<Goal> _goals = [];
  bool _isAddingGoal = false;
  String? tempGoalTitle;
  bool _isLoadingGoals = true;

  @override
  void initState() {
    super.initState();
    _fetchGoals();
  }

  // Load existing goals from the database
  Future<void> _fetchGoals() async {
    setState(() => _isLoadingGoals = true);

    final dbHelper = DatabaseHelper.instance;
    _goals = await dbHelper.fetchGoalsWithProgress();

    setState(() => _isLoadingGoals = false);
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: widget.theme.colorScheme.surface,
        centerTitle: true,
        title:  Text(
          _isAddingGoal ? "Select Exercise For Goal": "Analytics",
        ),

        leading: _displayChart
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _displayChart = false;
                  _exercise = null;
                  _exerciseHistory.clear();
                });
              },
            )
          : null,

        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ]
      ),

      body: Stack(
        children: [
          // Show analytics content with the persistent search bar only when not searching.
          if (!_isSearching && !_isAddingGoal)
            Column(
              children: [
                if (!_displayChart) _buildPersistentSearchBar(),
                Expanded(
                  child: _displayChart
                      ? _buildExerciseHistory()
                      : _buildAnalyticsContent(),
                ),
              ],
            ),

          // When search is active, show the full-screen search overlay.
          if (_isSearching) _buildFullScreenSearch(),
          if (_isAddingGoal) _createGoal(),
        ],
      ),
    );
  }

  // Callback when an exercise is selected - get history from the database
  void _handleExerciseSelected(Map<String, dynamic> exercise) async {
    final dbHelper = DatabaseHelper.instance;
    final records = await dbHelper.getExerciseHistoryGroupedBySession(exercise['exercise_id']);
    setState(() {
      _exercise = exercise;
      _displayChart = true;
      _exerciseHistory = records;
    });
  }

  // When a goal is being added and the user selected the exercise for the goal to be for
  // This brings up the selector for target weight
  void _exerciseForGoalSelected(Map<String, dynamic> exercise) async {
    final dbHelper = DatabaseHelper.instance;
    final exerciseName = exercise['exercise_title'];

    final weight = await showDialog<int>(
      context: context,
      builder: (context) => TargetWeightDialog(
        exerciseName: exerciseName,
        theme: widget.theme,
      ),
    );

    if (weight != null) {

      // First calculate current 1RM for this exercise
      final currentOneRm = await _calculateCurrentOneRm(exercise['exercise_id']);

      // Create and save the goal with accurate progress
      final newGoal = Goal(
        exerciseId: exercise['exercise_id'] as int ,
        exerciseTitle: exerciseName,
        targetWeight: weight,
        currentOneRm: currentOneRm,
      );

      final insertedId = await dbHelper.insertGoal(newGoal);

      final savedGoal = newGoal.copyWith(id: insertedId);

      setState(() {
        _goals.add(savedGoal);
      });
    }
  }

  // calculates one rep max based off of last logged set from the database
  Future<int> _calculateCurrentOneRm(int exerciseId) async {

    final db = await DatabaseHelper.instance.database;
    final recentSet = await db.query(
      'set_log',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (recentSet.isEmpty) return 0;
    
    
    final weight = recentSet.first['weight'] as int;
    final reps = (recentSet.first['reps'] as int);

    // Formula to estimate 1 rep max
    return (weight * (1 + reps / 30)).round();
  }

  // Build the exercise history view.
  Widget _buildExerciseHistory() {

    return SingleChildScrollView(
      child: Column(
        children: [
          ExerciseProgressChart(
            exercise: _exercise!,
            theme: widget.theme,
          ),

          ExerciseHistoryList(
            exerciseHistory: _exerciseHistory,
            theme: widget.theme,
          ),
        ],
      ),
    );
  }

  // List of Goal widgets, tappable to edit/delete
  List<Widget> _buildGoalList() {
    return _goals.map((goal) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: GestureDetector(
        onTap: () => _showGoalOptions(goal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (MediaQuery.sizeOf(context).width - 48)/2,
              ),

              child: Text(
                goal.exerciseTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),

            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: widget.theme.colorScheme.surfaceContainerHighest,
              ),
              width: (MediaQuery.sizeOf(context).width - 48)/2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: GoalProgress(
                  goal: goal,
                  size: (MediaQuery.sizeOf(context).width - 48)/2,
                  theme: widget.theme,
                ),
              ),
            ),
          ],
        ),
      ),
    )).toList();
  }

  // Bottomsheet that pops up when a goal is tapped
  void _showGoalOptions(Goal goal) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Target'),
              onTap: () {
                Navigator.pop(context);
                _editGoalWeight(goal);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete, 
                color: widget.theme.colorScheme.error
              ),

              title: Text(
                'Delete Goal', 
                style: TextStyle(
                  color: widget.theme.colorScheme.error
                )
              ),

              onTap: () {
                Navigator.pop(context);
                _deleteGoal(goal);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Dialog for editing goal target
  Future<void> _editGoalWeight(Goal goal) async {
    final dbHelper = DatabaseHelper.instance;
    final weightController = TextEditingController(text: goal.targetWeight.toString());

    final newWeight = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Target for ${goal.exerciseTitle}'),
        content: TextField(
          controller: weightController,
          keyboardType: TextInputType.number,

          decoration: const InputDecoration(
            labelText: 'Target Weight (lbs)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (weightController.text.isNotEmpty) {
                Navigator.pop(context, int.parse(weightController.text));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newWeight != null) {
      final updatedGoal = goal.copyWith(targetWeight: newWeight);
      await dbHelper.updateGoal(updatedGoal);
      await _fetchGoals();
    }
  }

  // Dialog and DB method to delete goal
  Future<void> _deleteGoal(Goal goal) async {

    final dbHelper = DatabaseHelper.instance;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('This will remove your ${goal.exerciseTitle} target'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete', 
              style: TextStyle(
                color: widget.theme.colorScheme.error
              )
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await dbHelper.deleteGoal(goal.id!);
      setState(() {
        _goals.removeWhere((g) => g.id == goal.id);
      });
    }
  }

  // Build the original analytics content.
  SingleChildScrollView _buildAnalyticsContent() {

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [  
            Container(
              height: 325,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: widget.theme.colorScheme.surface,  

                boxShadow: [
                  BoxShadow(
                    blurRadius: 5,
                    offset: const Offset(0, 0),
                    spreadRadius: 2,
                    color: widget.theme.colorScheme.shadow.withAlpha((0.3*255).round())

                  )
                ]
              ),
      
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                            "Last 7 Days",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      // Displays progress on exercises during past week workout
                      child: PageViewWithIndicator(
                        theme: widget.theme,
                        onSelected: (exercise){
                          _handleExerciseSelected(exercise.toMap());
                        }
                     )
                    ),
                  ],
                )
              )
            ),
      
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.theme.colorScheme.surface,  

                  boxShadow: [
                    BoxShadow(
                      blurRadius: 5,
                      offset: const Offset(0, 0),
                      spreadRadius: 2,
                      color: widget.theme.colorScheme.shadow.withAlpha((0.3*255).round())

                    )
                  ]
                ),
                      
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Goals",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                    ),
                                  ),

                                  InfoPopupWidget(
                                    popupContent: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Your \'Actual\' weight is your calculated approximate n rep max using the Epley formula:'),
                                        Center(child: Text(" \n 1 Rep Max = Weight • (1 + reps / 30)")),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: ButtonTheme(
                                  minWidth: 100,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() => _isAddingGoal = true,);
                                    },
                                  
                                    style: ButtonStyle(
                                      shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12))),
                                          backgroundColor: WidgetStateProperty.all(widget.theme.colorScheme.primary,), 
                                    ),
                                    
                                    label: Text(
                                      "Add Goal",
                                      style: TextStyle(
                                        color: widget.theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: _isLoadingGoals 
                        ? const Center(child: CircularProgressIndicator())
                        : Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: _buildGoalList(),
                        ),
                      ),
                    ],
                  )
                )
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Persistent search bar
  Widget _buildPersistentSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _isSearching = true;
          });
        },
        child: Container(
          
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12.0),
          decoration: BoxDecoration(
            color: widget.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),

            boxShadow: [
              BoxShadow(
                blurRadius: 5,
                offset: const Offset(0, 0),
                spreadRadius: 2,
                color: widget.theme.colorScheme.shadow.withAlpha((0.3*255).round())

              )
            ]
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: widget.theme.colorScheme.onSurface),

              const SizedBox(width: 8),

              Text(
                "Search exercise",
                style: TextStyle(color: widget.theme.colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Full-screen search overlay.
  Widget _buildFullScreenSearch() {
    return ExerciseSearchWidget(
      theme: widget.theme,
      onExerciseSelected: _handleExerciseSelected,
      onSearchModeChanged: (isSearching) {
        setState(() {
          _isSearching = isSearching;          
        });
      },
    );
  }

  Widget _createGoal(){
    return ExerciseSearchWidget(
      onExerciseSelected: _exerciseForGoalSelected,
      onSearchModeChanged: (isSearching) {
        setState(() {
          _isAddingGoal = isSearching;
        });
      },
      theme: widget.theme,
    );
  }
}
