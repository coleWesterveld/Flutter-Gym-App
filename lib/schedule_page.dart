// schedule page
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'user.dart';

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
  

  const SchedulePage({Key? mykey}) : super(key: mykey);
  @override
  _MyScheduleState createState() => _MyScheduleState();
}

// this class contains the list view of expandable card tiles 
// title is day title (eg. 'legs') and when expanded, leg excercises for that day show up
class _MyScheduleState extends State<SchedulePage> {
  DateTime today = DateTime.now();
  Map<DateTime, List<Event>> events = {};
  DateTime startDay = DateTime(2024, 8, 10);

  // List<Color> pastelPalette = [
  //   Color.fromRGBO(150, 50, 50, 0.6), 
  //   Color.fromRGBO(199, 143, 74, 0.6), 
  //   Color.fromRGBO(220, 224, 85, 0.6),
  //   Color.fromRGBO(57, 129, 42, 0.6),
  //   Color.fromRGBO(61, 169, 179, 0.6),
  //   Color.fromRGBO(61, 101, 167, 0.6),
  //   Color.fromRGBO(106, 92, 185, 0.6), 
  //   Color.fromRGBO(131, 49, 131, 0.6),
  //   Color.fromRGBO(180, 180, 178, 0.6),
  //   ];
  @override
  // main scaffold, putting it all together
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          showDialog(context: context, builder: (context){
            return const AlertDialog(
              scrollable: true,
              
            );
          });
        },
        child: const Icon(Icons.add)
      ),

      

      //bottomNavigationBar: weekView(),
      body: Padding(
        padding: const EdgeInsets.only(top: 60.0),
        child: Column(
          children: [
            const Text("schedule WIP"),
            Container(
              child: TableCalendar(
                
                calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                  DateTime origin = DateTime(2024, 1, 7);
                  for (var splitDay = 0; splitDay < context.watch<Profile>().split.length; splitDay ++){

                  
                    if (daysBetween(origin , day) % context.watch<Profile>().splitLength == (context.watch<Profile>().splitLength ~/ context.watch<Profile>().split.length) * splitDay) {
                      return Container(
                        decoration: BoxDecoration(
                          color: context.watch<Profile>().split[splitDay].dayColor,
                          borderRadius: const BorderRadius.all(
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