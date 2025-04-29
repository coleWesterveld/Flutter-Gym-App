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

// TODO: allow back button in appbar when chart displaying 

// TODO: bigger text maybe? or at least, option to scale it? I need old people for testing

import 'package:firstapp/app_tutorial/app_tutorial_keys.dart';
import 'package:firstapp/app_tutorial/tutorial_manager.dart';
import 'package:firstapp/widgets/history_session_view.dart';
import 'package:firstapp/widgets/target_weight_dialog.dart';
import 'package:firstapp/widgets/weekly_progress.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
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
import 'package:firstapp/other_utilities/timespan.dart';
import 'package:firstapp/providers_and_settings/ui_state_provider.dart';
import 'package:firstapp/providers_and_settings/settings_provider.dart';

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

  Future<List<List<SetRecord>>>? _exerciseHistory;

  List<Goal> _goals = [];
  String? tempGoalTitle;
  bool _isLoadingGoals = true;

  Timespan _selectedTimespan = Timespan.sixMonths; // Default timespan


  final scrollControl = ScrollController();
  bool showBackToTop = false;

  @override
  void initState() {
    scrollControl.addListener(() {
    // Determine the desired state based on scroll offset
    final bool shouldShow = scrollControl.offset > 100;
    // Only call setState if the state needs to change
      if (shouldShow != showBackToTop) {
        setState(() {
          showBackToTop = shouldShow;
        });
      }
    });
    super.initState();
    _fetchGoals();
    
  }

  @override
  void dispose(){
    super.dispose();
    scrollControl.dispose();
  }

  // Load existing goals from the database
  Future<void> _fetchGoals({useMetric = false}) async {
    setState(() => _isLoadingGoals = true);

    final dbHelper = DatabaseHelper.instance;
    _goals = await dbHelper.fetchGoalsWithProgress(useMetric: useMetric);

    setState(() => _isLoadingGoals = false);
    
  }

  @override
  Widget build(BuildContext context) {
    final uiState = context.watch<UiStateProvider>();


    if (!context.watch<Profile>().isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      extendBody: true, // Allows FAB to overlap MainScaffold's bottom nav
      backgroundColor: Colors.transparent, // Prevents double background

      floatingActionButton: (_displayChart && showBackToTop)
        ? FloatingActionButton(
          onPressed: (){
            scrollControl.animateTo(
              0, 
              duration: const Duration(milliseconds: 300), 
              curve: Curves.easeIn,
            );
          }, 
        child: const Icon(Icons.keyboard_double_arrow_up_sharp),
      )
      : null,

      body: Stack(
        children: [
          // Show analytics content with the persistent search bar only when not searching.
          if (!_isSearching && !uiState.isAddingGoal)
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
          if (uiState.isAddingGoal) _createGoal(context),
        ],
      ),
    );
  }

  // Callback when an exercise is selected - get history from the database
  Future<List<List<SetRecord>>> _handleExerciseSelected(Map<String, dynamic> exercise) async {
    final dbHelper = DatabaseHelper.instance;
    final records = await dbHelper.getExerciseHistoryGroupedBySession(exercise['exercise_id']);
    return records;
  }

  // When a goal is being added and the user selected the exercise for the goal to be for
  // This brings up the selector for target weight
  void _exerciseForGoalSelected(Map<String, dynamic> exercise) async {
    final dbHelper = DatabaseHelper.instance;
    final exerciseName = exercise['exercise_title'];

    final weight = await showDialog<double>(
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
  Future<double> _calculateCurrentOneRm(int exerciseId) async {

    final db = await DatabaseHelper.instance.database;
    final recentSet = await db.query(
      'set_log',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (recentSet.isEmpty) return 0;
    
    
    final weight = recentSet.first['weight'] as double;
    final reps = (recentSet.first['reps'] as double);

    // Formula to estimate 1 rep max
    return (weight * (1 + reps / 30));
  }

  // Build the exercise history view.
  Widget _buildExerciseHistory() {

    return FutureBuilder(
      future: _exerciseHistory,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading History. Sorry :/'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No History Found'));
        }

        final exerciseHistory = snapshot.data!;
          
        return Scrollbar(
          controller: scrollControl,
          child: SingleChildScrollView(
            controller: scrollControl,
            
            child: Column(
              children: [
                ExerciseProgressChart(
                  exercise: _exercise!,
                  theme: widget.theme,
                  selectedTimespan: _selectedTimespan,
                  useMetric: context.read<SettingsModel>().useMetric,

                  // auto calculate based on number of records
                  decimationFactor: -1,

                  onTimespanChanged: (newTimespan) {
                    setState(() {
                      _selectedTimespan = newTimespan;
                    });
                  },
                ),

                Divider(
                  color: widget.theme.colorScheme.outline,
                  thickness: 2,
                  endIndent: 40,
                  indent: 40,
                ),
          
                // for this I could implement a see more option maybe
                // the listview.builder does only build the ones in view so its actually not bad performance-wise already
                // performance testing shows this runs comfortably and not close to hitting memory ceiling on my mid-tier phone
                // so its fine unless further testings shows an issue or I decide its best for UX
                ExerciseHistoryList(
                  exerciseHistory: exerciseHistory,
                  theme: widget.theme,

                  
                ),
              ],
            ),
          ),
        );
      }
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

    final newWeight = await showDialog<double>(
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
                Navigator.pop(context, double.parse(weightController.text));
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
      if (mounted){
        await _fetchGoals(useMetric: context.read<SettingsModel>().useMetric);
      }
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
    final manager = context.watch<TutorialManager>();
    final uiState = context.watch<UiStateProvider>();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [  
            Showcase(
              disableDefaultTargetGestures: true,
              key: AppTutorialKeys.recentWorkouts,
              description: "See your progress from the past week. Tap on an exercise to see an extended history.",
              tooltipBackgroundColor: theme.colorScheme.surfaceContainerHighest,
      descTextStyle: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 16,
      ),

      tooltipActions: [
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          onTap: () => manager.skipTutorial(),
          backgroundColor: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.onSurface
          ),
          textStyle: TextStyle(
            color: theme.colorScheme.onSurface
          )

          
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          onTap: () => manager.advanceStep(),
          border: Border.all(
            color: theme.colorScheme.onSurface
          ),
          backgroundColor: theme.colorScheme.surface,
          textStyle: TextStyle(
            color: theme.colorScheme.onSurface
          )
        )
      ],
              child: Container(
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
                            setState(() {
                              _exercise = exercise.toMap();
                              _displayChart = true;
                            });
              
                            _exerciseHistory = _handleExerciseSelected(exercise.toMap());
                          }
                       )
                      ),
                    ],
                  )
                )
              ),
            ),
      
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Showcase(
                disableDefaultTargetGestures: true,
                key: AppTutorialKeys.addGoals,
                description: "Add a target weight for an exercise, and watch your predicted one-rep max improve.",
                tooltipBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                descTextStyle: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),

                tooltipActions: [
                  TooltipActionButton(
                    type: TooltipDefaultActionType.skip,
                    onTap: () => manager.skipTutorial(),
                    name: "Finish",
                    backgroundColor: theme.colorScheme.surface,
                    border: Border.all(
                      color: theme.colorScheme.onSurface
                    ),
                    textStyle: TextStyle(
                      color: theme.colorScheme.onSurface
                    )

                    
                  ),
                ],
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
                                        setState(() => uiState.isAddingGoal = true,);
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
                "Search exercise to view history...",
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
      onExerciseSelected: (exercise){
        setState(() {
          _exercise = exercise;
          _displayChart = true;
        });

        _exerciseHistory = _handleExerciseSelected(exercise);
      },

      onSearchModeChanged: (isSearching) {
        setState(() {
          _isSearching = isSearching;          
        });
      },
    );
  }

  Widget _createGoal(BuildContext context){
    final uiState = context.watch<UiStateProvider>();


    return ExerciseSearchWidget(
      onExerciseSelected: _exerciseForGoalSelected,
      onSearchModeChanged: (isSearching) {
        setState(() {
          uiState.isAddingGoal = isSearching;
        });
      },
      theme: widget.theme,
    );
  }
}
