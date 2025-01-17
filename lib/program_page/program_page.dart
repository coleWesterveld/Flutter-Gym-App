// program page
// ignore_for_file: prefer_const_constructors

/*
Still Todo on this page:
- DONE change colours, make customizeable by user
- move random functions to their own files
- make more modular, this file feels unnecessarily long 
- ability to add notes per exercise
- change look of title
- PERSISTENCE for exercises and set data, notes, title
  - either through shared preferences or local SQLite database
- Change look of calendar, right now big blocks of colour are too much
- stop bottom from being like stuck too low
- DONE I think i dont need focusnodes in user profile? would probably be a lot easier on memory and stuff to get rid
- fix double digit days - they dont show up well
- LATER: add sidebar, user can have multiple different programs to swap between
- the day indices should be their own container, not gradients
    this will prevent doubvle digit num overflow, be more flexible for multiple devices and is just better
- make a max of all user input fields - make them as long as possible but stop them from being absurd
I think the not saving problem is because i am unfocusing but not saving when I click done or scaffold
*/

//import 'package:firstapp/main.dart';
import 'package:firstapp/database/database_helper.dart';
//import 'package:firstapp/database/profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../user.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
//import 'package:flutter/cupertino.dart';

//TODO: gradient background

import 'package:flutter/services.dart';

// TODO: add exercise and set persistence - may have to use SQLite database as opposed to shared preferences
// TODO: move days between, lighten/darken and other outside functions to other file(s)

int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
   return (to.difference(from).inHours / 24).round();
}

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



//program page, where user defines the overall program by days,
// then exercises for each day with sets, rep range and notes
class ProgramPage extends StatefulWidget {
  //Function writePrefs;
  final DatabaseHelper dbHelper;
  
  const ProgramPage({Key? programkey, required this.dbHelper,}) : super(key: programkey);
  @override
  _MyListState createState() => _MyListState();
}


enum Viewer {title, color}
// this class contains the list view of expandable card tiles 
// title is day title (eg. 'legs') and when expanded, leg exercises for that day show up
class _MyListState extends State<ProgramPage> {
  DateTime today = DateTime.now();
  final List<DateTime> toHighlight = [DateTime(2024, 8, 20)];


  DateTime startDay = DateTime(2024, 8, 10);
  int? _sliding = 0;
  TextEditingController alertTEC = TextEditingController();
  //double alertInsetValue = 0;

  Widget pickerItemBuilder(Color color, bool isCurrentColor, void Function() changeColor) {
    
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: color,
        boxShadow: [BoxShadow(color: color.withOpacity(0.8), offset: const Offset(1, 2), blurRadius: 0.0)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: changeColor,
          borderRadius: BorderRadius.circular(8.0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isCurrentColor ? 1 : 0,
            child: Icon(
              Icons.done,
              size: 36,
              color: useWhiteForeground(color) ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }


    Widget pickerLayoutBuilder(BuildContext context, List<Color> colors, PickerItem child) {
    Orientation orientation = MediaQuery.of(context).orientation;

    return SizedBox(
      width: 300,
      height: orientation == Orientation.portrait ? 360 : 240,
      child: GridView.count(
        crossAxisCount: orientation == Orientation.portrait ?  5: 4,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        children: [for (Color color in colors) child(color)],
      ),
    );
  }

  // adds day to split
  _addItem() {
      context.read<Profile>().splitAppend(
        // newDay: "New Day", 
        // newexercises: [], 
        // newSets: [],
        // newReps1TEC: [],
        // newReps2TEC: [],
        // newRpeTEC: [],
        // newSetsTEC: [],
        );
  }


  //TODO: fix error where clicking on one textfield then directly to another getrs rid of done button, unexpectedly
  @override
  // main scaffold, putting it all together
  Widget build(BuildContext context) {
    
    //alertInsetValue =  MediaQuery.sizeOf(context).height - 300;
    //print(_sliding);
    return GestureDetector(
      onTap: (){
            WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
            Provider.of<Profile>(context, listen: false).changeDone(false);
        },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Color(0xFF1e2025),
          centerTitle: true,
          title: const Text(
            "Build Program",
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
            ),
        ),
      
        bottomSheet: buildBottomSheet(),
      
      
      
        // with image background
        // cant decide if I like it, ill leave code here to decide
        // for now, ill keep it simple
        // DecoratedBox(
        //   decoration: BoxDecoration( 
            
        //       // Image set to background of the body
        //       image: DecorationImage( 
        //           image: AssetImage("darkbg.png"), fit: BoxFit.cover),
        //     ),
        //   child:
      
        //list of day cards
        body: Column(
          children: [
            Expanded(
              child: ReorderableListView.builder(
                //reordering days
                  onReorder: (oldIndex, newIndex){
                    HapticFeedback.heavyImpact();
                    setState(() {
                      // if (newIndex > oldIndex) {
                      //   newIndex -= 1;
                      // }
                      context.read<Profile>().moveDay(oldIndex: oldIndex, newIndex: newIndex, programID: 1);
              
              
                    });
                  },
                
                  //button at bottom to add a new day to split
                  footer: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      key: ValueKey('dayAdder'),
                    
                      color: Color(0XFF1A78EB),
                      child: InkWell(
                     
                        splashColor: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          HapticFeedback.heavyImpact();
                          setState(() {
                            _addItem();
                          });
                          
                          //insertDay(context, 1, 'Day 1 - Upper Body');
                          
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: 50.0,
                          child: Icon(Icons.add),
                        ),
                      ),
                    ),
                  ),
                      
                  // building the rest of the tiles, one for each day from split list stored in user
                  //dismissable and reorderable: each child for dismissable needs to have a unique key
                  itemCount: context.watch<Profile>().split.length,
                  itemBuilder: (context, index) {
                    
                    return Dismissible(
                      direction: DismissDirection.endToStart,
                      key: ValueKey(context.watch<Profile>().split[index]),
                      background: Container(
                        color: Colors.red,
                        child: Icon(Icons.delete)
                      ),
                      
                      // dismiss when user swipes right to left on any day, remove that day from the list
                      onDismissed: (direction) {
                        HapticFeedback.heavyImpact();
                        // Remove the item from the data source.
                        setState(() {
                          context.read<Profile>().splitPop(index: index);    
                        });
                        //widget.writePrefs();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              style: TextStyle(
                                color: Colors.white
                              ),
                              'Day Deleted'
                              ),
                          ),
                        );
                      },
                      
                      //outline for each day tile in the list
                      child: Padding(
                        key: ValueKey(context.watch<Profile>().split[index]),
                        padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                        
                    
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: lighten(Color(0xFF141414), 20)),
                    
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(context.watch<Profile>().split[index].dayColor),
                                Color(context.watch<Profile>().split[index].dayColor),
                              const Color(0xFF1e2025),
                              ],
                          stops: const [
                            0, 0.11, 0.11
                          ]
                        ),
                    
                            
                            color: Color(0xFF1e2025),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                      
                          //defining the inside of the actual box, display information
                          child:  Center(
                            child: Theme(
                               data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          listTileTheme: ListTileThemeData(
                            contentPadding: EdgeInsets.only(left: 4, right: 16), // Removes extra padding
                          ),
                        ),
                              
                              //expandable to see exercises and sets for that day
                              child: ExpansionTile(
                              iconColor: Color(0XFF1A78EB),
                              collapsedIconColor: Color(0XFF1A78EB),
                              onExpansionChanged: (val){
                                if (!val){
                                  WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
                                  Provider.of<Profile>(context, listen: false).changeDone(false);
                                }
                              },
                      
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
                                            Row(
                                              children: [
                                                  
                                                //number
                                                SizedBox(
                                                  width: 30,
                                                  child: Text(
                                                    
                                                    "${index + 1}",
                                                        
                                                    style: TextStyle(
                                                       height: 0.6,
                                              
                                              color: darken(Color(context.watch<Profile>().split[index].dayColor), 70),
                                              fontSize: 50,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                        
                                                  //day title
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(left : 16.0),
                                                  child: SizedBox(
                                                    width: MediaQuery.sizeOf(context).width - 186,
                                                    child: Text(
                                                      overflow: TextOverflow.ellipsis,

                                                      context.watch<Profile>().split[index].dayTitle,
                                                      style: TextStyle(
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
                                        
                                      //update title button
                                      
                                      IconButton(onPressed: () {
                                          
                                          //TODO: make a button to go between two screens, 
                                          // default to changing title but when toggled to color can also change day color.
                                          //TODO: color prefereces persistence
                                          
                                          showDialog(
                                            anchorPoint: Offset(100, 100),
                                            
                                            context: context,
                                            builder: (BuildContext context) {
                                              return StatefulBuilder(
                                                builder: (context, StateSetter setState) {
                                                    return AlertDialog(
                                                      //Padding: EdgeInsets.only(bottom: alertInsetValue),
                                                      title: CupertinoSlidingSegmentedControl(
                                                        padding: EdgeInsets.all(4.0),
                                                        children: const <int, Text>{
                                                          0: Text("Title"),
                                                          1: Text("Color"),
                                                        }, 
                                                
                                                        onValueChanged: (int? newValue){
                                                          _sliding = newValue;
                                                
                                                          setState((){});
                                                     
                                                        },
                                                        thumbColor: Colors.orange,
                                                        groupValue: _sliding,
                                                      ),
                                                      content: editBuilder(index),
                                                      actions: [
                                                        IconButton(
                                                        onPressed: (){
                                                          HapticFeedback.heavyImpact();
                                                          String? dayTitle = alertTEC.text;
                                                          if (dayTitle.isNotEmpty) {
                                                          //rebuild widget tree reflecting new title
                                                          setState( () {
                                                            Provider.of<Profile>(context, listen: false).splitAssign(
                                                              index: index, 
                                                              //id: context.read<Profile>().split[index].dayID,
                                                              newDay: context.read<Profile>().split[index].copyWith(newDayTitle: dayTitle),
              
                                                              // newexercises: context.read<Profile>().exercises[index],
                                                              // newSets: context.read<Profile>().sets[index],
                    
                                                              // newSetsTEC: context.read<Profile>().setsTEC[index],
                    
                                                              // newReps1TEC: context.read<Profile>().reps1TEC[index],
                    
                                                              // newReps2TEC: context.read<Profile>().reps2TEC[index],
                    
                                                              // newRpeTEC: context.read<Profile>().rpeTEC[index],
                    
                                                              // newDay: SplitDayData(
                                                              //   data: dayTitle, dayColor: context.read<Profile>().split[index].dayColor
                                                              // )
                                                            );
                                                          });} //
                                                          Navigator.of(context, rootNavigator: true).pop('dialog');
                                                          _sliding = 0;
                      
                                                          
                                                        },
                                                        icon: Icon(Icons.check))
              ]
                                                
                                                );},
                                              );
                                            },
                                          );
                                        
                                          //widget.writePrefs();
                                        },
                      
                                        icon: Icon(Icons.edit_outlined),
                                        color: Colors.orange,
                                      ),
                                    ],
                                  ),
                                ),
                                      
                                //children of expansion tile - what gets shown when user expands that day
                                // shows exercises for that day
                                //this part is viewed after tile is expanded
                                //TODO: show sets per exercise, notes, maybe most recent weight/reps
                                //exercises are reorderable
                    
                                //TODO: get rid of little bit of color that somehow gets through at bottom
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color:Color(0xFF1e2025),
                                      borderRadius: BorderRadius.only(
                                        
                                        bottomRight: Radius.circular(12.0),
                                        
                                        bottomLeft: Radius.circular(12.0)),
                                      ),
                                    
                                    
                                    child: ReorderableListView.builder(
                                      
                                      //on reorder, update tree with new ordering
                                      onReorder: (oldIndex, newIndex){
                                        HapticFeedback.heavyImpact();
                                        setState(() {
                                          context.read<Profile>().moveexercise(oldIndex: oldIndex, newIndex: newIndex, dayIndex: index);
              
                                        });
                                      },
                                      
                                      //"add exercise" button at bottom of exercise list
                                      footer: Padding(
                                        key: ValueKey('exerciseAdder'),
                                        padding: const EdgeInsets.all(8),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: ButtonTheme(
                                            minWidth: 100,
                                            //height: 130,
                                            child: TextButton.icon(
                                              onPressed: () {
                                                HapticFeedback.heavyImpact();
                                                setState(() {
                                                  context.read<Profile>().exerciseAppend(
                                                    index: index,
                                                    
                                                  );
                                                });  
                                              },
                                            
                                              style: ButtonStyle(
                                                //when clicked, it splashes a lighter purple to show that button was clicked
                                                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                                       
                                                  borderRadius: BorderRadius.circular(12))),
                                                backgroundColor: WidgetStateProperty.all(Color(0XFF1A78EB),), 
                                                overlayColor: WidgetStateProperty. resolveWith<Color?>((states) {
                                                  if (states.contains(WidgetState.pressed)) return Color(0XFF1A78EB);
                                                  return null;
                                                }),
                                              ),
                                              
                                              label: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                  ),
                                                  Text(
                                    
                                                    "exercise  ",
                                                    style: TextStyle(
                                                        color: Color.fromARGB(255, 255, 255, 255),
                                                        //fontSize: 18,
                                                        //fontWeight: FontWeight.w800,
                                                      ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                          
                                      //being able to scroll within the already scrollable day view 
                                      // is annoying so i disabled it
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: context.read<Profile>().exercises[index].length,
                                      shrinkWrap: true,
                                      
                                          
                                      //displaying list of exercises for that day
                                      //TODO: add sets here too, centre text boxes, add notes option on dropdown
                                      itemBuilder: (context, exerciseIndex) {
                                        return Dismissible(
                                          key: ValueKey(context.watch<Profile>().exercises[index][exerciseIndex]),
                                          
                                          direction: DismissDirection.endToStart,
                                            background: Container(
                                              color: Colors.red,
                                              child: Icon(Icons.delete)
                                            ),
                                                      
                                          onDismissed: (direction) {
                                            HapticFeedback.heavyImpact();
                                            // Remove the item from the data source.
                                            setState(() {
                                              context.read<Profile>().exercisePop(index1: index, index2: exerciseIndex);    
                                            });
                                            
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  style: TextStyle(
                                                    color: Colors.white
                                                  ),
                                                  'exercise Deleted'
                                                ),
                                                  
                                              ),
                                            );
                                          },
                                          //actual information about the exercise
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.all(Radius.circular(1)),
                                              border: Border(bottom: BorderSide(color: lighten(Color(0xFF1e2025), 20)/*Theme.of(context).dividerColor*/, width: 0.5),),
                                            ),
                                            child: Material(
                                              color: const Color(0xFF1e2025),//_listColorFlop(index: exerciseIndex),
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
                                                              context.watch<Profile>().exercises[index][exerciseIndex].exerciseTitle,
                                                                                                    
                                                              style: TextStyle(
                                                                color: Color.fromARGB(255, 255, 255, 255),
                                                                fontSize: 16,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                            
                                                        //add set button 
                                                        Align(
                                                          key: ValueKey('setAdder'),
                                                          alignment: Alignment.centerLeft,
                                            
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
                                                                  padding: EdgeInsets.only(top: 0, bottom: 0, right: 0, left: 8),
                                                                  //alignment: Alignment.centerLeft,
                                                                  backgroundColor: const Color(0xFF1e2025),//_listColorFlop(index: exerciseIndex + 1),
                                                                  shape:
                                                                    RoundedRectangleBorder(
                                                                       side: BorderSide(
                                                                        width: 2,
                                                                        color: Color(0XFF1A78EB),
                                                                       ),
                                                                       borderRadius: BorderRadius.all(Radius.circular(8))
                                                                    ),
                                                                  
                                                                ),
                                                              
                                                                onPressed: () {
                                                                  HapticFeedback.heavyImpact();
                                                                  setState(() {
                                                                    context.read<Profile>().setsAppend(
                                                                      // newSets: 
                                                                      // SplitDayData(data: "New Set", dayColor: Colors.black), 
                                                                      index1: index,
                                                                      index2: exerciseIndex,
                                                                    );
                                                                  });  
                                                                },
                                                                label: Row(
                                                                  children:  [
                                                                    Icon(
                                                                      Icons.add,
                                                                      color: lighten(Color(0xFF141414), 70),
                                                                    ),
                                                                    Text(
                                                                      "Set",
                                                                      style: TextStyle(
                                                                        color: lighten(Color(0xFF141414), 70),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                        
                                                        ),
                                                      
                                                    
                                                        //confirm update button
                                                        IconButton(
                                                          onPressed: () async{
                                                            
                                                          HapticFeedback.heavyImpact();
                                                            //print(context.read<Profile>().split[index].data);
                                                            alertTEC = TextEditingController(text: context.read<Profile>().exercises[index][exerciseIndex].exerciseTitle);
                                                            String? exerciseTitle = await openDialog();
                                                            if (exerciseTitle == null || exerciseTitle.isEmpty) return;
                                                                
                                                            setState( () {
                                                              Provider.of<Profile>(context, listen: false).exerciseAssign(
                                                                index1: index, 
                                                                index2: exerciseIndex,
                                                                data: Provider.of<Profile>(context, listen: false).exercises[index][exerciseIndex].copyWith(newexerciseTitle: exerciseTitle)
                                                                // data: SplitDayData(
                                                                //   data: exerciseTitle, dayColor: context.read<Profile>().split[index].dayColor
                                                                // ),
                                                                
                                                                // newSets: context.read<Profile>().sets[index][exerciseIndex],
                                                       
                                                                // newSetsTEC: context.read<Profile>().setsTEC[index][exerciseIndex],
                    
                    
                                                                // newRpeTEC: context.read<Profile>().rpeTEC[index][exerciseIndex],
                    
                                                          
                                                                // newReps1TEC: context.read<Profile>().reps1TEC[index][exerciseIndex],
                    
                    
                                                                // newReps2TEC: context.read<Profile>().reps2TEC[index][exerciseIndex],
                                                              );
                                                            });
                                                          }, 
                                                          
                                                          icon: Icon(Icons.edit),
                                                              color: lighten(Color(0xFF141414), 70),
                                                        ),
                                                      ],
                                                    ),
                                              
                                                    //Displaying Sets for each exercise
                                                    ReorderableListView.builder(
                                                      //on reorder, update tree with new ordering
                                                      onReorder: (oldIndex, newIndex){
                                                        HapticFeedback.heavyImpact();
                                                        setState(() {
                                                          context.read<Profile>().moveSet(oldIndex: oldIndex, newIndex: newIndex, dayIndex: index, exerciseIndex: exerciseIndex);
                                                        });
                                                      },
                                              
                                                      //being able to scroll within the already scrollable day view 
                                                      // is annoying so i disabled it
                                                      physics: const NeverScrollableScrollPhysics(),
                                                      itemCount: context.read<Profile>().sets[index][exerciseIndex].length,
                                                      shrinkWrap: true,
                                              
                                                      //displaying list of sets for that exercise
                                                      //TODO: add sets here too, centre text boxes, add notes option on dropdown
                                                      itemBuilder: (context, setIndex) {
                                                        return Dismissible(
                                                          key: ValueKey(context.watch<Profile>().sets[index][exerciseIndex][setIndex]),
                                              
                                                          direction: DismissDirection.endToStart,
                                                          background: Container(
                                                            color: Colors.red,
                                                            child: Icon(Icons.delete)
                                                          ),
                                                                
                                                          onDismissed: (direction) {
                                                            HapticFeedback.heavyImpact();
                                                            // Remove the item from the data source.
                                                            setState(() {
                                                              context.read<Profile>().setsPop(
                                                                index1: index, 
                                                                index2: exerciseIndex,
                                                                index3: setIndex,
                                                              );    
                                                            });
                                                
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  style: TextStyle(
                                                                    color: Colors.white
                                                                  ),
                                                                  'exercise Deleted'
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
                                                                  child: Focus(
                                                                    onFocusChange: (hasFocus) {
                                                                      if (hasFocus){
                                                                        setState((){context.read<Profile>().done = true;});
                                                                      }//else{
                                                                        //setState((){context.read<Profile>().done = false;});
                                                                      //}
                                                                    
                                                                      
                                                                    },
                                                                    child: TextFormField(
                                                                      
                                                                     
                                                                    
                                                                      controller: context.watch<Profile>().setsTEC[index][exerciseIndex][setIndex],
                    
                                                                      // onFieldSubmitted: (value){
                                                                      //   //HapticFeedback.heavyImpact();
                                                                      //   //Navigator.of(context).pop(alertTEC.text);
                                                                      // },
                                                                            
                                                                      keyboardType: TextInputType.number,
                                                                      decoration: InputDecoration(
                                                                        filled: true,
                                                                        fillColor: darken(Color(0xFF1e2025), 25),
                                                                        contentPadding: EdgeInsets.only(
                                                                          bottom: 10, 
                                                                          left: 8 
                                                                        ),
                                                                        constraints: BoxConstraints(
                                                                          maxWidth: 50,
                                                                          maxHeight: 30,
                                                                        ),
                                                                        border: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.all(Radius.circular(8))),
                                                                        hintText: 'Sets', //This should be made to be whateever this value was last workout
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                          
                                                                Padding(
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  child: Focus(
                                                                    onFocusChange: (hasFocus) {
                                                                      if (hasFocus){
                                                                        setState((){context.read<Profile>().done = true;});
                                                                      }
                                                                      // }else{
                                                                      //   setState((){context.read<Profile>().done = false;});
                                                                      // }
                                                                    
                                                                      
                                                                    },
                                                                    child: TextFormField(
                                                                    
                                                                      controller: context.watch<Profile>().rpeTEC[index][exerciseIndex][setIndex],
                                                                     
                                                                      keyboardType: TextInputType. numberWithOptions(decimal: true),
                                                                                                          
                                                                      decoration:  InputDecoration(
                                                                        filled: true,
                                                                        fillColor: darken(Color(0xFF1e2025), 25),
                                                                        contentPadding: EdgeInsets.only(
                                                                          bottom: 10, 
                                                                          left: 8 
                                                                        ),
                                                                        constraints: BoxConstraints(
                                                                          maxWidth: 80,
                                                                          maxHeight: 30,
                                                                        ),
                                                                        border: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.all(Radius.circular(8))),
                                                                        hintText: 'RPE', //This should be made to be whateever this value was last workout
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                          
                                                                Icon(Icons.clear),
                                                                          
                                                                Padding(
                                                                  padding: const EdgeInsets.all(8.0),
                                                                  child: Focus(
                                                                    onFocusChange: (hasFocus) {
                                                                      if (hasFocus){
                                                                        setState((){context.read<Profile>().done = true;});}
                                                                      // }else{
                                                                      //   setState((){context.read<Profile>().done = false;});
                                                                      // }
                                                                    
                                                                      
                                                                    },
                                                                    child: TextFormField(
                                                                      
                                                                      controller: context.watch<Profile>().reps1TEC[index][exerciseIndex][setIndex],
                                              
                                                                      
                                                                      keyboardType: TextInputType. numberWithOptions(decimal: true,),
                                                                      decoration: InputDecoration(
                                                                        filled: true,
                                                                        fillColor: darken(Color(0xFF1e2025), 25),
                                                                        contentPadding: EdgeInsets.only(
                                                                          bottom: 10, 
                                                                          left: 8 
                                                                        ),
                                                                        constraints: BoxConstraints(
                                                                          maxWidth: 80,
                                                                          maxHeight: 30,
                                                                        ),
                                                                        border: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.all(Radius.circular(8))),
                                                                        hintText: 'Reps', //This should be made to be whateever this value was last workout
                                                                      ),
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
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ]
                              ),
                            ),
                          ),
                        )
                      ),  
                    );
                  },
              ),
            ),
            SizedBox(height: 82),
          ],
        ),
      ),
    );
  }

  
  //TODO: move to another file
  //this is to show text box to enter text for day titles and exercises
  Future<String?> openDialog() {
    //alertTEC = TextEditingController(text: hints);
    return showDialog(
      
      context: context,
      builder: (context) => AlertDialog(
        title: TextFormField(
          onFieldSubmitted: (value){
            HapticFeedback.heavyImpact();
            Navigator.of(context).pop(alertTEC.text);
          },
          autofocus: true,
          controller: alertTEC,
          decoration: InputDecoration(
            hintText: "Enter Text",
          ),
        ),
        actions: [
          IconButton(
            onPressed: (){
              HapticFeedback.heavyImpact();
              Navigator.of(context).pop(alertTEC.text);
            },
            icon: Icon(Icons.check))
        ]
      ),
    );
  }


  Widget buildBottomSheet(){
    // if we should be displaying done button for numeric keyboard, then create.
    // else display calendar
  if (context.read<Profile>().done){ 
    //return done bottom sheet
    return Container(
      decoration: BoxDecoration(

        border: Border(
          top: BorderSide(
            color:  lighten(Color(0xFF141414), 20),
          ),
        ),
        
        color: Color(0xFF1e2025),
          //borderRadius: BorderRadius.circular(12.0),
        ),

        height: 50,
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ButtonStyle(
                //when clicked, it splashes a lighter purple to show that button was clicked
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)
                  ),
                ),
                backgroundColor: WidgetStateProperty.all(Color(0xFF6c6e6e),),
              ),
                
              onPressed: () {
                WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
                context.read<Profile>().done = false;
                setState((){});
              },

              child: Text(
                'Done',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      }else{
        // return calendary bottom sheet


              return Container(
                color: Color(0xFF1e2025),
                padding: const EdgeInsets.all(8.0),
                height: 82,
                child: TableCalendar(
                  headerVisible: false,
                  calendarFormat: CalendarFormat.week,
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      DateTime origin = DateTime(2024, 1, 7);

                      for (int splitDay = 0; splitDay < context.watch<Profile>().split.length; splitDay ++){
                        int diff = daysBetween(origin , day) % context.watch<Profile>().splitLength;
                        if (diff == (context.watch<Profile>().splitLength ~/ context.watch<Profile>().split.length) * splitDay) {
                          return Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(context.watch<Profile>().split[splitDay].dayColor),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        }
                      }
                      
                      return null;
                    },
                  ),

                  rowHeight: 50,
                  focusedDay: today, 
                  firstDay: DateTime.utc(2010, 10, 16), 
                  lastDay: DateTime.utc(2030, 3, 14),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.white), // Color for weekdays (Mon-Fri)
                      weekendStyle: TextStyle(color: Colors.white),   // Color for weekends (Sat-Sun)
                ),
              ),
            );
      }
  }

  // TODO: keep this at the top of the screen, but not go off screen when keyboard comes up
  // its jarring when it bounces around
  Widget editBuilder(index){ 
          alertTEC = TextEditingController(text: context.watch<Profile>().split[index].dayTitle);
          

          // Ensure text is selected when the widget is built
          alertTEC.selection = TextSelection(
            baseOffset: 0,
            extentOffset: alertTEC.text.length,
          );

          if(_sliding == 0){
            //Value = MediaQuery.sizeOf(context).height - 450;
            return SizedBox(
              height: 100,
              width: 300,
              child: TextFormField(
                  
                  onFieldSubmitted: (value){
                    HapticFeedback.heavyImpact();
                    Navigator.of(context).pop(alertTEC.text);
                  },
                  autofocus: true,
                  controller: alertTEC,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: alertTEC.clear,
                      icon: Icon(Icons.highlight_remove),
                    ),
                    
                    hintText: "Enter Text",
                  )
                ),
            );

          }else{
                return SizedBox(
                  height: 250,
                  width: 300,
                  child: SingleChildScrollView(
                    
                    child: BlockPicker(
                      pickerColor: Color(context.watch<Profile>().split[index].dayColor),
                      onColorChanged: (Color color) {
                        context.read<Profile>().splitAssign(
                          
                          index: index,
                          newDay: context.read<Profile>().split[index].copyWith(newDayColor: color.value),

                        );
                        setState(() {});
                      },
                        
                      
                      availableColors: Profile.colors,
                      layoutBuilder: pickerLayoutBuilder,
                      itemBuilder: pickerItemBuilder,
                    ),
                  ),
                );
          }
  }
}
