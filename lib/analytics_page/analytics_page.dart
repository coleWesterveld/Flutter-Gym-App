// analyitcs page

//big page overhaul with search - links to DB to search for index
// next step is to take that index, query history, and plot it
// and clean up the UI

// overall goal of this page:
// metrics for motivation/acccountability
// insights into effective exercises or routines 
// (effectiveness measured by increased strength, or other metric)
// fun for workout and data geeks :)

// To continue I should add mock history to plot and test

// allow users to see graphs by search, or pin graphs or goals
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
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoadingGoals = true);
    try {
      final dbHelper = DatabaseHelper.instance;
      _goals = await dbHelper.fetchGoalsWithProgress();
    } catch (e) {
      debugPrint('Failed to load goals: $e');
    } finally {
      setState(() => _isLoadingGoals = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e2025),
        centerTitle: true,
        title:  Text(
          _isAddingGoal ? "Select Exercise For Goal": "Analytics",
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
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
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
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

  // Callback when an exercise is selected.
  void _handleExerciseSelected(Map<String, dynamic> exercise) async {
    debugPrint("selected: ${exercise}");
    final dbHelper = DatabaseHelper.instance;
    final records = await dbHelper.getExerciseHistoryGroupedBySession(exercise['exercise_id']);
    setState(() {
      _exercise = exercise;
      _displayChart = true;
      _exerciseHistory = records;
    });
  }

  void _exerciseForGoalSelected(Map<String, dynamic> exercise) async {
  final dbHelper = DatabaseHelper.instance;
  final weightController = TextEditingController();
  final exerciseName = exercise['exercise_title'];

  final weight = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Target for $exerciseName"),
        

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Target Weight",
                suffixText: "lbs",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (weightController.text.isNotEmpty) {
                Navigator.pop(context, int.parse(weightController.text));
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    ); // (keep your existing dialog code)

  if (weight != null) {
    debugPrint("test 1 $exercise");
    
    // 1. First calculate current 1RM for this exercise
    final currentOneRm = await _calculateCurrentOneRm(exercise['exercise_id']);
    debugPrint("test 2");

    // 2. Create and save the goal with accurate progress
    final newGoal = Goal(
      exerciseId: exercise['exercise_id'] as int ,
      exerciseTitle: exerciseName,
      targetWeight: weight,
      currentOneRm: currentOneRm, // Now has real value immediately
    );

    
       


    final insertedId = await dbHelper.insertGoal(newGoal);
     debugPrint("test 3");
    final savedGoal = newGoal.copyWith(id: insertedId);

    debugPrint('''
      Goal Debug:
      Current 1RM: ${savedGoal.currentOneRm}
      Target: ${savedGoal.targetWeight}
      Progress: ${savedGoal.progressPercentage}%
    ''');
    debugPrint("goals: $_goals");
    // 3. Update UI
    setState(() {
      _goals.add(savedGoal);
    });
    debugPrint("goals: $_goals");

    // 4. Still refresh later for any other updates
    _fetchData(); // Runs in background without await
    debugPrint("goals: $_goals");
  }
}

Future<int> _calculateCurrentOneRm(int exerciseId) async {

  debugPrint("exercise id: $exerciseId");
  final db = await DatabaseHelper.instance.database;
  final recentSet = await db.query(
    'set_log',
    where: 'exercise_id = ?',
    whereArgs: [exerciseId],
    orderBy: 'date DESC',
    limit: 1,
  );

  debugPrint("this should run/....");

  if (recentSet.isEmpty) return 0;
  
  // Use your preferred 1RM formula (here's Epley)
  final weight = recentSet.first['weight'] as int;
  final reps = (recentSet.first['reps'] as int);
  debugPrint("Reps: $reps");
  print("goal: ${(weight * (1 + reps / 30)).round()}");
  return (weight * (1 + reps / 30)).round();
}


  // Build the exercise history view.
  Widget _buildExerciseHistory() {
    // // Group history by date
    // final Map<String, List<SetRecord>> groupedHistory = {};
    // for (var record in _exerciseHistory) {
    //   final date = record.dateAsDateTime.toLocal().toString().split(' ')[0];
    //   if (!groupedHistory.containsKey(date)) {
    //     groupedHistory[date] = [];
    //   }
    //   groupedHistory[date]!.add(record);
    // }

    //debugPrint("History: ${groupedHistory}");

    return SingleChildScrollView(
      child: Column(
        children: [
          ExerciseProgressChart(exercise: _exercise!),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
                    itemCount: _exerciseHistory.length + 1,
                    itemBuilder:(context, index) {
                      if (index == _exerciseHistory.length){
                        return const Text(
                          "End of History"
                        );
                      }
            
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: lighten(Color(0xFF1e2025), 20),
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "${formatDate(_exerciseHistory[index][0].dateAsDateTime)}: ",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    )
                                  )
                                ),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: _exerciseHistory[index].length,
                                  itemBuilder: (context, historyIndex) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4.0,
                                        horizontal: 32,
                                      ),
                                      child: Text(
                                        "${_exerciseHistory[index][historyIndex].numSets} sets x ${_exerciseHistory[index][historyIndex].reps} reps @ ${_exerciseHistory[index][historyIndex].weight} lbs (RPE: ${_exerciseHistory[index][historyIndex].rpe})",
                                        style: TextStyle(
                                          fontSize: 16, 
                                          fontWeight: FontWeight.w700
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, 
                  ),
          ),
          // ...groupedHistory.entries.map((entry) {
          //   final date = entry.key;
          //   final records = entry.value;
          //   return Padding(
          //     padding: const EdgeInsets.all(8.0),
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Padding(
          //           padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //           child: Text(
          //             date,
          //             style: const TextStyle(
          //               fontWeight: FontWeight.bold,
          //               fontSize: 18,
          //             ),
          //           ),
          //         ),
          //         ...records.map((record) {
          //           return ListTile(
          //             title: Text(
          //               "${record.numSets} sets x ${record.reps} reps @ ${record.weight} lbs (RPE: ${record.rpe})",
          //             ),
          //             subtitle: record.historyNote != null && record.historyNote!.isNotEmpty
          //                 ? Text("Notes: ${record.historyNote}")
          //                 : null,
          //           );
          //         }).toList(),
          //       ],
          //     ),
          //   );
          // }).toList(),
        ],
      ),
    );
  }

  Future<void> _addGoalInDatabase (Goal goal, int index) async {
    final dbHelper = DatabaseHelper.instance;
    final goalId = await dbHelper.insertGoal(goal);
    _goals[index] = _goals[index].copyWith(id: goalId);
  }

  // void _addGoal(Goal goal) {
  //   debugPrint('''
  //     Goal Debug:
  //     Current 1RM: ${goal.currentOneRm}
  //     Target: ${goal.targetWeight}
  //     Progress: ${goal.progressPercentage}%
  //   ''');
  //   setState(() {
  //     _goals.add(goal);
  //   });
  //   _addGoalInDatabase(goal, _goals.length - 1); 
  // }

List<Widget> _buildGoalList() {
  debugPrint("here: $_goals");
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
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: lighten(Color(0xFF1e2025), 10),
            ),
            width: (MediaQuery.sizeOf(context).width - 48)/2,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: GoalProgress(goal: goal),
            ),
          ),
        ],
      ),
    ),
  )).toList();
}

void _showGoalOptions(Goal goal) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Target'),
            onTap: () {
              Navigator.pop(context);
              _editGoalWeight(goal);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete Goal', style: TextStyle(color: Colors.red)),
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
        decoration: InputDecoration(
          labelText: 'Target Weight (lbs)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (weightController.text.isNotEmpty) {
              Navigator.pop(context, int.parse(weightController.text));
            }
          },
          child: Text('Save'),
        ),
      ],
    ),
  );

  if (newWeight != null) {
    final updatedGoal = goal.copyWith(targetWeight: newWeight);
    await dbHelper.updateGoal(updatedGoal);
    await _fetchData(); // Refresh goals list
  }
}

Future<void> _deleteGoal(Goal goal) async {
    final dbHelper = DatabaseHelper.instance;
      final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Goal?'),
      content: Text('This will remove your ${goal.exerciseTitle} target'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Delete', style: TextStyle(color: Colors.red)),
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
    if (_displayChart){

      assert(_exercise != null, "to show exercise history, it should not be null");
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // TODO: error check here maybe with the !
  
            if (_displayChart)
              ExerciseProgressChart(exercise: _exercise!),
      
            Container(
              height: 325,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Color(0xFF1e2025),  
              ),
      
              
              //height: 200,
              child:  Align( // this will not stay const 
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          // TODO: instead of current scroll, each card shoudl take fill page and there should be dot tab indiators on bottom
                            "Last 7 Days",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                     Expanded(child: PageViewWithIndicator(
                      onSelected: (exercise){
                        debugPrint("exercise: ${exercise.toMap()}");
                        _handleExerciseSelected(exercise.toMap());
                      }
                     )),
      
                  ],
                )
              )
            ),
      
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Container(
                //height: 325,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF1e2025),  
                ),
                      
                
                //height: 200,
                child: Align( // this will not stay const 
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0 ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
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
                                  //height: 130,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() => _isAddingGoal = true,);
                                      
                                    },
                                  
                                    style: ButtonStyle(
                                      //when clicked, it splashes a lighter purple to show that button was clicked
                                      shape: WidgetStateProperty.all(RoundedRectangleBorder(
                              
                                        borderRadius: BorderRadius.circular(12))),
                                      backgroundColor: WidgetStateProperty.all(Color(0XFF1A78EB),), 
                                      overlayColor: WidgetStateProperty. resolveWith<Color?>((states) {
                                        if (states.contains(WidgetState.pressed)) return Color(0XFF1A78EB);
                                        return null;
                                      }),
                                    ),
                                    
                                    label: 
                                        const Text(
                          
                                          "Add Goal",
                                          style: TextStyle(
                                              color: Color.fromARGB(255, 255, 255, 255),
                                              //fontSize: 18,
                                              //fontWeight: FontWeight.w800,
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
                        // this might be overkill - loading is realtime and the half rendered progress looks janky
                        // but idk how would perform on slow phones - will test
                        child: _isLoadingGoals ?  Center(child: CircularProgressIndicator()): Wrap(
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

  // Persistent search bar.
  Widget _buildPersistentSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _isSearching = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1e2025),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: const [
              Icon(Icons.search, color: Color(0xFFdee3e5)),
              SizedBox(width: 8),
              Text(
                "Search exercise",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Full-screen search overlay.
  Widget _buildFullScreenSearch() {
    debugPrint(_isAddingGoal.toString());
    return ExerciseSearchWidget(
      onExerciseSelected: _handleExerciseSelected,
      onSearchModeChanged: (isSearching) {
        setState(() {
          _isSearching = isSearching;
          //if (!isSearching) _isAddingGoal = false;
          
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
    );
  }
}

// ---------------------------------------------------------
// The rest of the widget implementations

class GoalProgress extends StatefulWidget {
  const GoalProgress({
    super.key,
    //required this.current,
    required this.goal
  });
  //final int current;
  final Goal goal;

  @override
  State<GoalProgress> createState() => _GoalProgressState();
}

class _GoalProgressState extends State<GoalProgress> {
  @override
  Widget build(BuildContext context) {
    // debugPrint("single: ${widget.goal}"); // this is printing a lot, I hope thats okay? 
    return SizedBox(
      //color: Colors.red,
      height: 175,
      width: 175,
      child: Stack(
        children: [
            Center(
              child: ThickCircularProgress(
                progress: widget.goal.progressPercentage/100, 
                completedStrokeWidth: 25.0,
                backgroundStrokeWidth: 18.0,
                completedColor: Color(0XFF1A78EB),
                backgroundColor: lighten(Color(0xFF1e2025), 20),
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Actual',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFF1A78EB),
                  ),
                ),
                                
                const SizedBox(height: 5),
                
                Text(
                  '${widget.goal.currentOneRm} lbs',
                  textHeightBehavior: TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                                
                const Divider(
                  height: 5,
                  color: Colors.grey, // Line color
                  thickness: 2.0,    // Line thickness
                  indent: 60.0,      // Left padding
                  endIndent: 60.0,   // Right padding
                ),
                                
                Text(
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                                
                  '${widget.goal.targetWeight} lbs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Goal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFF1A78EB),
                  ),
                ),
                                
                                
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DayProgress extends StatefulWidget {
  DayProgress({
    super.key,
    required this.index,
  });

  final int index;

  @override
  State<DayProgress> createState() => _DayProgressState();
}

class _DayProgressState extends State<DayProgress> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: lighten(Color(0xFF1e2025), 10),
        ),
        
        width: 200,
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 300,
                    ),

                    child: Text(
                      context.read<Profile>().split[widget.index].dayTitle,

                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      maxLines: 2,

                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),


                  // TODO: this should be read from database as actual date
                  Text("Mon, 13/01")
                ],
              ),
            

            Expanded(
              child: ListView.builder(
              
                  itemCount: context.read<Profile>().exercises[widget.index].length,
                  itemBuilder: (context, exerciseIndex) {
                    return Container(
                      
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(1)),
                        border: Border(bottom: BorderSide(color: lighten(Color(0xFF1e2025), 30)/*Theme.of(context).dividerColor*/, width: 0.5),),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 300,
                                ),
                              
                                child: Text(
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  maxLines: 2,
                                  context.read<Profile>().exercises[widget.index][exerciseIndex].exerciseTitle,
                                ),
                              ),
                            ),
                        
                            Row(
                              children:[
                                buildTick(), 
                                  
                                Text("5lbs")
                              ]
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  
                ),
            ),
            ],
          ),
        )
                    
      ),
    );
  }

  Icon buildTick() {
    // random for mock for now but will eventually be based off of real data
    int random = Random().nextInt(3);
    const List<Color> colors = [Colors.red, Colors.green, Colors.grey];
    const List<IconData> icons = [Icons.arrow_drop_down, Icons.arrow_drop_up, Icons.remove];
    
    return Icon(
      icons[random], 
      color: colors[random],
    );
  }
}

// // cant even lie this whole class was written by ChatGPT
// // I wanted to have the circular progress indicator more customizeable
// // specifically, I can make the progressed part thicker than the non completed part
class ThickCircularProgress extends StatelessWidget {
  final double progress; // Progress as a value between 0 and 1
  final double completedStrokeWidth;
  final double backgroundStrokeWidth;
  final Color completedColor;
  final Color backgroundColor;

  const ThickCircularProgress({
    required this.progress,
    this.completedStrokeWidth = 10.0,
    this.backgroundStrokeWidth = 4.0,
    this.completedColor = Colors.blue,
    this.backgroundColor = Colors.grey,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(150, 150), // Adjust the size as needed
      painter: CircularProgressPainter(
        progress: progress,
        completedStrokeWidth: completedStrokeWidth,
        backgroundStrokeWidth: backgroundStrokeWidth,
        completedColor: completedColor,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double completedStrokeWidth;
  final double backgroundStrokeWidth;
  final Color completedColor;
  final Color backgroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.completedStrokeWidth,
    required this.backgroundStrokeWidth,
    required this.completedColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = backgroundStrokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw the completed arc
    final completedPaint = Paint()
      ..color = completedColor
      ..strokeWidth = completedStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Optional: Rounded ends
    final sweepAngle = progress * 2 * 3.14159265359;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265359 / 2, // Start angle (top of the circle)
      sweepAngle,
      false,
      completedPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
