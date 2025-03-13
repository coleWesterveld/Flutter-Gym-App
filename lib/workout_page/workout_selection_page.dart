// workout page
//not updated
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../user.dart';
//import 'package:flutter/cupertino.dart';
import '../schedule_page/schedule_page.dart';
import 'workout_page.dart';
import '../other_utilities/days_between.dart';
import '../other_utilities/lightness.dart';

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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
              // TODO: here I want to make a little grayed box that says "no workouts planned today" so the user knows why none are highliughted
              return dayBuild(context, index - 1, false);
            }
          },
        ),
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
              color: lighten(const Color(0xFF1e2025), 40)
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
    
              border: Border.all(color: lighten(const Color(0xFF141414), 20)),
              boxShadow: [
                todaysWorkout
                    ? BoxShadow(
                        color: Color(context.watch<Profile>().split[index].dayColor),
                        offset: const Offset(0.0, 0.0),
                        blurRadius: 8.0,
                      )
                    : const BoxShadow(),
              ],
              color:  const Color(0xFF1e2025),
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
                  controller: context.watch<Profile>().controllers[index],
                  key: ValueKey(context.watch<Profile>().split[index]),
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      for (int i = 0; i < context.read<Profile>().controllers.length; i++) {
                        if (i != index && isExpanded) {
                          context.read<Profile>().controllers[i].collapse();
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
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 255, 255, 255),
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
                                                const Color(0XFF1A78EB),
                                              ),
                                              overlayColor: WidgetStateProperty
                                                  .resolveWith<Color?>(
                                                      (states) {
                                                if (states.contains(
                                                    WidgetState.pressed)) {
                                                  return const Color(
                                                      0XFF1A78EB);
                                                }
                                                return null;
                                              }),
                                            ),
                                            onPressed: () {
                                              context.read<Profile>().setActiveDay(index);
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
                                                  WidgetState.pressed)) {
                                                return const Color(0XFF1A78EB);
                                              }
                                              return null;
                                            }),
                                          ),
                                          onPressed: () {
                                            context.read<Profile>().setActiveDay(index);
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
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(Radius.circular(1)),
                                border: Border(bottom: BorderSide(color: lighten(const Color(0xFF1e2025), 20)/*Theme.of(context).dividerColor*/, width: 0.5),),
                              ),
                              child: Material(
                                color:const Color(0xFF1e2025),
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
                                                    style: const TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                            height: context.watch<Profile>().setsTEC[index][exerciseIndex].length * 20 + 16,
                                            width: 100,
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: ListView(
                                                physics: const NeverScrollableScrollPhysics(),
                                                children: [
                                                  for(int i = 0; i < context.watch<Profile>().setsTEC[index][exerciseIndex].length; i++) 
                                                    Padding(
                                                      padding: const EdgeInsets.only(right: 24.0),
                                                      child: Center(
                                                        child: Text(
                                                          "${context.watch<Profile>().setsTEC[index][exerciseIndex][i].text} x ${context.watch<Profile>().reps1TEC[index][exerciseIndex][i].text}",
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
                                          
                                          // SizedBox(
                                          //   height: 100,
                                          //   width: 100,
                                          //   child: ListView(
                                          //     physics: const NeverScrollableScrollPhysics(),
                                          //     children: [
                                          //       for(int i = 0; i <5 ; i++) const Text("Stff"),
                                          //     ]
                                          //   ),
                                          // )
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
