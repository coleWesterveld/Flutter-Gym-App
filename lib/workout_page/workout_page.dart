// workout page
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../user.dart';
//import 'package:flutter/cupertino.dart';
import '../schedule_page/schedule_page.dart';
import 'setLogging.dart';

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
  // not very fond of this solution, it seems to work though. 
  // will have to migrate from previous solution as colors is moving from 0-255 to 0-1
  assert(1 <= percent && percent <= 100);
  var p = percent / 100;
  return Color.lerp(
  c, Colors.white, p
  )!;
      
}

// Color _listColorFlop(
//     {required int index, Color bgColor = const Color(0xFF151218)}) {
//   if (index % 2 == 0) {
//     return lighten(bgColor, 5);
//   } else {

//     return bgColor;
//   }
// }

//TODO: gradient background

class Workout extends StatefulWidget {
  const Workout({
    super.key,
  });

  @override
  State<Workout> createState() => _WorkoutState();
}

class _WorkoutState extends State<Workout>{
  late List<ExpansionTileController> _expansionControllers;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    int? primaryIndex = context.read<Profile>().activeDayIndex;


    // Access Provider or other inherited widgets here
    // THIS IS CAUSING ISSUES
    int exerciseLength = context.watch<Profile>().exercises[primaryIndex!].length;
    _expansionControllers = List.generate(
      exerciseLength,
      (_) => ExpansionTileController(),
    );

    //sint? primaryIndex = context.read<Profile>().activeDayIndex;
  }

  @override
  void initState() {
    
    super.initState();

    //List<ExpansionTileController> _expansionControllers = List.filled(context.watch<Profile>().split.length, ExpansionTileController(), growable: true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    int? primaryIndex = context.read<Profile>().activeDayIndex;
   
    return Scaffold(
      appBar: AppBar(
        // maybe null check here, i am using a lot of !
        // it should be fine but there could be wierd edge cases with closing/reloading I guess
        backgroundColor: const Color(0xFF1e2025),
        // centerTitle: true,
        title:  Text(
          "Day ${primaryIndex! + 1} • ${context.watch<Profile>().activeDay!.dayTitle}",
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: (primaryIndex == null) ? Text("Something Went Wrong.") :
        SizedBox(
        //height: MediaQuery.of(context).size.height - (265),
        child: ListView.builder(
          // building the rest of the tiles, one for each day from split list stored in user
          //dismissable and reorderable: each child for dismissable needs to have a unique key
          itemCount: context.watch<Profile>().exercises[primaryIndex].length,

          itemBuilder: (context, index) {
              return exerciseBuild(context, index, _expansionControllers);
          },
        ),
      ),
    );
  }

  Padding exerciseBuild(BuildContext context, int index, 
      List<ExpansionTileController> controllers) {

      
      int? primaryIndex = context.read<Profile>().activeDayIndex;

      return Padding(
          key: ValueKey(context.watch<Profile>().exercises[primaryIndex!][index]),
          padding: EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
          ),

          child: Container(
            // TODO: dont like how this goes all the way down under "start workout" button and stuff,
            decoration: BoxDecoration(
    
              border: Border.all(color: lighten(const Color(0xFF141414), 20)),
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
                  initiallyExpanded: index == 0,
                  controller: controllers[index],
                  key: ValueKey(context.watch<Profile>().exercises[primaryIndex][index]),
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      for (int i = 0; i < _expansionControllers.length; i++) {
                        if (i != index && isExpanded) {
                          _expansionControllers[i].collapse();
                        }
                      }
                    });
                  },
                  //initiallyExpanded: todaysWorkout,
                  
                  iconColor: const Color.fromARGB(255, 255, 255, 255),
                  collapsedIconColor: const Color.fromARGB(255, 255, 255, 255),

                  //TODO: simplify this
                  title: Row(
                    children: [
                      IconButton(
                        onPressed: (){
                          setState((){context.read<Profile>().showHistory![index] = !context.read<Profile>().showHistory![index];});
                          //(context.read<Profile>().showHistory![index].toString());
                        }, 
                        
                        icon: Icon(context.watch<Profile>().showHistory![index] ? Icons.swap_horiz:Icons.history)
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal:8.0),
                        child: Text(
                          context.watch<Profile>().exercises[primaryIndex][index].exerciseTitle,
                          overflow: TextOverflow.ellipsis,
                                            
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  //children of expansion tile - what gets shown when user expands that day
                  // shows exercises for that day
                  //this part is viewed after tile is expanded
                  //TODO: show sets per exercise, notes, maybe most recent weight/reps
                  //exercises are reorderable
                  children: context.watch<Profile>().showHistory![index] ? [Text("Hello there")]: [
                    SizedBox(
                      
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: context.read<Profile>().sets[primaryIndex][index].length,
                        itemBuilder: (context, exerciseIndex){
                          return GymSetRow(prevWeight: 12, prevReps: 5, expectedRPE: 8, expectedReps: 5, expectedWeight: 200,);
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextFormField(
  keyboardType: TextInputType.multiline,
  minLines: 2,  // Start with 2 rows
  maxLines: null, // Allow vertical expansion
  decoration: InputDecoration(
    filled: true,
    fillColor: const Color(0xFF1e2025),
    contentPadding: const EdgeInsets.only(bottom: 10, left: 8),
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    hintText: "Notes: ",
  ),
)

                    ),
                  ]
                ),
            ),
          )
        );
    }
  }

