// ignore_for_file: prefer_const_constructors
// TODO: this shoudl come back just for now it was everywhere and annoying

import 'package:dotted_border/dotted_border.dart';
import 'package:firstapp/schedule_page.dart';
import 'package:flutter/material.dart';
import 'user.dart';
import 'database/profile.dart';
import 'package:provider/provider.dart';

// this page whats left: 
// TODO: make pretty - notably, when a day hovers another day, preview changes
// TODO: make repeat every and start day functional
// reflect changes on this page back in schedule 
// done button to repeat every 
// better dropdown - match OS?
// undo button on drag and drop, in case of accidental drag when trying to scroll
// find out what a good length is fro long press draggable
// could add a save and cancel button, so that user can easily undo any reordering that they did if they dont like

// TODO: on reorder, we need to actually update the dayOrder
// therefore, either the min list is the highest dayorder, 
// or we need to reorder days automatically sometimes when shrinking the list
// what i think is that any days longer than the proposed shorter list shoudl stack up at the end.
// then we max out when days are stacked as much as they can and the list would just be too small.
// splitLength auto resets when we add days on split, we should fix how that works

// basically, atp the UI is mostly done, business logic is only probably 1/3 done

// This page mostly works IN ISOLATION, but not fully with everything
// i am not saving origin 

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

Color lighten(Color c, [int percent = 10]) {
  // not very fond of this solution, it seems to work though. 
  // will have to migrate from previous solution as colors is moving from 0-255 to 0-1
  assert(1 <= percent && percent <= 100);
  var p = percent / 100;
  return Color.lerp(
  c, Colors.white, p
  )!;
      
}


class EditSchedule extends StatefulWidget {
  @override
  _EditScheduleState createState() => _EditScheduleState();
}

class _EditScheduleState extends State<EditSchedule> {
  int startDay = 0;
  // List of days with initial content
  List<Day?> _days = [];
  TextEditingController splitLenTEC = TextEditingController();
  

  @override
  void initState() {
    startDay = context.read<Profile>().origin.weekday - 1;

    splitLenTEC.text = context.read<Profile>().splitLength.toString();

    generateDays();
    //debugPrint(_days.toString());
    super.initState();
  }


  void generateDays(){
    List<Day?> newDays = [];
    _days = context.read<Profile>().split;
    //debugPrint(_days.toString());

    int oldIdx = 0;
    if (_days.isNotEmpty){
      for (int i = 0; i < context.read<Profile>().splitLength; i++){
        if (oldIdx < _days.length &&_days[oldIdx]!.dayOrder == i){
          newDays.add(_days[oldIdx]);

          
          oldIdx ++;
        }
        else{
          newDays.add(null);
        }
      }
    }
    _days = newDays;
  }
  

  @override
  Widget build(BuildContext context) {
    //debugPrint(_days.toString());


    return GestureDetector(

      onTap: (){
            WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
            Provider.of<Profile>(context, listen: false).changeDone(false);
        },

      child: Scaffold(
      
        bottomSheet: buildBottomSheet(),
      
        appBar: AppBar(
          backgroundColor: const Color(0xFF1e2025),
          title: const Text(
            "Edit Schedule",
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
      
          ),
      
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(80.0), // Height of the persistent widget
            child: Container(
              //color: Colors.blue[100], // Background color
              padding: EdgeInsets.all(8.0), // Padding for the persistent widget
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    
                    decoration: BoxDecoration(
                      color: darken(Color(0xFF1e2025), 40),
                      borderRadius: BorderRadius.circular(8)
                    ),
      
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          
                      
                          Text(
                            "Repeat Every:",
      
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            )
                          ),
      
                          SizedBox(height: 5),
      
                          //TODO: it would maybe be good to have these dropdowns match the OS of user
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Focus(
                                onFocusChange: (hasFocus) {

                                  // this should not allow splitlength to be shorter than number of days 
                                  if (!hasFocus){
                                    
                                    
                                    if (splitLenTEC.text.isNotEmpty){
                                      if (int.parse(splitLenTEC.text) < context.read<Profile>().split.length){
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Length must be at least number of days in split (${context.read<Profile>().split.length})")),
                                        );
                                      }
                                      else{

                                        setState(() {
                                          context.read<Profile>().done = false;
                                          context.read<Profile>().splitLength = int.parse(splitLenTEC.text);
                                        
                                        });

                                      }
                                      
                                      // I made this a second setsate with the idea being that this might take a bit longer, 
                                      // and I want the done button going away to be fast, so it happens first, displays, and then we do this.
                                      // by slower, its like.. <0.25s but yeah
                                      // this is theory and im not an expert so should be tested during optimization.
                                      
                                      setState(() {
                                        generateDays();
                                      });

                                    }else{
                                      splitLenTEC.text = context.read<Profile>().splitLength.toString();
                                    }



                                  }
                                  else{
                                      //debugPrint("no");
                                      splitLenTEC.selection = TextSelection(
                                        baseOffset: 0,
                                        extentOffset: splitLenTEC.text.length,
                                      );
                                      
                                      setState(() {
                                        context.read<Profile>().done = true;
                                      });
                                      
                                    }
                                },
      
                                child: TextFormField(
                                  controller: splitLenTEC,
                                                                        
                                  //controller: context.watch<Profile>().rpeTEC[index][excerciseIndex][setIndex],
                                  
                                  keyboardType: TextInputType. numberWithOptions(decimal: true),
                                                                      
                                  decoration:  InputDecoration(
                                    filled: true,
                                    fillColor: Color(0xFF1e2025),
                                    contentPadding: EdgeInsets.only(
                                      bottom: 10, 
                                      left: 8 
                                    ),
                                    constraints: BoxConstraints(
                                      maxWidth: 30,
                                      maxHeight: 30,
                                    ),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(8))),
                                    //hintText: context.watch<Profile>().splitLength.toString(), //This should be made to be whateever this value was last workout
                                  ),
                                ),
                              ),
                              SizedBox(width: 5),
                          
                              Text(
                                "Days",
                                style: TextStyle(
                                  height: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            ]
                          ),
      
                          
                        ],
                      ),
                    ),
                  ),
                  Container(
                    
                    decoration: BoxDecoration(
                      color: darken(Color(0xFF1e2025), 40),
                      borderRadius: BorderRadius.circular(8)
                    ),
      
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        
                          children: [
                            
                            
                            DropdownButton<int>(
                              isDense: true,
                              value: startDay,
                              items: const [
                                DropdownMenuItem(value: 0, child: Text("Monday")),
                                DropdownMenuItem(value: 1, child: Text("Tuesday")),
                                DropdownMenuItem(value: 2, child: Text("Wednesday")),
                                DropdownMenuItem(value: 3, child: Text("Thursday")),
                                DropdownMenuItem(value: 4, child: Text("Friday")),
                                DropdownMenuItem(value: 5, child: Text("Saturday")),
                                DropdownMenuItem(value: 6, child: Text("Sunday")),
                              ],
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    startDay = newValue;
                                    context.read<Profile>().origin = getDayOfCurrentWeek(startDay + 1);
                                  });
                                  }
                                
                                // Handle starting day change
                              },
                          ),
                          SizedBox(height: 5),
                          Text(
                              "Start Day",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              )
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
           
        
        body: _days.isEmpty ? 
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Align(
            alignment: Alignment.topCenter,
        
            child: Text("No Days In Split",
              style: TextStyle(
                //height: 0.5,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: lighten(const Color(0xFF1e2025), 40)
              )
            )
          ),
        )
        :
        ListView.builder(
          itemCount: _days.length,
        
          itemBuilder: (context, index){
        
            return DragTarget<Day>(
              onAcceptWithDetails: (details) {
                setState(() {
                  final oldIndex = _days.indexOf(details.data);
                  final targetContent = _days[index];

                  if (targetContent == null || oldIndex == index) {
                    _days[oldIndex] = null;
                    _days[index] = details.data;
                  } else {
                    _days[oldIndex] = null;

                    int closestIndex = -1;
                    int minDistance = _days.length; // Start with the maximum possible distance

                    for (int i = 0; i < _days.length; i++) {
                      if (_days[i] == null) {
                        int distance = (i - index).abs(); // Calculate distance to oldIndex
                        if (distance < minDistance) {
                          closestIndex = i; // Update closest index
                          minDistance = distance;
                        }
                      }
                    }

                    final nextIndex = closestIndex; // Set the closest available index
                    if (nextIndex != -1) {
                      _days[oldIndex] = null;
                      _days[nextIndex] = targetContent;
                      _days[index] = details.data;
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No available slot to move the existing day.")),
                      );
                    }
                  }

                  // Update dayOrder for all days in both _days and split
                  for (int i = 0; i < _days.length; i++) {
                    if (_days[i] != null) {
                      // Update the dayOrder property directly
                      _days[i]!.dayOrder = i;

                      // Find the index in the split list and update there as well
                      int splitIndex = context.read<Profile>().split.indexWhere((day) => day.dayID == _days[i]!.dayID);
                      if (splitIndex != -1) {
                        context.read<Profile>().splitAssign(newDay: _days[i]!, index: splitIndex);
                      }
                    }
                  }
                });

                //ebugPrint(context.read<Profile>().split[2].toString());
                //debugPrint(context.read<Profile>().origin.toString());
              },
        
              builder: (context, candidateData, rejectedData) {
                final isActive = candidateData.isNotEmpty;
                if (_days[index] != null) {
                  return _DraggableDay(days: _days, index: index, startDay: startDay);
        
                } else {
                  return _RestDay(isActive: isActive, index: index, startDay: startDay);
                }
                // for draggable: 
                // child is initial state, before dragging
                // feedback is widget as it is dragged
                // child when dragging is what is displayed at anchor (origin) during dragging
                // data is data transmitted to dragtarget on drop (will be a day)
              },
            );
          }
          
        )
      ),
    );
  }

  Widget? buildBottomSheet(){
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
        return null;
      }
    }
  }


class _RestDay extends StatelessWidget {
  const  _RestDay({
    //super.key,
    required this.isActive,
    required this.index,
    required this.startDay,
  });

  final bool isActive;
  final int index;
  final int startDay;

  static List<String> daysOfWeek = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: DottedBorder(
        strokeWidth: 2,
        // [strokelength, spacelength]
        dashPattern: const [15, 10],
        borderType: BorderType.RRect, // Rounded rectangle border
        radius: Radius.circular(12),
        
        color: isActive ? lighten(Color(0XFF1A78EB), 20) : lighten(const Color(0xFF1e2025), 20),
        
        
        child: Container(
        height: 56,
        width: double.infinity,
        
        decoration: BoxDecoration(
          color: isActive ? Color(0XFF1A78EB) : const Color(0xFF1e2025),
          borderRadius: BorderRadius.circular(12),
          //border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  topLeft: Radius.circular(12),
                ),

                // border: Border(
                //   right: BorderSide(
                //     color: Colors.grey,
                //     width: 2.0,
                //   ),
                // ),

                color: darken(const Color(0xFF1e2025), 40),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                     
                      daysOfWeek[(index + startDay) % 7],
                      style: TextStyle(
                        height: 1.0,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    Text(
                     
                      "${index + 1}",
                    
                      style: TextStyle(
                        height: 1.0,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: lighten(const Color(0xFF1e2025), 60)
                      ),
                    ),
                  ],
                )
              ),

            ),

            Expanded(
              //width: double.infinity,
              child: Center(
                //alignment: Alignment.center,
                child: Container(
                  child: Text(
                    "Rest Day",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  )
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

class _DraggableDay extends StatelessWidget {
  // this widget isnt exactly following DRY, could use refactor
  const _DraggableDay({
    //super.key,
    required List<Day?> days,
    required int index,
    required int startDay,

  }) : 
  _days = days, 
  _index = index,
  _startDay = startDay;

  final List<Day?> _days;
  final int _index;
  final int _startDay;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable(

    // this should be tweaked - I want it to be pretty easy to drag and reorder 
    // cuz thats the whole purpose of this page
    // at the same time, user needs to be able to scroll whout dragging stuff everywhere instantly 

    delay: Duration(milliseconds: 200),
    data: _days[_index]!,
    
    feedback: Container(
      decoration: BoxDecoration(
      boxShadow: [
              BoxShadow(
                blurStyle: BlurStyle.normal,
                color: Colors.black.withValues(alpha: 0.6), // Shadow color
                offset: Offset(0, 4), // Horizontal and ßvertical offset
                blurRadius: 8, // Blur effect
                spreadRadius: 12, // Spread effect
              ),
            ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          child: Container(
              height: 70,
              width: MediaQuery.sizeOf(context).width,
              
              decoration: BoxDecoration(
                
      
                border: Border.all(
                  color: Color(_days[_index]!.dayColor),
                  
                  width: 3.0,
                ),
          
                borderRadius: BorderRadius.circular(13),
                //border: Border.all(color: Colors.white, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10.0),
                        topLeft: Radius.circular(10.0),
                        ),
                      // border: Border(
                      //   right: BorderSide(
                      //     color: Colors.grey,
                      //     width: 2.0,
                      //   ),
                      // ),
          
                      color: Color(_days[_index]!.dayColor),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
          
                           
                            _RestDay.daysOfWeek[(_index + _startDay) % 7],
                            style: TextStyle(
                              //color: darken(const Color(0xFF1e2025), 60),
                              height: 1.0,
                              fontSize: 20,
                              color: darken(Color(_days[_index]!.dayColor), 70),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
          
                          Text(
                           
                            "${_index + 1}",
                          
                            style: TextStyle(
                              height: 1.0,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: darken(Color(_days[_index]!.dayColor), 50)
                            ),
                          ),
                        ],
                      )
                    ),
          
                  ),
          
                  Expanded(
                    //width: double.infinity,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _days[_index]!.dayTitle,
                          style: TextStyle(
                            fontSize: 18,
                        
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
        ),
      ),
    ),
    
    childWhenDragging: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
          height: 60,//socks
          width: double.infinity,
          
          decoration: BoxDecoration(
            border: Border.all(
              color: Color(0xFF1e2025),
              //width: 2.0,
            ),

            borderRadius: BorderRadius.circular(12),
            //border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10.0),
                    topLeft: Radius.circular(10.0),
                    ),
                  // border: Border(
                  //   right: BorderSide(
                  //     color: Colors.grey,
                  //     width: 2.0,
                  //   ),
                  // ),
      
                  color: darken(Color(_days[_index]!.dayColor), 50),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(

                       
                        _RestDay.daysOfWeek[(_index + _startDay) % 7],
                        style: TextStyle(
                          //color: darken(const Color(0xFF1e2025), 60),
                          height: 1.0,
                          fontSize: 20,
                          color: darken(Color(_days[_index]!.dayColor), 80),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
      
                      Text(
                       
                        "${_index + 1}",
                      
                        style: TextStyle(
                          height: 1.0,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: darken(Color(_days[_index]!.dayColor), 60)
                        ),
                      ),
                    ],
                  )
                ),
      
              ),
      
              Expanded(
                //width: double.infinity,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _days[_index]!.dayTitle,
                      style: TextStyle(
                        fontSize: 18,
                        // this is ugly but works for now
                        color: (Theme.of(context).textTheme.bodyMedium != null && Theme.of(context).textTheme.bodyMedium!.color != null) 
                          ? darken(Theme.of(context).textTheme.bodyMedium!.color!, 30) : Colors.white,
                    
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
    ),

    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
          height: 60,
          width: double.infinity,
          
          decoration: BoxDecoration(
            border: Border.all(
              color: lighten(Color(0xFF1e2025), 20),
              //width: 2.0,
            ),

            borderRadius: BorderRadius.circular(12),
            //border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10.0),
                    topLeft: Radius.circular(10.0),
                    ),
                  // border: Border(
                  //   right: BorderSide(
                  //     color: Colors.grey,
                  //     width: 2.0,
                  //   ),
                  // ),
      
                  color: Color(_days[_index]!.dayColor),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(

                       
                        _RestDay.daysOfWeek[(_index + _startDay) % 7],
                        style: TextStyle(
                          //color: darken(const Color(0xFF1e2025), 60),
                          height: 1.0,
                          fontSize: 20,
                          color: darken(Color(_days[_index]!.dayColor), 70),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
      
                      Text(
                       
                        "${_index + 1}",
                      
                        style: TextStyle(
                          height: 1.0,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: darken(Color(_days[_index]!.dayColor), 50)
                        ),
                      ),
                    ],
                  )
                ),
      
              ),
      
              Expanded(
                //width: double.infinity,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _days[_index]!.dayTitle,
                      style: TextStyle(
                        fontSize: 18,
                    
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(Icons.drag_handle),
              ),
            ],
          ),
        ),
    ),
    );
  }
}
