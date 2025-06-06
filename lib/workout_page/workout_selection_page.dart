// workout selection page

// TODO: allow user to adjust program from within workout - just once or permanently
// Im thinkin we add them to the program just as we normally would, but we give em a flag 'temporairy' and then after finish is pressed we delete any temp.
// also if theyre temporary we prolly dont want to display them on the program page since theyre not so official ykyk

import 'package:firstapp/app_tutorial/app_tutorial_keys.dart';
import 'package:firstapp/app_tutorial/tutorial_manager.dart';
import 'package:firstapp/providers_and_settings/active_workout_provider.dart';
import 'package:firstapp/providers_and_settings/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import '../providers_and_settings/program_provider.dart';
//import 'package:flutter/cupertino.dart';
import '../schedule_page/schedule_page.dart';
import 'workout_page.dart';
import '../other_utilities/days_between.dart';
import '../other_utilities/lightness.dart';
import '../providers_and_settings/settings_page.dart';
import 'package:firstapp/other_utilities/events.dart';

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
  void expandTile({int? index}) {
    
    if (!mounted) {
       print("Error expanding tile: WorkoutSelectionPageState not mounted.");
       return;
    }

    // Determine the target index if not provided
    int targetIndex;
    if (index == null) {
      final expand = toExpand(); // Assumes toExpand() gets the correct index
      // Handle the case where toExpand might return an invalid index or -1
      if (expand < 0 || expand >= _expansionControllers.length) {
          print("Warning: toExpand() returned invalid index $expand. Defaulting to 0.");
          targetIndex = 0; // Default to the first tile if calculation fails
      } else {
          targetIndex = expand;
      }
    } else {
      targetIndex = index;
    }

    // Final check for index bounds *before* the callback
    if (targetIndex < 0 || targetIndex >= _expansionControllers.length) {
       print("Error expanding tile: targetIndex $targetIndex out of bounds (0-${_expansionControllers.length - 1}).");
       return;
    }

    // Use addPostFrameCallback to defer the expansion logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
        // Re-check mounted status and index validity *inside* the callback,
        // as the state could have changed between scheduling and execution.
        if (mounted && targetIndex < _expansionControllers.length) {
            final controller = _expansionControllers[targetIndex];

            // Check if it needs expanding
            if (!controller.isExpanded) {
                try {
                    print("Attempting to expand tile programmatically via postFrameCallback: $targetIndex");
                    // Collapse others FIRST if that's the desired behavior
                    // This ensures only one is expanded when the target one opens.
                    for (int i = 0; i < _expansionControllers.length; i++) {
                      if (i != targetIndex && _expansionControllers[i].isExpanded) {
                        _expansionControllers[i].collapse();
                         // Update state tracking if necessary
                         if (i < _expansionStates.length) _expansionStates[i] = false;
                      }
                    }

                    // Now expand the target tile
                    controller.expand();

                    // Update internal state tracking if used
                    if (targetIndex < _expansionStates.length) {
                        _expansionStates[targetIndex] = true;
                    }
                    // You might need setState(() {}); here if _expansionStates directly drives UI elements
                    // that aren't automatically handled by the ExpansionTile itself.
                 } catch (e) {
                    // Catch potential errors during the actual expand call
                    print("Error during controller.expand() for index $targetIndex inside callback: $e");
                 }
            } else {
               print("Tile already expanded post-frame: $targetIndex");
            }
        } else {
           print("Error expanding tile post-frame: targetIndex $targetIndex out of bounds or state not mounted.");
        }
    });
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

    final workout = getEventsForDay(day: today, context: context);

    if (workout.isEmpty){
      return -1;
    } else{
      return workout[0].index;
    }
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

  Widget dayBuild(BuildContext context, int index, bool todaysWorkout) {
    final theme = Theme.of(context);
    final manager = context.watch<TutorialManager>();

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
      if (index == 0){

      return Showcase(
        disableDefaultTargetGestures: true,
        key: AppTutorialKeys.startWorkout,
        description: "Start a workout to begin logging. Includes notes, stopwatches, targets, and recent history, for reference.",
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
        
        child: Padding(
            key: ValueKey(context.watch<Profile>().split[index]),
            padding: EdgeInsets.only(
                left: 8,
                right: 8,
                top: (!todaysWorkout && index == 0) ? 8 : 8),
        
            child: Container(
              decoration: BoxDecoration(
            
                border: Border.all(
                  color: widget.theme.colorScheme.outline,
                  width: 0.5
                ),
                boxShadow: [
                  todaysWorkout
                      ? BoxShadow(
                          color: Color(context.watch<Profile>().split[index].dayColor),
                          offset: const Offset(2.0, 2.0),
                          blurRadius: 4.0,
                        )
                      : BoxShadow(
                        color: widget.theme.colorScheme.shadow,
                        offset: const Offset(2, 2),
                        blurRadius: 4.0,
                      ),

                  // BoxShadow(
                  //   color: lighten(widget.theme.colorScheme.shadow, 20),
                  //   offset: const Offset(-2, -2),
                  //   blurRadius: 4.0,
                  // ),
                ],
                color: widget.theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
              ),
                    
              //defining the inside of the actual box, display information
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  listTileTheme: const ListTileThemeData(
                    contentPadding: EdgeInsets.only(
                      left: 4, right: 16
                    ), // Removes extra padding
                    horizontalTitleGap: 0
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
                    

                    leading: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row( 
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            //width: 50,
                            child: Text(
                              "${index + 1}",
                                                    
                              style: TextStyle(
                                height: 0.6,
                                color: widget.theme.colorScheme.onSurface,
                                fontSize: 35,
                                fontWeight: FontWeight.w900,
                              ),
                              ),
                          ),
                      
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration:  BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(context.watch<Profile>().split[index].dayColor),
                              ),
                            
                            ),
                          ),
                        ]
                      ),
                    ),
                    
                    title: SizedBox(
                      height: 40,
                      
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 30,
                              width: 100,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [                                  
                        
                                  SizedBox(
                                    width:  MediaQuery.sizeOf(context).width - 148,
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
                          borderRadius: const BorderRadius.only(
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
                                                onPressed: () async {
                                              bool? setWorkout = true;
                                              // if theres already a workout active, prompt user to choose - end current workout to start new one or cancel
                                              if (context.read<ActiveWorkoutProvider>().activeDay != null){
                                                setWorkout =  await confirmNewWorkout(context);
                                              }
                
                                              //debugPrint("setit: $setWorkout");
                
                                              // If user did not select back, then we start it
                                              if (setWorkout == true){ // User confirmed to start new (or no old one active)
                                                // This will clear any old snapshot, generate new ID, init structures, start timers
                                                await context.read<ActiveWorkoutProvider>().setActiveDayAndStartNew(index);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => Workout(theme: widget.theme),
                                                  )
                                                );
                                              }
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
                                             onPressed: () async {
                                              bool? setWorkout = true;
                                              // if theres already a workout active, prompt user to choose - end current workout to start new one or cancel
                                              if (context.read<ActiveWorkoutProvider>().activeDay != null){
                                                setWorkout = await confirmNewWorkout(context);
                                              }
                
                                              //debugPrint("setit: $setWorkout");
                
                                              // If user did not select back, then we start it
                                              if (setWorkout == true){ // User confirmed to start new (or no old one active)
                                                // This will clear any old snapshot, generate new ID, init structures, start timers
                                                await context.read<ActiveWorkoutProvider>().setActiveDayAndStartNew(index);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => Workout(theme: widget.theme),
                                                  )
                                                );
                                              }
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
                                  border: Border(
                                    bottom: BorderSide(
                                      color: widget.theme.colorScheme.outline,
                                      width: 0.5
                                    ),
                                  ),
                                ),
                                child: Material(
                                  color: widget.theme.colorScheme.surface,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                              Align(
                                                alignment: Alignment.topLeft,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(6.0),
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
            )),
      );
      } else{
      return Padding(
          key: ValueKey(context.watch<Profile>().split[index]),
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8
          ),

          child: Container(
            decoration: BoxDecoration(
              
              border: Border.all(
                color: widget.theme.colorScheme.outline,
                width: 0.5
              ),
              boxShadow: [
                todaysWorkout
                    ? BoxShadow(
                        color: Color(context.watch<Profile>().split[index].dayColor),
                        offset: const Offset(2, 2),
                        blurRadius: 4.0,
                      )
                    : BoxShadow(
                        color: widget.theme.colorScheme.shadow,
                        offset: const Offset(2, 2),
                        blurRadius: 4.0,
                      ),

                  // BoxShadow(
                  //   color: lighten(widget.theme.colorScheme.shadow, 20),
                  //   offset: const Offset(-2, -2),
                  //   blurRadius: 4.0,
                  // ),
              ],
              color: widget.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
            ),
          
            //defining the inside of the actual box, display information
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                dividerColor: Colors.transparent,
                listTileTheme: const ListTileThemeData(
                  contentPadding: EdgeInsets.only(
                    left: 4, right: 16
                  ), // Removes extra padding
                  horizontalTitleGap: 0,
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

                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row( 
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            //width: 50,
                            child: Text(
                              "${index + 1}",
                                                    
                              style: TextStyle(
                                height: 0.6,
                                color: widget.theme.colorScheme.onSurface,
                                fontSize: 35,
                                fontWeight: FontWeight.w900,
                              ),
                              ),
                          ),
                    
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration:  BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(context.watch<Profile>().split[index].dayColor),
                              ),
                            
                            ),
                          ),
                        ]
                      ),
                  ),
                  title: SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 30,
                            width: 100,
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
                        borderRadius: const BorderRadius.only(
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
                                            onPressed: () async {
                                              bool? setWorkout = true;
                                              // if theres already a workout active, prompt user to choose - end current workout to start new one or cancel
                                              if (context.read<ActiveWorkoutProvider>().activeDay != null){
                                                setWorkout = await confirmNewWorkout(context);
                                              }
              
                                              //debugPrint("setit: $setWorkout");
              
                                              // If user did not select back, then we start it
                                              if (setWorkout == true){ // User confirmed to start new (or no old one active)
                                                // This will clear any old snapshot, generate new ID, init structures, start timers
                                                await context.read<ActiveWorkoutProvider>().setActiveDayAndStartNew(index);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => Workout(theme: widget.theme),
                                                  )
                                                );
                                              }
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
                                            onPressed: () async {
                                              bool? setWorkout = true;
                                              // if theres already a workout active, prompt user to choose - end current workout to start new one or cancel
                                              if (context.read<ActiveWorkoutProvider>().activeDay != null){
                                                setWorkout = await confirmNewWorkout(context);
                                              }
              
                                              //debugPrint("setit: $setWorkout");
              
                                              // If user did not select back, then we start it
                                              if (setWorkout == true){ // User confirmed to start new (or no old one active)
                                                // This will clear any old snapshot, generate new ID, init structures, start timers
                                                await context.read<ActiveWorkoutProvider>().setActiveDayAndStartNew(index);
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => Workout(theme: widget.theme),
                                                  )
                                                );
                                              }
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
                                      const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                            Align(
                                              alignment: Alignment.topLeft,
                                              child: Padding(
                                                padding: const EdgeInsets.all(6.0),
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

  Future<bool?> confirmNewWorkout(BuildContext context) {
    return showDialog<bool>(
      context: context, 
      builder: (context) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,

        title: const Align(alignment: Alignment.center, child: Text('End Active Workout')),
        content: Align(
          alignment: Alignment.center,
          heightFactor: 1, 
          child: Text('To start a new workout, you must end the active workout: ${context.read<ActiveWorkoutProvider>().activeDay!.dayTitle}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End old workout, start new one'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Back', 
              style: TextStyle(
                color: widget.theme.colorScheme.error
              )
            ),
          ),
        ],
      ),
    );
  }
}
