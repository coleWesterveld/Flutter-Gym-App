// workout page
//not updated
import 'package:firstapp/providers_and_settings/active_workout_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers_and_settings/program_provider.dart';
//import 'package:flutter/cupertino.dart';
import '../schedule_page/schedule_page.dart';
import 'workout_page.dart';
import '../other_utilities/days_between.dart';
import '../other_utilities/lightness.dart';
import '../providers_and_settings/settings_page.dart';

class WorkoutSelectionPage extends StatefulWidget {
  final ThemeData theme;
  const WorkoutSelectionPage({
    required this.theme,
    super.key,
  });

  @override
  State<WorkoutSelectionPage> createState() => WorkoutSelectionPageState();
}

class WorkoutSelectionPageState extends State<WorkoutSelectionPage>
  with SingleTickerProviderStateMixin {

  late AnimationController _pulseController;

  List<ExpansionTileController> _expansionControllers = [];
  // States tracked separately to maintain collapse/open state across rebuilds and profile.split size changes
  List<bool> _expansionStates = [];


    // Method for TutorialManager to expand a tile
  void expandTile(int index) {
    if (mounted && index >= 0 && index < _expansionControllers.length) {
        // Collapse others if needed (optional, depends on desired tutorial behavior)
        // for (int i = 0; i < _expansionControllers.length; i++) {
        //   if (i != index && _expansionControllers[i].isExpanded) {
        //     _expansionControllers[i].collapse();
        //   }
        // }
        if (!_expansionControllers[index].isExpanded) {
             print("Expanding tile programmatically: $index");
            _expansionControllers[index].expand();
            // Update internal state if you rely on _expansionStates
             if (index < _expansionStates.length) {
                 _expansionStates[index] = true;
             }
             setState(() {}); // Trigger rebuild if needed
        } else {
           print("Tile already expanded: $index");
        }
    } else {
       print("Error expanding tile: index $index out of bounds or not mounted.");
    }
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final profile = Provider.of<Profile>(context);
    if (_expansionControllers.length != profile.split.length) {
      _initializeControllersAndStates();
    }

  }

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    )..repeat(reverse: true); // Continuously animates back and forth
  }

  @override
  void dispose() {
    _pulseController.dispose();

    // for (var controller in _expansionControllers) {
    //   controller.dispose()
    // }

    super.dispose();
  }

   // Initialize or update controllers when split length changes
  void _initializeControllersAndStates() {
    final profile = Provider.of<Profile>(context, listen: false);
    
    // Save current expansion states before recreating
    final oldStates = _expansionStates.asMap();
    
    // Create new controllers and states
    _expansionControllers = List.generate(
      profile.split.length,
      (index) => ExpansionTileController(),
    );
    
    // Initialize states - preserve old states where possible
    _expansionStates = List.generate(
      profile.split.length,
      (index) => oldStates[index] ?? (index == toExpand()),
    );
  }

  DateTime today = DateTime.now();

  DateTime startDay = DateTime(2024, 8, 10);

  int toExpand() {
    DateTime origin = DateTime(2024, 1, 7);
    int index =
        daysBetween(origin, today) % context.watch<Profile>().splitLength;

    if (index < context.watch<Profile>().split.length) {
      return index;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<Profile>().isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    
    int todaysWorkout = toExpand();
    return SizedBox(
      //height: MediaQuery.of(context).size.height - (265),
      child: ListView.builder(
        // building the rest of the tiles, one for each day from split list stored in user
        //dismissable and reorderable: each child for dismissable needs to have a unique key
        itemCount: (todaysWorkout == -1)
            ? context.watch<Profile>().split.length + 1
            : context.watch<Profile>().split.length,

        itemBuilder: (context, index) {
          if (todaysWorkout != -1) {
            if (index == 0) {
              return dayBuild(
                  context, todaysWorkout, true);
            } else if (index <= todaysWorkout) {
              return dayBuild(
                  context, index - 1, false);
            } else {
              return dayBuild(context, index, false);
            }
          } else {
            return dayBuild(context, index - 1, false);
          }
        },
      ),
    );
    
  }

  Padding dayBuild(BuildContext context, int index, bool todaysWorkout) {
    if (!todaysWorkout && index == -1) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Center(
          child: Text("No Workout Scheduled For Today",
            style: TextStyle(
              //height: 0.5,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: widget.theme.colorScheme.onSurface
            )
          )
        ),
      );
    } else {
      return Padding(
          key: ValueKey(context.watch<Profile>().split[index]),
          padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: (!todaysWorkout && index == 0) ? 8 : 8),

          child: Container(
            // TODO: dont like how this goes all the way down under "start workout" button and stuff,
            decoration: BoxDecoration(
    
              border: Border.all(color: widget.theme.colorScheme.outline),
              boxShadow: [
                todaysWorkout
                    ? BoxShadow(
                        color: Color(context.watch<Profile>().split[index].dayColor),
                        offset: const Offset(0.0, 0.0),
                        blurRadius: 8.0,
                      )
                    : const BoxShadow(),
              ],
              color: widget.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
            ),

            //defining the inside of the actual box, display information
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                listTileTheme: const ListTileThemeData(
                  contentPadding: EdgeInsets.only(
                      left: 4, right: 16), // Removes extra padding
                ),
              ),

              //expandable to see exercises and sets for that day
              child: ExpansionTile(
                  controller: _expansionControllers[index],
                  key: ValueKey(context.watch<Profile>().split[index]),
                  onExpansionChanged: (isExpanded) {
                    if (isExpanded){
                      setState(() {
                        for (int i = 0; i < _expansionControllers.length; i++) {
                          if (i != index) {
                            _expansionControllers[i].collapse();
                          }
                        }
                      });
                    }
                  },
                  initiallyExpanded: todaysWorkout,
                  //initiallyExpanded: toExpand(index),
                  //controller: context.watch<Profile>().controllers[index],
                  iconColor: widget.theme.colorScheme.onSurface,
                  collapsedIconColor: widget.theme.colorScheme.onSurface,

                  //top row always displays day title, and edit button
                  //sized boxes and padding is just a bunch of formatting stuff
                  //tbh it could probably be made more concise
                  //TODO: simplify this
                  title: SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 30,
                            width: 100,
                            child: Row(
                              children: [
                                //number
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    "${index + 1}",

                                    style: TextStyle(
                                      height: 0.6,
                                      color: Color(context.watch<Profile>().split[index].dayColor),
                                      fontSize: 50,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    

                                    //day title
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: SizedBox(
                                    width:  MediaQuery.sizeOf(context).width - 138,
                                    child: Text(
                                      overflow: TextOverflow.ellipsis,
                                      context.watch<Profile>().split[index].dayTitle,
                                      style: TextStyle(
                                        color: widget.theme.colorScheme.onSurface,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  //children of expansion tile - what gets shown when user expands that day
                  // shows exercises for that day
                  //this part is viewed after tile is expanded
                  //TODO: show sets per exercise, notes, maybe most recent weight/reps
                  //exercises are reorderable
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.surface,
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(12.0),
                            bottomLeft: Radius.circular(12.0)),
                      ),
                      child: ListView.builder(
                        //being able to scroll within the already scrollable day view
                        // is annoying so i disabled it
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            context.read<Profile>().exercises[index].length +
                                1,
                        shrinkWrap: true,

                        //displaying list of exercises for that day

                        itemBuilder: (context, exerciseIndex) {
                          if (exerciseIndex ==
                              context
                                  .read<Profile>()
                                  .exercises[index]
                                  .length) {
                            return Padding(
                              padding: const EdgeInsets.all(8),
                              child: todaysWorkout
                                  ? AnimatedBuilder(
                                      animation: _pulseController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: 1 +
                                              0.05 *
                                                  _pulseController
                                                      .value, // Slightly bigger and smaller
                                          child: child,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: ElevatedButton(
                                            style: ButtonStyle(
                                              //when clicked, it splashes a lighter purple to show that button was clicked
                                              shape: WidgetStateProperty.all(
                                                  RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12))),
                                              backgroundColor:
                                                  WidgetStateProperty.all(
                                                widget.theme.colorScheme.primary,
                                              ),
                                              overlayColor: WidgetStateProperty
                                                  .resolveWith<Color?>(
                                                      (states) {
                                                if (states.contains(
                                                    WidgetState.pressed)) {
                                                  return  widget.theme.colorScheme.primary;
                                                }
                                                return null;
                                              }),
                                            ),
                                            onPressed: () {
                                              Navigator.push<bool>(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => Workout(theme: widget.theme)),
                                                )
                                                .then((finished) {
                                                  if (finished == true) {
                                                    // only clear activeDay once the Workout route is fully popped
                                                    context.read<ActiveWorkoutProvider>().setActiveDay(null);
                                                  }
                                                });
                                              
                                              // Navigator.push(
                                              //     context,
                                              //     MaterialPageRoute(
                                              //       builder: (context) =>
                                              //           const Workout(),
                                              //     ));
                                              context.read<ActiveWorkoutProvider>().generateWorkoutSessionId();
                                              context.read<ActiveWorkoutProvider>().setActiveDay(index);
                                            },
                                            child: const Text(
                                              "Start This Workout",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800),
                                            )),
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: ElevatedButton(
                                          style: ButtonStyle(
                                            //when clicked, it splashes a lighter purple to show that button was clicked
                                            shape: WidgetStateProperty.all(
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12))),
                                            backgroundColor:
                                                WidgetStateProperty.all(
                                               widget.theme.colorScheme.primary,
                                            ),
                                            overlayColor: WidgetStateProperty
                                                .resolveWith<Color?>((states) {
                                              if (states.contains(
                                                  WidgetState.pressed)) {
                                                return  widget.theme.colorScheme.primary;
                                              }
                                              return null;
                                            }),
                                          ),
                                          onPressed: () {
                                            context.read<ActiveWorkoutProvider>().generateWorkoutSessionId();
                                            context.read<ActiveWorkoutProvider>().setActiveDay(index);
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                    Workout(theme: widget.theme),
                                                ));
                                          },
                                          child: Text(
                                            "Start This Workout",
                                            style: TextStyle(
                                                color: widget.theme.colorScheme.onPrimary,
                                                fontWeight: FontWeight.w800),
                                          )),
                                    ),
                            );
                          } else {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(Radius.circular(1)),
                                border: Border(bottom: BorderSide(color: widget.theme.colorScheme.outline),),
                              ),
                              child: Material(
                                color:widget.theme.colorScheme.surface,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                            Align(
                                              alignment: Alignment.topLeft,
                                              child: Padding(
                                                padding: const EdgeInsets.all(12.0),
                                                child: SizedBox(
                                                  width: MediaQuery.sizeOf(context).width - 172,
                                                  child: Text(
                                                    overflow: TextOverflow.visible,
                                                    //softWrap: true,
                                                    context.watch<Profile>().exercises[index][exerciseIndex].exerciseTitle,
                                                    style: TextStyle(
                                                      color: widget.theme.colorScheme.onSurface,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                            height: context.watch<Profile>().sets[index][exerciseIndex].length * 20 + 16,
                                            width: 100,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: ListView(
                                                physics: const NeverScrollableScrollPhysics(),
                                                children: [
                                                  for(int i = 0; i < context.watch<Profile>().sets[index][exerciseIndex].length; i++) 
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 24.0),
                                                      child: Center(
                                                        child: Text(
                                                          "${context.watch<Profile>().sets[index][exerciseIndex][i].numSets} x (${context.watch<Profile>().sets[index][exerciseIndex][i].setLower}-${context.watch<Profile>().sets[index][exerciseIndex][i].setUpper})",
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                          )
                                                          ),
                                                      ),
                                                    ),
                                                ]
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ]),
            ),
          ));
    }
  }
}
