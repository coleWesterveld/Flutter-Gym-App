// program page
// ignore_for_file: prefer_const_constructors

/*
Still Todo on this page:
- change colours, make customizeable by user
- move random functions to their own files
- make more modular, this file feels unnecessarily long 
- ability to add notes per excercise
- change look of title
- PERSISTENCE for excercises and set data, notes, title
  - either through shared preferences or local SQLite database
- Change look of calendar, right now big blocks of colour are too much
- stop bottom from being like stuck too low
- I think i dont need focusnodes in user profile? would probably be a lot easier on memory and stuff to get rid

- LATER: add sidebar, user can have multiple different programs to swap between
*/

//import 'package:firstapp/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'user.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'data_saving.dart';



//import 'package:flutter/cupertino.dart';



//TODO: gradient background

import 'package:flutter/services.dart';

// TODO: add excercise and set persistence - may have to use SQLite database as opposed to shared preferences
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
// then excercises for each day with sets, rep range and notes
class ProgramPage extends StatefulWidget {
  Function writePrefs;
  
  ProgramPage({Key? programkey, required this.writePrefs,}) : super(key: programkey);
  @override
  _MyListState createState() => _MyListState();
}


enum Viewer {title, color}
// this class contains the list view of expandable card tiles 
// title is day title (eg. 'legs') and when expanded, leg excercises for that day show up
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
        newDay: "New Day", 
        newExcercises: [], 
        newSets: [],
        newReps1TEC: [],
        newReps2TEC: [],
        newRpeTEC: [],
        newSetsTEC: [],
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
        
      
        bottomSheet: context.read<Profile>().done
            ? Container(
                
                decoration: BoxDecoration(
                  border:
                  Border(top: BorderSide(
                    color:  lighten(Color(0xFF141414), 20),
                  )),
          
            
      
              
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
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                
                          borderRadius: BorderRadius.circular(4))),
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
              )
            : 
      
            Container(
                color: Color(0xFF1e2025),
                padding: const EdgeInsets.all(8.0),
                height: 82,
          child: TableCalendar(
            headerVisible: false,
            calendarStyle: CalendarStyle(
              
              
            ),
            calendarFormat: CalendarFormat.week,
                    calendarBuilders: CalendarBuilders(
                      
                  defaultBuilder: (context, day, focusedDay) {
                    
                    DateTime origin = DateTime(2024, 1, 7);
                    for (int splitDay = 0; splitDay < context.watch<Profile>().split.length; splitDay ++){
          
                      int diff = daysBetween(origin , day) % context.watch<Profile>().splitLength;
                      if (diff == (context.watch<Profile>().splitLength ~/ context.watch<Profile>().split.length) * splitDay) {
                        return Container(
                          decoration: BoxDecoration(
                            color: context.watch<Profile>().split[splitDay].dayColor,
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
              ),
      
      
      
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
        body: SizedBox(
          height: 650,
          child: ReorderableListView.builder(
            //reordering days
              onReorder: (oldIndex, newIndex){
                HapticFeedback.heavyImpact();
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  SplitDayData x = Provider.of<Profile>(context, listen: false).split[oldIndex];
                  List<SplitDayData> y = context.read<Profile>().excercises[oldIndex];
                  List<List<SplitDayData>> z = context.read<Profile>().sets[oldIndex];
                  
                 
                  List<List<TextEditingController>> b = context.read<Profile>().setsTEC[oldIndex];
      
                 
                  List<List<TextEditingController>> d = context.read<Profile>().reps1TEC[oldIndex];
      
                 
                  List<List<TextEditingController>> f = context.read<Profile>().reps2TEC[oldIndex];
      
                  
                  List<List<TextEditingController>> h = context.read<Profile>().rpeTEC[oldIndex];
      
      
                  context.read<Profile>().splitPop(index: oldIndex);
      
                  context.read<Profile>().splitInsert(
                    index: newIndex, 
                    days: x, 
                    excerciseList: y, 
                    newSets: z,
                    
                    newSetsTEC: b,
                   
                    newReps1TEC: d,
                   
                    newReps2TEC: f,
                    
                    newRpeTEC: h,
                  );
                });
                widget.writePrefs();
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
                      widget.writePrefs();
                      
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: 50.0,
                      child: Icon(Icons.add),
                    ),
                  ),
                ),
              ),
        
              //TODO: fix same globalkey error when reordering excercises
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
                    widget.writePrefs();
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
                            context.watch<Profile>().split[index].dayColor,
                            context.watch<Profile>().split[index].dayColor,
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
                          
                          //expandable to see excercises and sets for that day
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
                                          
                                          color: darken(context.watch<Profile>().split[index].dayColor, 70),
                                          fontSize: 50,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                                    
                                              //day title
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(left : 16.0),
                                              child: Text(
                                                context.watch<Profile>().split[index].data,
                                                style: TextStyle(
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
                                                          newExcercises: context.read<Profile>().excercises[index],
                                                          newSets: context.read<Profile>().sets[index],
      
                                                          newSetsTEC: context.read<Profile>().setsTEC[index],
      
                                                          newReps1TEC: context.read<Profile>().reps1TEC[index],
      
                                                          newReps2TEC: context.read<Profile>().reps2TEC[index],
      
                                                          newRpeTEC: context.read<Profile>().rpeTEC[index],
      
                                                          newDay: SplitDayData(
                                                            data: dayTitle, dayColor: context.read<Profile>().split[index].dayColor
                                                          )
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
                                    
                                      widget.writePrefs();
                                    },
        
                                    icon: Icon(Icons.edit_outlined),
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ),
                                  
                            //children of expansion tile - what gets shown when user expands that day
                            // shows excercises for that day
                            //this part is viewed after tile is expanded
                            //TODO: show sets per excercise, notes, maybe most recent weight/reps
                            //excercises are reorderable
      
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
                                      if (newIndex > oldIndex) {
                                        newIndex -= 1;
                                      }
                                      //swap excercise list
                                      SplitDayData x = Provider.of<Profile>(context, listen: false).excercises[index][oldIndex];
                                      
                                      List<SplitDayData> y = Provider.of<Profile>(context, listen: false).sets[index][oldIndex];
      
                                      List<TextEditingController> b = Provider.of<Profile>(context, listen: false).setsTEC[index][oldIndex];
      
                                      List<TextEditingController> d = Provider.of<Profile>(context, listen: false).reps1TEC[index][oldIndex];
      
                                      List<TextEditingController> f = Provider.of<Profile>(context, listen: false).reps2TEC[index][oldIndex];
      
                                      List<TextEditingController> h = Provider.of<Profile>(context, listen: false).rpeTEC[index][oldIndex];
                                      
                                      context.read<Profile>().excercisePop(index1: index, index2: oldIndex);
                                      
                                      context.read<Profile>().excerciseInsert(
                                        index1: index, 
                                        index2: newIndex, 
                                        data: x, 
                                        newSets: y,
                            
                                        newSetsTEC: b,
                              
                                        newReps1TEC: d,
                                  
                                        newReps2TEC: f,
                                  
                                        newRpeTEC: h,
                                      );
                                    });
                                  },
                                  
                                  //"add excercise" button at bottom of excercise list
                                  footer: Padding(
                                    key: ValueKey('excerciseAdder'),
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
                                              context.read<Profile>().excerciseAppend( newExcercise: 
                                                SplitDayData(data: "New Excercise", dayColor: Colors.black), 
                                                index: index,
                                                newSets: [],
                                             
                                                newReps1TEC: [],
                                            
                                                newReps2TEC: [],
                                               
                                                newRpeTEC: [],
                                               
                                                newSetsTEC: [],
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
                                
                                                "Excercise  ",
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
                                  itemCount: context.read<Profile>().excercises[index].length,
                                  shrinkWrap: true,
                                  
                                      
                                  //displaying list of excercises for that day
                                  //TODO: add sets here too, centre text boxes, add notes option on dropdown
                                  itemBuilder: (context, excerciseIndex) {
                                    return Dismissible(
                                      key: ValueKey(context.watch<Profile>().excercises[index][excerciseIndex]),
                                      
                                      direction: DismissDirection.endToStart,
                                        background: Container(
                                          color: Colors.red,
                                          child: Icon(Icons.delete)
                                        ),
                                                  
                                      onDismissed: (direction) {
                                        HapticFeedback.heavyImpact();
                                        // Remove the item from the data source.
                                        setState(() {
                                          context.read<Profile>().excercisePop(index1: index, index2: excerciseIndex);    
                                        });
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              style: TextStyle(
                                                color: Colors.white
                                              ),
                                              'Excercise Deleted'
                                            ),
                                              
                                          ),
                                        );
                                      },
                                      //actual information about the excercise
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.all(Radius.circular(1)),
                                          border: Border(bottom: BorderSide(color: lighten(Color(0xFF1e2025), 20)/*Theme.of(context).dividerColor*/, width: 0.5),),
                                        ),
                                        child: Material(
                                          color: const Color(0xFF1e2025),//_listColorFlop(index: excerciseIndex),
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
                                                              backgroundColor: const Color(0xFF1e2025),//_listColorFlop(index: excerciseIndex + 1),
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
                                                                  newSets: 
                                                                  SplitDayData(data: "New Set", dayColor: Colors.black), 
                                                                  index1: index,
                                                                  index2: excerciseIndex,
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
                                                        alertTEC = TextEditingController(text: context.read<Profile>().excercises[index][excerciseIndex].data);
                                                        String? excerciseTitle = await openDialog();
                                                        if (excerciseTitle == null || excerciseTitle.isEmpty) return;
                                                            
                                                        setState( () {
                                                          Provider.of<Profile>(context, listen: false).excerciseAssign(
                                                            index1: index, 
                                                            index2: excerciseIndex,
                                                            data: SplitDayData(
                                                              data: excerciseTitle, dayColor: context.read<Profile>().split[index].dayColor
                                                            ),
                                                            
                                                            newSets: context.read<Profile>().sets[index][excerciseIndex],
                                                   
                                                            newSetsTEC: context.read<Profile>().setsTEC[index][excerciseIndex],
      
      
                                                            newRpeTEC: context.read<Profile>().rpeTEC[index][excerciseIndex],
      
                                                      
                                                            newReps1TEC: context.read<Profile>().reps1TEC[index][excerciseIndex],
      
      
                                                            newReps2TEC: context.read<Profile>().reps2TEC[index][excerciseIndex],
                                                          );
                                                        });
                                                      }, 
                                                      
                                                      icon: Icon(Icons.edit),
                                                          color: lighten(Color(0xFF141414), 70),
                                                    ),
                                                  ],
                                                ),
                                          
                                                //Displaying Sets for each excercise
                                                ReorderableListView.builder(
                                                  //on reorder, update tree with new ordering
                                                  onReorder: (oldIndex, newIndex){
                                                    HapticFeedback.heavyImpact();
                                                    setState(() {
                                                      if (newIndex > oldIndex) {
                                                        newIndex -= 1;
                                                      }
                                                      //swap excercise list
                                                      SplitDayData x = Provider.of<Profile>(context, listen: false).sets[index][excerciseIndex][oldIndex];
                                          
                                                      context.read<Profile>().setsPop(
                                                        index1: index, 
                                                        index2: excerciseIndex, 
                                                        index3: oldIndex
                                                      );
                                          
                                                      context.read<Profile>().setsInsert(
                                                        index1: index, 
                                                        index2: excerciseIndex, 
                                                        index3: newIndex, 
                                                        data: x
                                                      );
                                                    });
                                                  },
                                          
                                                  //being able to scroll within the already scrollable day view 
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
                                                        child: Icon(Icons.delete)
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
                                                          SnackBar(
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
                                                              child: Focus(
                                                                onFocusChange: (hasFocus) {
                                                                  if (hasFocus){
                                                                    setState((){context.read<Profile>().done = true;});
                                                                  }//else{
                                                                    //setState((){context.read<Profile>().done = false;});
                                                                  //}
                                                                
                                                                  
                                                                },
                                                                child: TextFormField(
                                                                 
                                                                
                                                                  controller: context.watch<Profile>().setsTEC[index][excerciseIndex][setIndex],
      
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
                                                                
                                                                  controller: context.watch<Profile>().rpeTEC[index][excerciseIndex][setIndex],
                                                                 
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
                                                                  
                                                                  controller: context.watch<Profile>().reps1TEC[index][excerciseIndex][setIndex],
                                          
                                                                  
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
      ),
    );
  }

  
  //TODO: move to another file
  //this is to show text box to enter text for day titles and excercises
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

  // TODO: keep this at the top of the screen, but not go off screen when keyboard comes up
  // its jarring when it bounces around
  Widget editBuilder(index){
    alertTEC = TextEditingController(text: context.read<Profile>().split[index].data);
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
            hintText: "Enter Text",
          )
        ),
    );


        
    }else{
          //alertInsetValue = MediaQuery.sizeOf(context).height - 300;
          return SizedBox(
            height: 250,
            width: 300,
            child: SingleChildScrollView(
              
              child: BlockPicker(
                pickerColor: context.watch<Profile>().split[index].dayColor,
                onColorChanged: (Color color) {
                  context.read<Profile>().splitAssign(
                    index: index,
                    newDay: SplitDayData(data: context.read<Profile>().split[index].data, dayColor: color),
                    newExcercises: context.read<Profile>().excercises[index],
                    newSets: context.read<Profile>().sets[index],

                  
                    newSetsTEC: context.read<Profile>().setsTEC[index],

             
                    newRpeTEC: context.read<Profile>().rpeTEC[index],

            
                    newReps1TEC: context.read<Profile>().reps1TEC[index],

                   
                    newReps2TEC: context.read<Profile>().reps2TEC[index],
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


// Color _listColorFlop({required int index, Color bgColor = const Color(0xFF151218)}){
//   if (index % 2 == 0){
//     return lighten(bgColor, 5);
//   }
//   else{
//     return bgColor;
//   }
}