// ignore_for_file: prefer_const_constructors
// TODO: this shoudl come back just for now it was everywhere and annoying

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'user.dart';
import 'database/profile.dart';
import 'package:provider/provider.dart';

// TODO: make pretty

// but also it needs to allow user to customize splitlength and choose day of week to start split
// also, like much of the code, could probably use a refactor at the end of it all

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
  // List of days with initial content
  List<Day?> _days = [];
  

  @override
  void initState() {
    List<Day?> _newDays = [];
    _days = context.read<Profile>().split;
    //debugPrint(_days.toString());

    

    int oldIdx = 0;
    if (_days.isNotEmpty){
      for (int i = 0; i < context.read<Profile>().splitLength; i++){
        if (oldIdx < _days.length &&_days[oldIdx]!.dayOrder == i){
          _newDays.add(_days[oldIdx]);

          
          oldIdx ++;
        }
        else{
          _newDays.add(null);
        }
      }
    }
    
    _days = _newDays;
    debugPrint(_days.toString());
    super.initState();
  }
  

  @override
  Widget build(BuildContext context) {
    debugPrint(_days.toString());


    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e2025),
        title: const Text(
          "Edit Schedule",
          style: TextStyle(
            fontWeight: FontWeight.w900,
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
            onAcceptWithDetails:(details) {
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
              });
              
            },

            builder: (context, candidateData, rejectedData) {
              final isActive = candidateData.isNotEmpty;
              if (_days[index] != null) {
                return _DraggableDay(days: _days, index: index);

              } else {
                return _RestDay(isActive: isActive, index: index);
              }
              // for draggable: 
              // child is initial state, before dragging
              // feedback is widget as it is dragged
              // child when dragging is what is displayed at anchor (origin) during dragging
              // data is data transmitted to dragtarget on drop (will be a day)
            },
          );
        }
        
      ),
    );
  }
}

class _RestDay extends StatelessWidget {
  const  _RestDay({
    //super.key,
    required this.isActive,
    required this.index,
  });

  final bool isActive;
  final int index;

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
        dashPattern: [15, 10],
        borderType: BorderType.RRect, // Rounded rectangle border
        radius: Radius.circular(8),
        
        color: isActive ? lighten(Color(0XFF1A78EB), 20) : lighten(const Color(0xFF1e2025), 20),
        
        
        child: Container(
        height: 50,
        width: double.infinity,
        
        decoration: BoxDecoration(
          color: isActive ? Color(0XFF1A78EB) : const Color(0xFF1e2025),
          borderRadius: BorderRadius.circular(8),
          //border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              decoration: BoxDecoration(
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
                     
                      daysOfWeek[index % 7],
                      style: TextStyle(
                        height: 1.0,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    Text(
                     
                      "${index + 1}",
                    
                      style: TextStyle(
                        height: 1.0,
                        fontSize: 14,
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
            )
          ],
        ),
      ),
      ),
    );
  }
}

class _DraggableDay extends StatelessWidget {
  const _DraggableDay({
    //super.key,
    required List<Day?> days,
    required int index,
  }) : _days = days, _index = index;

  final List<Day?> _days;
  final int _index;

  @override
  Widget build(BuildContext context) {
    return Draggable(
    data: _days[_index]!,
    
    feedback: Material(
      child: Container(
        height: 50,
        width: MediaQuery.sizeOf(context).width,
        color: Colors.red,
        child: Text(
          "Dragging",
          style: TextStyle(decoration: TextDecoration.none,)
          
        ),
      ),
    ),
    
    childWhenDragging: Container(
      height: 50,
      width: 100, 
      color: Colors.green,
      child: Text("Slot here")
    ),

    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
          height: 70,
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

                       
                        _RestDay.daysOfWeek[_index % 7],
                        style: TextStyle(
                          //color: darken(const Color(0xFF1e2025), 60),
                          height: 1.0,
                          fontSize: 24,
                          color: darken(Color(_days[_index]!.dayColor), 70),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
      
                      Text(
                       
                        "${_index + 1}",
                      
                        style: TextStyle(
                          height: 1.0,
                          fontSize: 20,
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
    );
  }
}
