import 'package:firstapp/other_utilities/format_weekday.dart';
import 'package:firstapp/providers_and_settings/active_workout_provider.dart';
import 'package:firstapp/providers_and_settings/settings_provider.dart';
import 'package:firstapp/widgets/done_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers_and_settings/program_provider.dart';
import '../widgets/set_logging.dart';
import '../other_utilities/lightness.dart';
import 'dart:async';
import '../database/database_helper.dart';
import '../database/profile.dart';
import 'package:intl/intl.dart';
import '../providers_and_settings/settings_page.dart';
import 'package:firstapp/widgets/history_session_view.dart';
// all null checks are very importasnt cuz when popping there is an instant when this page is still rendering but active day is null
// I couldnt find a good way around it so everything is just null checked to catch null cases and tries to be discrete. 


// list todo: 
// TACKLING: expanded index should expand once, initially, and when a user finishes an exercise, but should not interfere further with user interaction
// the text should remain in the fields even upon closing/expanding a tile
// the logged sets should be indicated even upon expanding/collapsing
// the timer could work better I think - need to ingtegrate with set logging
// fix notes - for now, they only work if you create a note after logging the sets
// Use datatable for target, rpe, weight, reps

// I think it may be more clear to change all imports to this package version
// then again, idk if it really matters
import 'package:firstapp/widgets/workout_stopwatch.dart';

class Workout extends StatefulWidget {
  final  ThemeData theme;
  const Workout({
    super.key,
    required this.theme,
  });

  @override
  State<Workout> createState() => _WorkoutState();
}

class _WorkoutState extends State<Workout> {
  int expandedTileIndex = 0;
  //bool _userHasInteracted = false; // Track if user has manually expanded/collapsed
  // Profile? _profile;
  // late final VoidCallback _profileListener;



  final Map<int, List<SetRecord>> _exerciseHistory = {};

  // will be false until all sets in an exercise are logged.


  void _preloadHistory() async {
    final dbHelper = DatabaseHelper.instance;
    int index = 0;

    final workoutProvider = context.read<ActiveWorkoutProvider>();
    int? primaryIndex = workoutProvider.activeDayIndex;

    if (primaryIndex != null && workoutProvider.sessionID != null){

      for (Exercise exercise
          in context.read<Profile>().exercises[primaryIndex]) {

        //debugPrint("exercises: ${exercise.exerciseTitle} : ${exercise.exerciseID}");
        final record = await dbHelper.getPreviousSessionSets(
          exercise.exerciseID, 
          workoutProvider.sessionID!,
        );
        //debugPrint("record found for exercise: ${record}");
        if (record.isNotEmpty) {
          _exerciseHistory[index] = record;
          // debugPrint("index: ${index}");
          // debugPrint("record for ID: ${exercise.exerciseID}");
          // debugPrint("record saved: ${_exerciseHistory[index]}");

        }
        index++;
      }
    }else{
      debugPrint("Primary index is null.");
    }

    //debugPrint("History: ${_exerciseHistory}");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }


  @override
  void initState() {
    super.initState();
    _preloadHistory();
  }

  @override
  void dispose() {
    //_timer?.cancel();
    //_profile?.removeListener(_profileListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = context.read<ActiveWorkoutProvider>();

    int? primaryIndex = workoutProvider.activeDayIndex;

    return GestureDetector(
      onTap: () {
        WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
        Provider.of<Profile>(context, listen: false).changeDone(false);
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        bottomSheet: context.watch<Profile>().done
            ? DoneButtonBottom(context: context, theme: widget.theme)
            : null,
            appBar: AppBar(
              title: Text(
                // this only happens for short period during transition from popping
                // so nobody should see the const value, it will hopefully blend in
                (primaryIndex != null && workoutProvider.activeDay != null) ? "Day ${primaryIndex + 1} • ${context.read<ActiveWorkoutProvider>().activeDay!.dayTitle}" : "Workout",
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80), // Increased height to accommodate the control bar
                child: WorkoutControlBar(
                  positionAtTop: true,
                  theme: widget.theme
                ),
              ),

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
        body: primaryIndex == null
            ? const Center(child: Text("Something Went Wrong."))
            : ListView.builder(
                itemCount:
                    context.watch<Profile>().exercises[primaryIndex].length,
                itemBuilder: (context, index) => exerciseBuild(context, index),
              ),
      ),
    );
  }

  Widget exerciseBuild(BuildContext context, int index) {
    int? primaryIndex = context.read<ActiveWorkoutProvider>().activeDayIndex;
    bool isNextSet = index == context.watch<ActiveWorkoutProvider>().nextSet[0];

    if (primaryIndex == null){
      return const SizedBox.shrink();
    }

    return Padding(
      key: ValueKey(context.watch<Profile>().exercises[primaryIndex][index]),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: isNextSet ? 2 : 1,
            color: isNextSet
                ? widget.theme.colorScheme.primary
                : widget.theme.colorScheme.outline,
          ),
          color: context.watch<ActiveWorkoutProvider>().isExerciseComplete[index] 
            ? widget.theme.colorScheme.primary.withAlpha((255 * 0.25).round()) 
            :widget.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            listTileTheme: const ListTileThemeData(
                contentPadding: EdgeInsets.only(left: 4, right: 16)),
          ),
          child: ExpansionTile(
            //key: ValueKey('${expandedTileIndex}_$index'),
            initiallyExpanded: context.read<ActiveWorkoutProvider>().expansionStates[index],
            controller: context.read<ActiveWorkoutProvider>().workoutExpansionControllers[index],
            onExpansionChanged: (isExpanded) {
              // track for saving purposes
              context.read<ActiveWorkoutProvider>().expansionStates[index] = isExpanded;
            },

            iconColor: widget.theme.colorScheme.onSurface,
            collapsedIconColor: widget.theme.colorScheme.onSurface,
            title: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      context
                          .watch<Profile>()
                          .exercises[primaryIndex][index]
                          .exerciseTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      // Toggle history visibility
                      context.read<ActiveWorkoutProvider>().showHistory![index] =
                          !context.read<ActiveWorkoutProvider>().showHistory![index];
                    });
                  },
                  icon: Icon(
                    context.watch<ActiveWorkoutProvider>().showHistory![index]
                        ? Icons.swap_horiz
                        : Icons.history,
                  ),
                ),
              ],
            ),
            children: context.watch<ActiveWorkoutProvider>().showHistory![index]
                ? [
                    _exerciseHistory.containsKey(index)
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Most Recent History:"),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: HistorySessionView(
                                    exerciseHistory: _exerciseHistory[index]!,
                                    theme: widget.theme,
                                  ),
                                ),
                                
                                        
                                TextButton(
                                    onPressed: () {
                                      _showFullHistoryModal(
                                        context
                                            .read<Profile>()
                                            .exercises[primaryIndex][index]
                                            .exerciseID,
                                        context
                                            .read<Profile>()
                                            .exercises[primaryIndex][index]
                                            .exerciseTitle,
                                      );
                                    },
                                    child: const Text("Show Full History")),
                              ],
                            ),
                          )
                        : const Align(
                            heightFactor: 3,
                            alignment: Alignment.center,
                            child:  Text("No History Found For This Exercise")
                          )
                  ]
                : [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        children: [
                          Text("Target"),
                          SizedBox(width: 125),
                          Text("RPE"),
                          SizedBox(width: 20),
                          Text("Weight"),
                          SizedBox(width: 20),
                          Text("Reps")
                        ],
                      ),
                    ),
                    SizedBox(
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: context.read<Profile>().sets[primaryIndex][index].length,
                        itemBuilder: (context, setIndex) {
                          return ListView.builder(

                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: context.read<Profile>().sets[primaryIndex][index][setIndex].numSets,
                          
                            itemBuilder: (context, subSetIndex){ 
                              return GymSetRow(
                                repsLower: context.read<Profile>().sets[primaryIndex][index][setIndex].setLower,
                                repsUpper: context.read<Profile>().sets[primaryIndex][index][setIndex].setUpper ?? 0,
                                expectedRPE: context.read<Profile>().sets[primaryIndex][index][setIndex].rpe?.toDouble() ?? 0.0,
                                exerciseIndex: index,
                                setIndex: setIndex,
                                rpeController: context.read<ActiveWorkoutProvider>().workoutRpeTEC[index][setIndex][subSetIndex],
                                repsController: context.read<ActiveWorkoutProvider>().workoutRepsTEC[index][setIndex][subSetIndex],
                                weightController: context.read<ActiveWorkoutProvider>().workoutWeightTEC[index][setIndex][subSetIndex],
                                //initiallyChecked: (context.read<Profile>().sets[primaryIndex][index][setIndex].loggedRecordID[subSetIndex] != null),
                                recordID: context.read<Profile>().sets[primaryIndex][index][setIndex].loggedRecordID[subSetIndex],
                                // either logs or unlogs a set
                                onChanged: (isChecked) async {
                                  int loggedRecordID = -1;
                                  final workoutProvider = context.read<ActiveWorkoutProvider>();

                                  // logs the set to the DB - sets loggedRecordID to be the ID of the set so we can referecne to update and delete
                                  if (isChecked) {

                                    // log the set
                                    loggedRecordID = await context.read<Profile>().logSet(
                                      SetRecord.fromDateTime(
                                        dayTitle: context.read<Profile>().split[primaryIndex].dayTitle,
                                        programTitle: context.read<Profile>().currentProgram.programTitle,

                                        sessionID: context.read<ActiveWorkoutProvider>().sessionID!,
                                        exerciseID: context.read<Profile>()
                                          .exercises[context.read<ActiveWorkoutProvider>().activeDayIndex!][index].exerciseID,
                                        date: DateTime.now(),
                                        numSets: 1,
                                        reps: double.parse(workoutProvider.workoutRepsTEC[index][setIndex][subSetIndex].text),
                                        weight: double.parse(workoutProvider.workoutWeightTEC[index][setIndex][subSetIndex].text),
                                        rpe: double.parse(workoutProvider.workoutRpeTEC[index][setIndex][subSetIndex].text),
                                        historyNote: workoutProvider.workoutNotesTEC[index].text,
                                      ),
                                      useMetric: context.read<SettingsModel>().useMetric,
                                    );

                                    // reset "rest since last set" stopwatch to zero once we log a set
                                    if (context.mounted) context.read<ActiveWorkoutProvider>().lastRestStartTime = DateTime.now();
                                  
                                  } else{
                                    if (context.read<Profile>().sets[primaryIndex][index][setIndex].loggedRecordID[subSetIndex] != null){
                                      context.read<Profile>().deleteLoggedSet(
                                        recordID: context.read<Profile>().sets[primaryIndex][index][setIndex].loggedRecordID[subSetIndex]!
                                      );
                                    } else{
                                      debugPrint("Cannot unlog set by referencing a null ID");
                                    }
                                    // unlog this set
                                  }


                                  setState(() {
                                    
                                    // Update the logged status
                                    if (isChecked){
                                      context.read<Profile>().sets[primaryIndex][index][setIndex]
                                      .loggedRecordID[subSetIndex] = loggedRecordID;
                                    } else{
                                      context.read<Profile>().sets[primaryIndex][index][setIndex]
                                      .loggedRecordID[subSetIndex] = null;
                                    }
                                    

                                    if (isChecked) {
                                      context.read<ActiveWorkoutProvider>().incrementSet([index, setIndex, subSetIndex]);
                                      
                                      // Handle exercise expansion/collapse
                                      if (context.read<ActiveWorkoutProvider>().nextSet[0] != index) {
                                        context.read<ActiveWorkoutProvider>().workoutExpansionControllers[
                                          context.read<ActiveWorkoutProvider>().nextSet[0]
                                        ].expand();
                                        context.read<ActiveWorkoutProvider>().expansionStates[
                                          context.read<ActiveWorkoutProvider>().nextSet[0]
                                        ] = true;

                                        context.read<ActiveWorkoutProvider>().workoutExpansionControllers[index].collapse();
                                        context.read<ActiveWorkoutProvider>().expansionStates[index] = false;
                                      }
                                    }

                                    // just learned you can label loops to break out fully. The more you know.
                                    // Improved all-logged check
                                    
                                    bool allLogged = true;

                                    // if no set in the exercise is yet to be logged, we mark the exercise as entirely logged and complete
                                    outerLoop: // Label for the outer loop
                                    for (final workoutSet in context.read<Profile>().sets[primaryIndex][index]) {
                                      for (int j = 0; j < workoutSet.loggedRecordID.length; j++) {
                                        if ((workoutSet.loggedRecordID[j] == null)) {
                                          allLogged = false;
                                          break outerLoop; // Break both loops immediately
                                        }
                                      }
                                    }

                                    // Update exercise completion status
                                    context.read<ActiveWorkoutProvider>().isExerciseComplete[index] = allLogged;
                                  });
                                },
                              );
                            }
                          );
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4),
                        child: Container(
                          width: 70,
                          height: 30,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha((255 * 0.5).round()),
                                offset: const Offset(0.0, 0.0),
                                blurRadius: 12.0,
                              ),
                            ],
                          ),
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.only(
                                  top: 0, bottom: 0, right: 0, left: 8),
                              backgroundColor: widget.theme.colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      width: 2, color: widget.theme.colorScheme.primary),
                                  borderRadius:
                                      const BorderRadius.all(Radius.circular(8))),
                            ),
                            onPressed: () {
                              context.read<Profile>().setsAppend(
                                    index1: primaryIndex,
                                    index2: index,
                                  );
                              context.read<ActiveWorkoutProvider>().isExerciseComplete[index] = false;
                              setState(() {});
                            },
                            label: Row(
                              children: [
                                Icon(Icons.add,
                                    color: widget.theme.colorScheme.onSurface),
                                Text("Set",
                                    style: TextStyle(
                                        color: widget.theme.colorScheme.onSurface),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Focus(
                        onFocusChange: (hasFocus) {
                          if (!hasFocus)  {
                            // Save when focus is lost
                            final notes = context.read<ActiveWorkoutProvider>().workoutNotesTEC[index].text;
                            _updateSetNotesInDB(
                              context.read<ActiveWorkoutProvider>().sessionID!,
                              context.read<Profile>().exercises[primaryIndex][index].exerciseID,
                              notes
                            );
                          }
                        },

                        child: TextFormField(
                          keyboardType: TextInputType.multiline,
                          minLines: 2,
                          maxLines: null,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).scaffoldBackgroundColor,
                            contentPadding:
                                const EdgeInsets.only(bottom: 10, left: 8),
                            // border: const OutlineInputBorder(
                            //     borderRadius:
                            //         BorderRadius.all(Radius.circular(8))),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.blue),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.red, width: 2),
                            ),  
                            hintText: "Notes: ",
                          ),
                        
                          controller: context.watch<ActiveWorkoutProvider>().workoutNotesTEC[index],
                        
                        ),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }


  void _showFullHistoryModal(int exerciseId, String exerciseTitle) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final dbHelper = DatabaseHelper.instance;
    try {
      final records = await dbHelper.getExerciseHistoryGroupedBySession(exerciseId);

      if (!mounted) return;

      Navigator.of(context).pop();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => _buildHistoryBottomSheet(records, exerciseTitle),
      );
    } catch (e) {
      debugPrint("Error fetching history: $e");
      if (!mounted) return;

      Navigator.of(context).pop();
      showModalBottomSheet(
        context: context,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Error loading history: ${e.toString()}"),
        ),
      );
    }
  }

  Widget _buildHistoryBottomSheet(
      List<List<SetRecord>> records, String title) {
    //final history = records.map((record) => SetRecord.fromMap(record)).toList();

    if (records.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("No History Found",
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 24),
              Text("No recorded sets found for $title"),
            ],
          ),
        ),
      );
    }

    // Ion think I am using pagination here, seems ok for now 
    // but could be added in the future just like how ive done for analytics page to speed up loads
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text("History for $title",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: records.length + 1,
                  itemBuilder:(context, index) {
                    if (index == records.length){
                      return const Text(
                        "End of History"
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0
                      ),
                      child: HistorySessionView(
                        exerciseHistory: records[index], 
                        theme: widget.theme
                      ),
                    );
                    
                  }, 
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _updateSetNotesInDB(String sessionID, int exerciseID, String note) async {
    final db = DatabaseHelper.instance;

    await db.updateSetNotes(sessionId: sessionID, exerciseId: exerciseID, note: note);

  }
}
