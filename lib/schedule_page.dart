// schedule page
//not updated
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
  DateTime? _selectedDay;
  late final ValueNotifier<List<Event>> _selectedEvents;

  void loadEvents(){
    //
  }

  @override
  void initState(){
    super.initState();
    _selectedDay = today;
    //_selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    //loadEvents();
  }

  List<Event> _getEventsForDay (DateTime day){
    for (var splitDay = 0; splitDay < context.read<Profile>().split.length; splitDay ++){
      if (daysBetween(startDay , day) % context.read<Profile>().splitLength == (context.read<Profile>().splitLength ~/ context.read<Profile>().split.length) * splitDay) {
        return [Event(context.read<Profile>().split[splitDay].data)];
      }
    }
    return [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay){
    if (!isSameDay(_selectedDay, selectedDay)){
      setState((){
        _selectedDay = selectedDay;
        today = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
      
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safe to access context.watch<Profile>() here
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    loadEvents(); // You can call loadEvents() here as well, if needed
  }

  @override
  // main scaffold, putting it all together
  Widget build(BuildContext context) {

    

    return Scaffold(
      appBar: AppBar(
        //backgroundColor: const Color(0xFF643f00),
        centerTitle: true,
        title: const Text(
          "Planner",
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
          ),
      ),
 

      

      //bottomNavigationBar: weekView(),
      body: Container(
        //color: const Color(0xFF180c12),
        // decoration: const BoxDecoration( 
          
        //     // Image set to background of the body
        //     image: DecorationImage( 
        //         image: AssetImage("darkbg.png"), fit: BoxFit.cover),
        //   ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Container(
                
                decoration: BoxDecoration(
                  
                  color: const Color(0xFF2b2b2b),
                  //border: Border
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TableCalendar(
                    selectedDayPredicate: (day) {
                      return _selectedDay!.year == day.year &&
                      _selectedDay!.month == day.month &&
                      _selectedDay!.day == day.day;
                    },
                    onDaySelected: _onDaySelected,
                    eventLoader: _getEventsForDay,
                    
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
                    focusedDay: _selectedDay!, 
                    firstDay: DateTime.utc(2010, 10, 16), 
                    lastDay: DateTime.utc(2030, 3, 14)
                  ),
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<List<Event>>(
                valueListenable: _selectedEvents, 
                builder: (context, value, _){
                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index){
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12, 
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2b2b2b),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              //color: context.watch<Profile>().split[index].dayColor,
                            
                          ),),
                          child: ListTile(
                            //tileColor: const Color.fromARGB(255, 43, 43, 43),            //onTap: () => print(""),
                            title: Text(value[index].title)
                          ),
                        
                        ),
                      );
                    },
                  );
                }
              ),
            )
          ],
        ),
      ),

      
    );
  }
}