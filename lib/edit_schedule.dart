import 'package:flutter/material.dart';
import 'user.dart';
import 'database/profile.dart';
import 'package:provider/provider.dart';

// TODO: make pretty

// but also it needs to allow user to customize splitlength and choose day of week to start split
// also, like much of the code, could probably use a refactor at the end of it all



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
                return Draggable(
                data: _days[index]!,
                child: Container(
                  height: 50,
                  width: 100,
                  color: Profile.colors[index % Profile.colors.length], // temporary
                  child: Text(_days[index]!.dayTitle)
                ),

                feedback: Material(
                  child: Container(
                    height: 50,
                    width: 100,
                    color: Colors.red,
                    child: Text(
                      "Dragging",
                      style: TextStyle(decoration: TextDecoration.none,)
                      
                    ),
                  ),
                ),

                childWhenDragging: Container(
                  child: Container(
                    height: 50,
                    width: 100, 
                    color: Colors.green,
                    child: Text("Slot here")
                  )
                ),
                );

              } else {
                return Container(
                height: 50,
                width: 100,
                
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue : Colors.grey,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text("Rest Day")
              );
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

  Widget _buildDayWidget(Day content) {
    return Container(
      key: ValueKey(content),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Text(
          content.dayTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRestDayWidget(int index) {
    return Container(
      key: ValueKey("rest-$index"),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: const Center(
        child: Text(
          "Rest Day",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
