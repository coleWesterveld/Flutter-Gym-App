// workout page
//not updated
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user.dart';
//import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';


// lighten and darken colour functions found on stackoverflow by mr_mmmmore
// here: https://stackoverflow.com/questions/58360989/programmatically-lighten-or-darken-a-hex-color-in-dart
// void main() => runApp(new MaterialApp(home: MyList()));
/// Darken a color by [percent] amount (100 = black)
// ........................................................
Color darken(Color c, [int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    var f = 1 - percent / 100;
    return Color.fromARGB(
        c.alpha,
        (c.red * f).round(),
        (c.green  * f).round(),
        (c.blue * f).round()
    );
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
        c.blue + ((255 - c.blue) * p).round()
    );
}




Color _listColorFlop({required int index, Color bgColor = const Color(0xFF151218)}){
  if (index % 2 == 0){
    return lighten(bgColor, 5);
  }
  else{
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

class _WorkoutPageState extends State<WorkoutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //backgroundColor: const Color(0xFF643f00),
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
            itemCount: context.watch<Profile>().split.length,
            itemBuilder: (context, index) {
              return Padding(
                key: ValueKey(context.watch<Profile>().split[index]),
                padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                
                //following shadows are what gives neumorphism effect
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        offset: const Offset(-6.0, -6.0),
                        blurRadius: 16.0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        offset: const Offset(6.0, 6.0),
                        blurRadius: 12.0,
                      ),
                      BoxShadow(
                        color: context.watch<Profile>().split[index].dayColor,
                        offset: const Offset(0.0, 0.0),
                        blurRadius: 0.0,
                      ),
                      //this shadow is what gives left side lining of colour
                      //kind of undecided if I want to change this, i could make this more of a drop shadow, idk
                      BoxShadow(
                        color: context.watch<Profile>().split[index].dayColor,
                        offset: const Offset(-4.0, 0.0),
                        blurRadius: 0.0,
                      ),
                    ],
                    color: const Color(0xFF151218),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
              
                  //defining the inside of the actual box, display information
                  child:  Center(
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      
                      //expandable to see excercises and sets for that day
                      child: ExpansionTile(
                      iconColor: const Color.fromARGB(255, 255, 255, 255),
                      collapsedIconColor: const Color.fromARGB(255, 255, 255, 255),
              
                      //top row always displays day title, and edit button
                      //sized boxes and padding is just a bunch of formatting stuff
                      //tbh it could probably be made more concise
                      //TODO: simplify this
                      title: 
                        SizedBox(
                          height: 40,
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 30,
                                  width: 100,
                                  child: 
                                    Padding(
                                      padding: const EdgeInsets.all(0.0),
                                      //actual information: number ordering of day, 
                                      //user given day name, edit button
                                      child: Row(
                                        children: [
              
                                          //number
                                          Text(
                                            "${index + 1}: ",
              
                                            style: TextStyle(
                                              color: context.watch<Profile>().split[index].dayColor,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                            ),
              
                                          //day title
                                          ),
                                          Text(
                                            context.watch<Profile>().split[index].data,
                                            style: const TextStyle(
                                              color: Color.fromARGB(255, 255, 255, 255),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          
                                        ], 
                                      ),//end of title row
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
                          ListView.builder(

                            //being able to scroll within the already scrollable day view 
                            // is annoying so i disabled it
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: context.read<Profile>().excercises[index].length,
                            shrinkWrap: true,
              
                            //displaying list of excercises for that day
                            
                            itemBuilder: (context, excerciseIndex) {
                              return Material(
                                color: _listColorFlop(index: excerciseIndex),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                context.watch<Profile>().excercises[index][excerciseIndex].data,
                                                                                      
                                                style: const TextStyle(
                                                  color: Color.fromARGB(255, 255, 255, 255),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                
                                      //Displaying Sets for each excercise
                                      ListView.builder(
                                        //on reorder, update tree with new ordering
                                        // is annoying so i disabled it
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: context.read<Profile>().sets[index][excerciseIndex].length,
                                        shrinkWrap: true,
                                
                                        //displaying list of sets for that excercise
                                        //TODO: add sets here too, centre text boxes, add notes option on dropdown
                                        itemBuilder: (context, setIndex) {
                                          return Dismissible(
                                            key: ValueKey(context.watch<Profile>().sets[index][excerciseIndex][setIndex]),
                                
                                            direction: DismissDirection.endToStart,
                                            background: Container(
                                              color: Colors.red,
                                              child: const Icon(Icons.delete)
                                            ),
                                                  
                                            onDismissed: (direction) {
                                              HapticFeedback.heavyImpact();
                                              // Remove the item from the data source.
                                              setState(() {
                                                context.read<Profile>().setsPop(
                                                  index1: index, 
                                                  index2: excerciseIndex,
                                                  index3: setIndex,
                                                );    
                                              });
                                  
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    style: TextStyle(
                                                      color: Colors.white
                                                    ),
                                                    'Excercise Deleted'
                                                  ),
                                               ),
                                              );
                                            },
                                            
                                            //actual information about the sets
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Row(
                                                // TODO: add rep ranges
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: TextFormField(
                                            
                                                      decoration: const InputDecoration(
                                                        contentPadding: EdgeInsets.only(
                                                          bottom: 10, 
                                                          left: 8 
                                                        ),
                                                        constraints: BoxConstraints(
                                                          maxWidth: 150,
                                                          maxHeight: 30,
                                                        ),
                                                        border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.all(Radius.circular(8))),
                                                        hintText: 'Weight', //This should be made to be whateever this value was last workout
                                                      ),
                                                    ),
                                                  ),
                                                  const Icon(Icons.clear),
                                                  Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: TextFormField(
                                                      decoration: const InputDecoration(
                                                        contentPadding: EdgeInsets.only(
                                                          bottom: 10, 
                                                          left: 8 
                                                        ),
                                                        constraints: BoxConstraints(
                                                          maxWidth: 150,
                                                          maxHeight: 30,
                                                        ),
                                                        border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.all(Radius.circular(8))),
                                                        hintText: 'Reps', //This should be made to be whateever this value was last workout
                                                      ),
                                                    ),
                                                  ),                  
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ]
                      ),
                    ),
                  ),
                )
              );
            },
        ),
      ),
    );
  }
}