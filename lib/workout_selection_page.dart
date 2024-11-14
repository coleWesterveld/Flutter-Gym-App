// workout page
//not updated
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user.dart';
//import 'package:flutter/cupertino.dart';
import 'schedule_page.dart';
import 'workout_page.dart';

// lighten and darken colour functions found on stackoverflow by mr_mmmmore
// here: https://stackoverflow.com/questions/58360989/programmatically-lighten-or-darken-a-hex-color-in-dart
// void main() => runApp(new MaterialApp(home: MyList()));
/// Darken a color by [percent] amount (100 = black)
// ........................................................
Color darken(Color c, [int percent = 10]) {
  assert(1 <= percent && percent <= 100);
  var f = 1 - percent / 100;
  return Color.fromARGB(c.alpha, (c.red * f).round(), (c.green * f).round(),
      (c.blue * f).round());
}

/// Lighten a color by [percent] amount (100 = white)
// ........................................................
Color lighten(Color c, [int percent = 10]) {
  assert(1 <= percent && percent <= 100);
  var p = percent / 100;
  return Color.fromARGB(
      c.alpha,
      c.red + ((255 - c.red) * p).round(),
      c.green + ((255 - c.green) * p).round(),
      c.blue + ((255 - c.blue) * p).round());
}

Color _listColorFlop(
    {required int index, Color bgColor = const Color(0xFF151218)}) {
  if (index % 2 == 0) {
    return lighten(bgColor, 5);
  } else {
    return bgColor;
  }
}

//TODO: gradient background

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({
    super.key,
  });

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late List<ExpansionTileController> _expansionControllers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Access Provider or other inherited widgets here
    int splitLength = context.watch<Profile>().split.length;
    _expansionControllers = List.generate(
      splitLength,
      (index) => ExpansionTileController(),
    );
  }

  @override
  void initState() {
    super.initState();

    //List<ExpansionTileController> _expansionControllers = List.filled(context.watch<Profile>().split.length, ExpansionTileController(), growable: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    )..repeat(reverse: true); // Continuously animates back and forth
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
    int todaysWorkout = toExpand();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e2025),
        centerTitle: true,
        title: const Text(
          "Workout",
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height - (265),
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
                    context, todaysWorkout, true, _expansionControllers);
              } else if (index <= todaysWorkout) {
                return dayBuild(
                    context, index - 1, false, _expansionControllers);
              } else {
                return dayBuild(context, index, false, _expansionControllers);
              }
            } else {
              // TODO: here I want to make a little grayed box that says "no workouts planned today" so the user knows why none are highliughted
              return dayBuild(context, index - 1, false, _expansionControllers);
            }
          },
        ),
      ),
    );
  }

  Padding dayBuild(BuildContext context, int index, bool todaysWorkout,
      List<ExpansionTileController> controllers) {
    if (!todaysWorkout && index == -1) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Center(
          child: Text("No Workout Scheduled For Today",
            style: TextStyle(
              //height: 0.5,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: lighten(const Color(0xFF1e2025), 40)
            )
          )
        ),
      );
    } else {
      return Padding(
          key: ValueKey(context.watch<Profile>().split[index]),
          padding: EdgeInsets.only(
              left: 15,
              right: 15,
              top: (!todaysWorkout && index == 0) ? 5 : 15),

          //following shadows are what gives neumorphism effect
          child: Container(
            // TODO: dont like how this goes all the way down under "start workout" button and stuff,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    context.watch<Profile>().split[index].dayColor,
                    context.watch<Profile>().split[index].dayColor,
                    const Color(0xFF1e2025),
                  ],
                  stops: const [
                    0,
                    0.11,
                    0.11
                  ]),
              border: Border.all(color: lighten(const Color(0xFF141414), 20)),
              boxShadow: [
                todaysWorkout
                    ? BoxShadow(
                        color: context.watch<Profile>().split[index].dayColor,
                        offset: const Offset(0.0, 0.0),
                        blurRadius: 8.0,
                      )
                    : const BoxShadow(),
              ],
              color: todaysWorkout
                  ? context.watch<Profile>().split[index].dayColor
                  : const Color(0xFF1e2025),
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

              //expandable to see excercises and sets for that day
              child: ExpansionTile(
                  controller: controllers[index],
                  key: ValueKey(context.watch<Profile>().split[index]),
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      for (int i = 0; i < _expansionControllers.length; i++) {
                        if (i != index && isExpanded) {
                          _expansionControllers[i].collapse();
                        }
                      }
                    });
                  },
                  initiallyExpanded: todaysWorkout,
                  //initiallyExpanded: toExpand(index),
                  //controller: context.watch<Profile>().controllers[index],
                  iconColor: const Color.fromARGB(255, 255, 255, 255),
                  collapsedIconColor: const Color.fromARGB(255, 255, 255, 255),

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
                                      color: darken(
                                          context
                                              .watch<Profile>()
                                              .split[index]
                                              .dayColor,
                                          70),
                                      fontSize: 50,
                                      fontWeight: FontWeight.w900,
                                    ),

                                    //day title
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Text(
                                    context.watch<Profile>().split[index].data,
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 255, 255, 255),
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
                  // shows excercises for that day
                  //this part is viewed after tile is expanded
                  //TODO: show sets per excercise, notes, maybe most recent weight/reps
                  //excercises are reorderable
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1e2025),
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(12.0),
                            bottomLeft: Radius.circular(12.0)),
                      ),
                      child: ListView.builder(
                        //being able to scroll within the already scrollable day view
                        // is annoying so i disabled it
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            context.read<Profile>().excercises[index].length +
                                1,
                        shrinkWrap: true,

                        //displaying list of excercises for that day

                        itemBuilder: (context, excerciseIndex) {
                          if (excerciseIndex ==
                              context
                                  .read<Profile>()
                                  .excercises[index]
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
                                                const Color(0XFF1A78EB),
                                              ),
                                              overlayColor: WidgetStateProperty
                                                  .resolveWith<Color?>(
                                                      (states) {
                                                if (states.contains(
                                                    WidgetState.pressed))
                                                  return const Color(
                                                      0XFF1A78EB);
                                                return null;
                                              }),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const Workout(),
                                                  ));
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
                                              const Color(0XFF1A78EB),
                                            ),
                                            overlayColor: WidgetStateProperty
                                                .resolveWith<Color?>((states) {
                                              if (states.contains(
                                                  WidgetState.pressed))
                                                return const Color(0XFF1A78EB);
                                              return null;
                                            }),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const Workout(),
                                                ));
                                          },
                                          child: const Text(
                                            "Start This Workout",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800),
                                          )),
                                    ),
                            );
                          } else {
                            return Material(
                              color: _listColorFlop(
                                  index: excerciseIndex,
                                  bgColor: const Color(0xFF151218)),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              context
                                                  .watch<Profile>()
                                                  .excercises[index]
                                                      [excerciseIndex]
                                                  .data,
                                              style: const TextStyle(
                                                color: Color.fromARGB(
                                                    255, 255, 255, 255),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    //Displaying Sets for each excercise
                                    // ListView.builder(
                                    //   //on reorder, update tree with new ordering
                                    //   // is annoying so i disabled it
                                    //   physics: const NeverScrollableScrollPhysics(),
                                    //   itemCount: context.read<Profile>().sets[index][excerciseIndex].length,
                                    //   shrinkWrap: true,

                                    //   //displaying list of sets for that excercise
                                    //   //TODO: add sets here too, centre text boxes, add notes option on dropdown
                                    //   itemBuilder: (context, setIndex) {
                                    //     return Dismissible(
                                    //       key: ValueKey(context.watch<Profile>().sets[index][excerciseIndex][setIndex]),

                                    //       direction: DismissDirection.endToStart,
                                    //       background: Container(
                                    //         color: Colors.red,
                                    //         child: const Icon(Icons.delete)
                                    //       ),

                                    //       onDismissed: (direction) {
                                    //         HapticFeedback.heavyImpact();
                                    //         // Remove the item from the data source.
                                    //         setState(() {
                                    //           context.read<Profile>().setsPop(
                                    //             index1: index,
                                    //             index2: excerciseIndex,
                                    //             index3: setIndex,
                                    //           );
                                    //         });

                                    //         ScaffoldMessenger.of(context).showSnackBar(
                                    //           const SnackBar(
                                    //             content: Text(
                                    //               style: TextStyle(
                                    //                 color: Colors.white
                                    //               ),
                                    //               'Excercise Deleted'
                                    //             ),
                                    //          ),
                                    //         );
                                    //       },

                                    //       //actual information about the sets
                                    //       child: Padding(
                                    //         padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    //         child: Row(
                                    //           // TODO: add rep ranges
                                    //           children: [
                                    //             Padding(
                                    //               padding: const EdgeInsets.all(8.0),
                                    //               child: TextFormField(

                                    //                 decoration: const InputDecoration(
                                    //                   contentPadding: EdgeInsets.only(
                                    //                     bottom: 10,
                                    //                     left: 8
                                    //                   ),
                                    //                   constraints: BoxConstraints(
                                    //                     maxWidth: 150,
                                    //                     maxHeight: 30,
                                    //                   ),
                                    //                   border: OutlineInputBorder(
                                    //                       borderRadius: BorderRadius.all(Radius.circular(8))),
                                    //                   hintText: 'Weight', //This should be made to be whateever this value was last workout
                                    //                 ),
                                    //               ),
                                    //             ),
                                    //             const Icon(Icons.clear),
                                    //             Padding(
                                    //               padding: const EdgeInsets.all(8.0),
                                    //               child: TextFormField(
                                    //                 decoration: const InputDecoration(
                                    //                   contentPadding: EdgeInsets.only(
                                    //                     bottom: 10,
                                    //                     left: 8
                                    //                   ),
                                    //                   constraints: BoxConstraints(
                                    //                     maxWidth: 150,
                                    //                     maxHeight: 30,
                                    //                   ),
                                    //                   border: OutlineInputBorder(
                                    //                       borderRadius: BorderRadius.all(Radius.circular(8))),
                                    //                   hintText: 'Reps', //This should be made to be whateever this value was last workout
                                    //                 ),
                                    //               ),
                                    //             ),
                                    //           ],
                                    //         ),
                                    //       ),
                                    //     );
                                    //   },
                                    // ),
                                  ],
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
