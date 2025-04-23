// schedule page
//not updated
//import 'dart:ffi';

// TODO: these indicators are not very clear, i need to make the design more intuitive
// ie. what days have passed, what indicates today vs. indicates selected day

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers_and_settings/program_provider.dart';
import '../database/profile.dart';
import 'edit_schedule.dart';
import '../other_utilities/days_between.dart';
import '../other_utilities/lightness.dart';
import '../providers_and_settings/settings_page.dart';
import 'package:firstapp/other_utilities/events.dart';

class SchedulePage extends StatefulWidget {
  final ThemeData theme;

  const SchedulePage({
    Key? mykey,
    required this.theme,
  }) : super(key: mykey);
  @override
  _MyScheduleState createState() => _MyScheduleState();
}

// this class contains the list view of expandable card tiles 
// title is day title (eg. 'legs') and when expanded, leg exercises for that day show up
class _MyScheduleState extends State<SchedulePage> {
  DateTime today = DateTime.now();
  Map<DateTime, List<Event>> events = {};

  // this becomes origin from profile class in initializer
  // origin is some day of this week, specified by user
  // this may need to be changed for longer startdays and saved in database
  DateTime startDay = DateTime.now();

  DateTime? _selectedDay;
  late ValueNotifier<List<Event>> _selectedEvents;



  @override
  void initState(){
    
    super.initState();
    _selectedDay = today;
    _selectedEvents = ValueNotifier(getEventsForDay(day: _selectedDay!, context: context));
    //loadEvents();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay){
    if (!isSameDay(_selectedDay, selectedDay)){
      setState((){
        _selectedDay = selectedDay;
        //today = focusedDay;
        _selectedEvents.value = getEventsForDay(day: selectedDay, context: context);
      });
      
    }
  }

  Widget buildLegend(){
    int crossCount = 2;
    int numLabels = context.watch<Profile>().split.length;
    
    Orientation orientation = MediaQuery.of(context).orientation;
    return SizedBox(
      //color: Colors.red,
      width: double.infinity,
      height: orientation == Orientation.portrait ? 34*(numLabels / crossCount).ceilToDouble() : 50,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: orientation == Orientation.portrait ?  crossCount: 1,
        //crossAxisSpacing: 5,
        //mainAxisSpacing: 5,
        childAspectRatio: 6,
        children: legendLabels(),
      ),
    );
  }

  List<Widget> legendLabels(){
    List<Widget> labels = [];
    for (Day day in context.watch<Profile>().split){
      labels.add(
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: SizedBox(
            height: 20,
            child: Row(
            children: [
              Container(
                width: 15,
                height: 15, 
                decoration: BoxDecoration(
                  color: Color(day.dayColor),
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(child: Text(" ${day.dayTitle}",overflow: TextOverflow.ellipsis,)),
            ],
            ),
          ),
        )
        );

      //labels.add(label);
    }
    return labels;
  }

    @override
  void dispose() {
    _selectedEvents.dispose(); // Dispose the ValueNotifier to avoid memory leaks
    super.dispose();
  }

  BoxDecoration _buildToday(){
    final events = getEventsForDay(day: today, context: context);
    if (events.isNotEmpty){
      return BoxDecoration(
        border: Border.all(color: widget.theme.colorScheme.onSurface, width: 3),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        color: darken(Color(context.watch<Profile>().split[events[0].index].dayColor),20), 
        shape: BoxShape.rectangle, 
      );
    }

    return  BoxDecoration(
        color:  darken(const Color(0xFF1e2025), 20),
        border: Border.all(color: widget.theme.colorScheme.onSurface, width: 3),
        borderRadius:  const BorderRadius.all(Radius.circular(14)),
        shape: BoxShape.rectangle, 
      );
    
    
  }

  BoxDecoration _buildSelected(){
    final events = getEventsForDay(day: _selectedDay!, context: context);
    if (events.isNotEmpty){
      return BoxDecoration(
        border: Border.all(color: widget.theme.colorScheme.surface, width: 3),
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        color: lighten(Color(context.watch<Profile>().split[events[0].index].dayColor),20), 
        shape: BoxShape.rectangle, 
      );
    }

    return  BoxDecoration(
        color:  widget.theme.colorScheme.outline,
        border: Border.all(color: widget.theme.colorScheme.surface, width: 1),        borderRadius:  const BorderRadius.all(Radius.circular(14)),
        shape: BoxShape.rectangle, 
      );
    
    
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedEvents.value = getEventsForDay(day: _selectedDay!, context: context);
  }

  @override
  
  // main scaffold, putting it all together
  Widget build(BuildContext context) {

    if (!context.watch<Profile>().isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    startDay = context.watch<Profile>().origin;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.theme.colorScheme.surface,
        centerTitle: true,
        title: const Text(
          "Planner",
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),

        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ]
      ),
 
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: TextButton(
                  onPressed: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditSchedule(
                              theme: widget.theme
                            ),
                      )
                    );
                  }, 
                  child: const Text("Edit Schedule")),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 14, left: 14, right: 14),
              child: Container(
                
                decoration: BoxDecoration(
                  
                  color: widget.theme.colorScheme.surface,
                  //border: Border
                  borderRadius: BorderRadius.circular(12),

                  boxShadow: [
                    BoxShadow(
                      blurRadius: 5,
                      offset: const Offset(0, 0),
                      spreadRadius: 2,
                      color: widget.theme.colorScheme.shadow.withAlpha((0.3*255).round())

                    )
                  ]
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
        
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                      child: Container(
                        child: TableCalendar(


//TODO: add button in header to take user back to today
                          // limit to only monthview
                          availableCalendarFormats: const {
                            CalendarFormat.month: 'Month',
                          },

                          // will return true if seected day is same as day, will highlight day as selected
                          selectedDayPredicate: (day) {
                            return _selectedDay!.year == day.year &&
                              _selectedDay!.month == day.month &&
                              _selectedDay!.day == day.day;
                          },

                          // manage when a day gets tapped
                          onDaySelected: _onDaySelected,

                          // given a day, load its events
                          eventLoader: (day){
                            return getEventsForDay(day: day, context: context);
                          },
                          
                          
                          // build by day
                          
                          calendarBuilders: CalendarBuilders(
                          outsideBuilder: (context, day, focusedDay) {
                            var events = getEventsForDay(day: day, context: context);
                          
                            //DateTime origin = DateTime(2024, 1, 7);
                            
                            if (events.isNotEmpty){
                              return  Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: today.isBefore(day) ? 
                                      Color(context.watch<Profile>().split[events[0].index].dayColor): 
                                      darken(Color(context.watch<Profile>().split[events[0].index].dayColor), 40),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(16.0),
                                    ),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(color: widget.theme.colorScheme.onSurface),
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                          
                            return null;
                          },




                          defaultBuilder: (context, day, focusedDay) {
                            var events = getEventsForDay(day: day, context: context);
                          
                            //DateTime origin = DateTime(2024, 1, 7);
                            
                            if (events.isNotEmpty){
                              return  Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: today.isBefore(day) ? 
                                      Color(context.watch<Profile>().split[events[0].index].dayColor): 
                                      darken(Color(context.watch<Profile>().split[events[0].index].dayColor), 40),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(16.0),
                                    ),
                                    shape: BoxShape.rectangle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(color: widget.theme.colorScheme.onPrimary),
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            return null;
                          },
                          ),
                          rowHeight: 70,
                          focusedDay: _selectedDay!, 
                          firstDay: DateTime.utc(2010, 10, 16), 
                          lastDay: DateTime.utc(2030, 3, 14),
                          calendarStyle: CalendarStyle(
                            markerDecoration: const BoxDecoration(),
                            defaultDecoration: BoxDecoration(
                              //color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              shape: BoxShape.rectangle,
                            ),
                            
                            
                            selectedDecoration: _buildSelected(),
                            todayDecoration: _buildToday(),

                            // the days default to circle shape, and this throws errors on animating selection (even after chaning default)
                            // idk a better way to do this, but this works, even if its maybe not elegant
                            rangeEndDecoration: BoxDecoration(
                              //color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              shape: BoxShape.rectangle,
                            ),
                            weekendDecoration: BoxDecoration(
                              //color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              shape: BoxShape.rectangle,
                            ),
                            outsideDecoration: BoxDecoration(
                              //color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              shape: BoxShape.rectangle,
                            ),

                            selectedTextStyle: TextStyle(
                              color: widget.theme.colorScheme.onPrimary, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    buildLegend(),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents, 
              builder: (context, value, _){
                if (value.isNotEmpty){
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        
                        //border: Border.all(color: const Color(0xFF1e2025)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 5,
                              offset: const Offset(0, 0),
                              spreadRadius: 2,
                              color: widget.theme.colorScheme.shadow.withAlpha((0.3*255).round())

                            )
                          ]
                        ),
                        child: ListTile(
                          //tileColor: const Color.fromARGB(255, 43, 43, 43),            //onTap: () => print(""),
                          title: Text(value[0].title)
                        ),
                      
                      ),
                    );
                  }else{
                    return const SizedBox(height: 0);
                  }
                
              }
            )
          ],
        ),),

      
    );
  }
}