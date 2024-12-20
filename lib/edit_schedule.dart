import 'package:flutter/material.dart';
import 'user.dart';
import 'database/profile.dart';
import 'package:provider/provider.dart';

// TODO: first things first, this needs to work as intended
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
  

  @override
  Widget build(BuildContext context) {
    List<Day?> _days = context.watch<Profile>().split;
    debugPrint(_days.toString());


    List<Day?> _newDays = [];

    int oldIdx = 0;
    if (_days.isNotEmpty){
      for (int i = 0; i <= context.watch<Profile>().splitLength; i++){
        if (oldIdx < _days.length &&_days[oldIdx]!.dayOrder == i){
          _newDays.add(_days[oldIdx]);

          
          oldIdx ++;
        }
        else{
          _newDays.add(null);
        }
      }
    }
    debugPrint(_newDays.toString());
    _days = _newDays;

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
      Column(
        children: _days.asMap().entries.map((entry) {
          final index = entry.key;
          final content = entry.value;

          return DragTarget<Day>(

            onAcceptWithDetails: (incoming) {
              setState(() {
                final oldIndex = _days.indexOf(incoming.data);
                final targetContent = _days[index];

                if (targetContent == null) {
                  // If the slot is empty, just move the day
                  _days[oldIndex] = null;
                  _days[index] = incoming.data;
                } else {
                  // Push the existing day to the next available slot
                  final nextIndex = _days.indexWhere((slot) => slot == null);
                  if (nextIndex != -1) {
                    _days[oldIndex] = null;
                    _days[nextIndex] = targetContent;
                    _days[index] = incoming.data;
                  } else {
                    // No available slot; reject the move
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No available slot to move the existing day.")),
                    );
                  }
                }
              });
            },

            builder: (context, candidateData, rejectedData) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: content != null
                    ? Draggable<Day>(
                        data: content,
                        feedback: Material(
                          color: Colors.transparent,
                          child: _buildDayWidget(content),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.5,
                          child: _buildDayWidget(content),
                        ),
                        child: _buildDayWidget(content),
                      )
                    : _buildRestDayWidget(index),
              );
            },
          );
        }).toList(),
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
