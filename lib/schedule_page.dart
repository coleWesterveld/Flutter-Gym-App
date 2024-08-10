// schedule page
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Event{
  final String title;
  Event(this.title);
}


  
class SchedulePage extends StatefulWidget {
  @override
  _MyScheduleState createState() => _MyScheduleState();
}

// this class contains the list view of expandable card tiles 
// title is day title (eg. 'legs') and when expanded, leg excercises for that day show up
class _MyScheduleState extends State<SchedulePage> {
  DateTime today = DateTime.now();
  Map<DateTime, List<Event>> events = {};
  @override
  // main scaffold, putting it all together
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          showDialog(context: context, builder: (context){
            return AlertDialog(
              scrollable: true,
              
            );
          });
        },
        child: const Icon(Icons.add)
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 60.0),
        child: Column(
          children: [
            Text("hioya there"),
            Container(
              child: TableCalendar(
                rowHeight: 90,
                focusedDay: today, 
                firstDay: DateTime.utc(2010, 10, 16), 
                lastDay: DateTime.utc(2030, 3, 14)
              ),
            ),
          ],
        ),
      ),
    );
  }
}