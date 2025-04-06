import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../user.dart';
import 'set_logging.dart';
import '../other_utilities/lightness.dart';
import 'dart:async';
import '../database/database_helper.dart';
import '../database/profile.dart';
import 'package:intl/intl.dart';

// list todo: 
// TACKLING: expanded index should expand once, initially, and when a user finishes an exercise, but should not interfere further with user interaction
// the text should remain in the fields even upon closing/expanding a tile
// the logged sets should be indicated even upon expanding/collapsing
// the timer could work better I think - need to ingtegrate with set logging

// I think it may be more clear to change all imports to this package version
// then again, idk if it really matters
import 'package:firstapp/other_utilities/workout_stopwatch.dart';

class Workout extends StatefulWidget {
  const Workout({super.key});

  @override
  State<Workout> createState() => _WorkoutState();
}

class _WorkoutState extends State<Workout> {
  int expandedTileIndex = 0;
  //bool _userHasInteracted = false; // Track if user has manually expanded/collapsed
  // Profile? _profile;
  // late final VoidCallback _profileListener;



  Map<int, SetRecord> _exerciseHistory = {};
  List<SetRecord> _fullHistory = [];

  Map<int, bool> isExerciseComplete = {}; // will be false until all sets in an exercise are logged.

  void _preloadHistory() async {
    final dbHelper = DatabaseHelper.instance;
    int index = 0;
    int? primaryIndex = context.read<Profile>().activeDayIndex;
    for (Exercise exercise
        in context.read<Profile>().exercises[primaryIndex!]) {
      final record = await dbHelper.fetchSetRecords(
          exerciseId: exercise.exerciseID, lim: 1);
      if (record.isNotEmpty) {
        _exerciseHistory[index] = (SetRecord.fromMap(record[0]));
      }
      index++;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // if (_profile == null) {
    //   _profile = Provider.of<Profile>(context, listen: false);
    //   expandedTileIndex = _profile!.nextSet[0]; // Initial expansion
    //   _profileListener = () {
    //     if (mounted /*&& !_userHasInteracted*/) { // Only auto-expand if no interaction
    //       setState(() {
    //         expandedTileIndex = _profile!.nextSet[0];
    //       });
    //     }
    //   };
    //   _profile!.addListener(_profileListener);
    // }
  }

  @override
  void initState() {
    super.initState();
    _preloadHistory();
    _startStopwatch();
  }

  @override
  void dispose() {
    //_timer?.cancel();
    //_profile?.removeListener(_profileListener);
    super.dispose();
  }

  void _startStopwatch() {
    context.read<Profile>().workoutStopwatch.start();
    // _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    //   if (mounted) setState(() {});
    // });
  }

  void _handleExerciseSelected(int id) async {
    setState(() {
      _fullHistory = [];
    });

    final dbHelper = DatabaseHelper.instance;
    try {
      final records = await dbHelper.fetchSetRecords(exerciseId: id);
      if (mounted) {
        setState(() {
          _fullHistory =
              records.map((record) => SetRecord.fromMap(record)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
      if (mounted) {
        setState(() {
          _fullHistory = [];
        });
      }
    }
  }

  // void _stopStopwatch() {
  //   _stopwatch.stop();
  //   _timer?.cancel();
  // }

  String _formatTime(int milliseconds) {
    int seconds = (milliseconds / 1000).truncate();
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${remainingSeconds.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    int? primaryIndex = context.read<Profile>().activeDayIndex;

    return GestureDetector(
      onTap: () {
        WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
        Provider.of<Profile>(context, listen: false).changeDone(false);
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        bottomSheet: context.watch<Profile>().done
            ? Container(
                decoration: BoxDecoration(
                  border: Border(
                      top: BorderSide(color: lighten(Color(0xFF141414), 20))),
                  color: Color(0xFF1e2025),
                ),
                height: 50,
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4))),
                        backgroundColor:
                            WidgetStateProperty.all(Color(0xFF6c6e6e)),
                      ),
                      onPressed: () {
                        WidgetsBinding.instance.focusManager.primaryFocus
                            ?.unfocus();
                        context.read<Profile>().done = false;
                        setState(() {});
                      },
                      child: const Text('Done',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              )
            : null,
            appBar: AppBar(
              backgroundColor: const Color(0xFF1e2025),
              title: Text(
                "Day ${primaryIndex! + 1} • ${context.watch<Profile>().activeDay!.dayTitle}",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80), // Increased height to accommodate the control bar
                child: WorkoutControlBar(
                  positionAtTop: true,
                ),
              ),
            ),
        // appBar: AppBar(
        //   backgroundColor: const Color(0xFF1e2025),
        //   title: Text(
        //     "Day ${primaryIndex! + 1} • ${context.watch<Profile>().activeDay!.dayTitle}",
        //     style: TextStyle(fontWeight: FontWeight.w900),
        //   ),
        //   bottom: PreferredSize(
        //     preferredSize: const Size.fromHeight(50),
        //     child: Padding(
        //       padding: const EdgeInsets.symmetric(horizontal: 8.0),
        //       child: Row(
        //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //         children: [
        //           Container(
        //             height: 40,
        //             width: 110,
        //             decoration: BoxDecoration(
        //                 color: context.read<Profile>().isPaused
        //                     ? lighten(Color(0xFF1e2025), 10)
        //                     : darken(Color(0xFF1e2025), 10),
        //                 borderRadius: BorderRadius.circular(12),
        //                 border: Border.all(
        //                     width: 2, color: lighten(Color(0xFF1e2025), 20))),
        //             child: Center(
        //               child: Text(
        //                 _formatTime(context.read<Profile>().workoutStopwatch.elapsedMilliseconds),
        //                 style: TextStyle(
        //                   fontSize: 18,
        //                   fontWeight: FontWeight.bold,
        //                   color: Colors.white,
        //                 ),
        //               ),
        //             ),
        //           ),
        //           Row(
        //             mainAxisSize: MainAxisSize.min,
        //             children: [
        //               OutlinedButton(
        //                 onPressed: () {
        //                   context.read<Profile>().togglePause();
        //                   setState(() {
        //                     context.read<Profile>().isPaused = !context.read<Profile>().isPaused;
        //                   });
        //                 },
        //                 style: OutlinedButton.styleFrom(
        //                   backgroundColor:
        //                       context.read<Profile>().isPaused ? lighten(Color(0xFF1e2025), 10) : null,
        //                   minimumSize: const Size(90, 40),
        //                   side: const BorderSide(color: Colors.blue, width: 2),
        //                   shape: RoundedRectangleBorder(
        //                       borderRadius: BorderRadius.circular(12)),
        //                   padding: const EdgeInsets.symmetric(
        //                       horizontal: 16, vertical: 8),
        //                 ),
        //                 child: Text(
        //                   context.read<Profile>().isPaused ? "Resume" : "Pause",
        //                   style: const TextStyle(color: Colors.blue),
        //                 ),
        //               ),
        //               const SizedBox(width: 8),
        //               ElevatedButton(
        //                 onPressed: () {},
        //                 style: ElevatedButton.styleFrom(
        //                   minimumSize: const Size(90, 40),
        //                   backgroundColor: Colors.blue,
        //                   shape: RoundedRectangleBorder(
        //                       borderRadius: BorderRadius.circular(12)),
        //                   padding: const EdgeInsets.symmetric(
        //                       horizontal: 16, vertical: 8),
        //                 ),
        //                 child: const Text("Finish",
        //                     style: TextStyle(color: Colors.white)),
        //               ),
        //             ],
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        //),
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

  Padding exerciseBuild(BuildContext context, int index) {
    int? primaryIndex = context.read<Profile>().activeDayIndex;
    bool isNextSet = index == context.watch<Profile>().nextSet[0];

    return Padding(
      key: ValueKey(context.watch<Profile>().exercises[primaryIndex!][index]),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              width: isNextSet ? 2 : 1,
              color: isNextSet
                  ? Colors.blue
                  : lighten(const Color(0xFF141414), 20)),
          color: const Color(0xFF1e2025),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            listTileTheme: const ListTileThemeData(
                contentPadding: EdgeInsets.only(left: 4, right: 16)),
          ),
          child: ExpansionTile(
            key: ValueKey('${expandedTileIndex}_$index'),
            initiallyExpanded: expandedTileIndex == index,
            controller: context.read<Profile>().workoutExpansionControllers[index],
            // onExpansionChanged: (isExpanded) {
            //   setState(() {
            //     if (isExpanded) {
            //       expandedTileIndex = index;
            //       //_userHasInteracted = true;
            //     } else if (expandedTileIndex == index) {
            //       expandedTileIndex = -1;
            //     }
            //   });
            // },
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      // Expand the tile if not already expanded
                      if (expandedTileIndex != index) {
                        expandedTileIndex = index;
                        //_userHasInteracted = true;
                      }
                      // Toggle history visibility
                      context.read<Profile>().showHistory![index] =
                          !context.read<Profile>().showHistory![index];
                    });
                  },
                  icon: Icon(
                    context.watch<Profile>().showHistory![index]
                        ? Icons.swap_horiz
                        : Icons.history,
                  ),
                ),
              ],
            ),
            children: context.watch<Profile>().showHistory![index]
                ? [
                    _exerciseHistory.containsKey(index)
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("History From Last Session: "),
                                ListTile(
                                  title: Text(
                                      "${_exerciseHistory[index]!.numSets} sets x ${_exerciseHistory[index]!.reps} reps @ ${_exerciseHistory[index]!.weight} lbs (RPE: ${_exerciseHistory[index]!.rpe})"),
                                  subtitle: _exerciseHistory[index]!
                                                  .historyNote !=
                                              null &&
                                          _exerciseHistory[index]!
                                              .historyNote!
                                              .isNotEmpty
                                      ? Text(
                                          "Notes: ${_exerciseHistory[index]!.historyNote}")
                                      : null,
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
                        : const Text("No History Found For This Exercise")
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
                        itemCount: context
                            .read<Profile>()
                            .sets[primaryIndex][index]
                            .length,
                        itemBuilder: (context, setIndex) {
                          return GymSetRow(
                            prevWeight: 12,
                            prevReps: 5,
                            expectedRPE: 8,
                            expectedReps: 5,
                            expectedWeight: 200,
                            exerciseIndex: index,
                            setIndex: setIndex,
                            initiallyChecked: context.read<Profile>().sets[primaryIndex][index][setIndex].hasBeenLogged,
                            
                            
                            onChanged: (isChecked){
                              // record that the set has been completed 
                              setState(() {
                                context.read<Profile>().sets[primaryIndex][index][setIndex].hasBeenLogged = isChecked;
                                if (isChecked){
                                  context.read<Profile>().incrementSet([index, setIndex]);
                                  

                                  // if moving on to a new exercise, expand new and close old
                                  if (context.read<Profile>().nextSet[0] != index){
                                    context.read<Profile>().workoutExpansionControllers[
                                      context.read<Profile>().nextSet[0]
                                    ].expand();

                                    context.read<Profile>().workoutExpansionControllers[index].collapse();
                                  }
                                }
                              });
                              //debugPrint("stuff: ${context.read<Profile>().sets[primaryIndex][index][setIndex].hasBeenLogged}");
                            },
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
                                color: Colors.black.withOpacity(0.5),
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
                              backgroundColor: const Color(0xFF1e2025),
                              shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                      width: 2, color: Color(0XFF1A78EB)),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8))),
                            ),
                            onPressed: () {
                              debugPrint("exercise at $primaryIndex, $index");
                              context.read<Profile>().setsAppend(
                                    index1: primaryIndex,
                                    index2: index,
                                  );
                              setState(() {});
                            },
                            label: Row(
                              children: [
                                Icon(Icons.add,
                                    color: lighten(Color(0xFF141414), 70)),
                                Text("Set",
                                    style: TextStyle(
                                        color: lighten(Color(0xFF141414), 70))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextFormField(
                        keyboardType: TextInputType.multiline,
                        minLines: 2,
                        maxLines: null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1e2025),
                          contentPadding:
                              const EdgeInsets.only(bottom: 10, left: 8),
                          border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8))),
                          hintText: "Notes: ",
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
      final records = await dbHelper.fetchSetRecords(exerciseId: exerciseId);

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
      List<Map<String, dynamic>> records, String title) {
    final history = records.map((record) => SetRecord.fromMap(record)).toList();

    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("No History Found",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text("No recorded sets found for $title"),
          ],
        ),
      );
    }

    final groupedHistory = <String, List<SetRecord>>{};
    for (var record in history) {
      if (record.dateAsDateTime == null) continue;
      final date = DateFormat('yyyy-MM-dd').format(record.dateAsDateTime);
      groupedHistory.putIfAbsent(date, () => []).add(record);
    }

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
                child: ListView(
                  controller: scrollController,
                  children: [
                    ...groupedHistory.entries.map((entry) {
                      final date = entry.key;
                      final records = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(date,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          ...records
                              .map((record) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              "${record.numSets} sets × ${record.reps} reps @ ${record.weight} lbs",
                                              style: const TextStyle(
                                                  fontSize: 16)),
                                          if (record.rpe != null)
                                            Text("RPE: ${record.rpe}"),
                                          if (record.historyNote?.isNotEmpty ??
                                              false)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 8.0),
                                              child: Text(
                                                "Notes: ${record.historyNote}",
                                                style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontStyle:
                                                        FontStyle.italic),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ))
                              .toList(),
                          const SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
