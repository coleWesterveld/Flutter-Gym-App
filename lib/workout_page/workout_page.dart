// workout page
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../user.dart';
//import 'package:flutter/cupertino.dart';
//import '../schedule_page/schedule_page.dart';
import 'set_logging.dart';
import '../other_utilities/lightness.dart';
import 'dart:async';


// for set logging this is how it should prolly be done:
// when the user opens an active workout, it should create a "session" which buffers the setdata in memory
// when they are working out, maybe it would be good to load up the history for that exercise in the background so that it is fast to retrieve
// TODO: fix animations here. I have an error 

class Workout extends StatefulWidget {
  const Workout({
    super.key,
  });

  @override
  State<Workout> createState() => _WorkoutState();
}

class _WorkoutState extends State<Workout> {
  // -1 indicates no tile is expanded.
  int expandedTileIndex = 0; 

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No need to initialize controllers here
  }

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();

    final profile = context.read<Profile>();
    expandedTileIndex = profile.nextSet[0];

    profile.addListener(() {
      if (mounted) {
        setState(() {
          expandedTileIndex = profile.nextSet[0];
        });
      }
    });
    
    _startStopwatch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    context.read<Profile>().removeListener(() {});
    super.dispose();
  }

  void _startStopwatch() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // Update UI every second
      }
    });
  }

  void _stopStopwatch() {
    _stopwatch.stop();
    _timer?.cancel();
  }


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
                    top: BorderSide(
                      color: lighten(Color(0xFF141414), 20),
                    ),
                  ),
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
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        backgroundColor: WidgetStateProperty.all(Color(0xFF6c6e6e)),
                      ),
                      onPressed: () {
                        WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
                        context.read<Profile>().done = false;
                        setState(() {});
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(color: Colors.white),
                      ),
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
            preferredSize: const Size.fromHeight(50), // Adjust height as needed
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Stopwatch Text (Placeholder for now)
                  Container(
                    height: 40,
                    width: 110,
                    decoration: BoxDecoration(
                      
                      color: _isPaused ? lighten( Color(0xFF1e2025), 10) : darken( Color(0xFF1e2025), 10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(width: 2, color: lighten( Color(0xFF1e2025), 20) /*_isPaused ? lighten(Colors.blue, 10): Colors.blue*/)
                    ),
                    child: Center(
                      child: Text(
                        _formatTime(_stopwatch.elapsedMilliseconds), // Replace this with a real stopwatch widget
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:  Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Finish Button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
          onPressed: () {
            if (_isPaused) {
              _startStopwatch();
            } else {
              _stopStopwatch();
            }
            setState(() {
              _isPaused = !_isPaused;
            });
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: _isPaused ? lighten( Color(0xFF1e2025), 10) : null,
            minimumSize: const Size(90, 40),
            side: const BorderSide(color: Colors.blue, width: 2), // Blue outline
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            _isPaused ? "Resume" : "Pause",
            style: const TextStyle(color: Colors.blue), // Blue text
          ),
        ),

                      SizedBox(width: 8),
                      // Finish Button
                  ElevatedButton(

                    onPressed: () {
                      // Handle finish button tap
                      
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(90, 40), // Set width and height
                      
                      backgroundColor:  Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Border radius set to 8
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      "Finish",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                    ],
                  ),

                  
                ],
              ),
            ),
          ),
        ),

        body: primaryIndex == null
            ? Center(child: Text("Something Went Wrong."))
            : ListView.builder(
                itemCount: context.watch<Profile>().exercises[primaryIndex].length,
                itemBuilder: (context, index) {
                  return exerciseBuild(context, index);
                },
              ),
      ),
    );
  }

  Padding exerciseBuild(BuildContext context, int index) {
    int? primaryIndex = context.read<Profile>().activeDayIndex;

    return Padding(
      key: ValueKey(context.watch<Profile>().exercises[primaryIndex!][index]),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          // the colour should maybe change with what is reccomended to be next (next after most recently logged set)
          // but for now its fine IG
          border: Border.all(width: (index == context.watch<Profile>().nextSet[0]) ? 2 :1,color: (index == context.watch<Profile>().nextSet[0]) ? Colors.blue : lighten(const Color(0xFF141414), 20)),
          color: const Color(0xFF1e2025),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            listTileTheme: const ListTileThemeData(
              contentPadding: EdgeInsets.only(left: 4, right: 16),
            ),
          ),
          child: ExpansionTile(
            // Use a unique key that changes based on expansion state
            key: ValueKey(expandedTileIndex == index ? "expanded_$index" : "collapsed_$index"),
            initiallyExpanded: expandedTileIndex == index,
            onExpansionChanged: (isExpanded) {
              // When a tile is expanded, update the state variable to rebuild tiles
              setState(() {
                if (isExpanded) {
                  expandedTileIndex = index;
                } else if (expandedTileIndex == index) {
                  expandedTileIndex = -1; // none expanded
                }
              });
            },
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            title: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      context.watch<Profile>().exercises[primaryIndex][index].exerciseTitle,
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
              ],
            ),
            children: context.watch<Profile>().showHistory![index]
                ? [Text("Hello there")]
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
                          return GymSetRow(
                            prevWeight: 12,
                            prevReps: 5,
                            expectedRPE: 8,
                            expectedReps: 5,
                            expectedWeight: 200,
                            exerciseIndex: index,
                            setIndex: setIndex,
                          );
                        },
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
                          contentPadding: const EdgeInsets.only(bottom: 10, left: 8),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
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
}
