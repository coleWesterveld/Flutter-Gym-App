// workout page
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../user.dart';
//import 'package:flutter/cupertino.dart';
import '../schedule_page/schedule_page.dart';
import 'set_logging.dart';
import '../other_utilities/lightness.dart';

// for set logging this is how it should prolly be done:
// when the user opens an active workout, it should create a "session" which buffers the setdata in memory
// when they are working out, maybe it would be good to load up the history for that exercise in the background so that it is fast to retrieve
// 

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
                        ]
                      ),
                    ),

                    SizedBox(
                      
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
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

