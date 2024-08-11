// schedule page
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class Event{
  final String title;
  Event(this.title);
}

int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
   return (to.difference(from).inHours / 24).round();
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
  final List<DateTime> toHighlight = [DateTime(2024, 8, 20)];
  DateTime startDay = DateTime(2024, 8, 10);
  
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
            Text("schedule WIP"),
            Container(
              child: TableCalendar(
                calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                
                  if (daysBetween(startDay, day) % 7 ==0) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.lightGreen,
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
                
                return null;
              },
            ),
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