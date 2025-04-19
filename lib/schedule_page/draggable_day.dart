import 'package:dotted_border/dotted_border.dart';
import 'package:firstapp/widgets/done_button.dart';
//import 'package:firstapp/schedule_page.dart';
import 'package:flutter/material.dart';
import '../providers_and_settings/program_provider.dart';
import '../database/profile.dart';
import 'package:provider/provider.dart';
import '../other_utilities/lightness.dart';
import '../other_utilities/day_of_week.dart';
import '../providers_and_settings/settings_page.dart';
import 'package:firstapp/schedule_page/rest_day.dart';


class DraggableDay extends StatelessWidget {
  // this widget isnt exactly following DRY, could use refactor
  const DraggableDay({super.key, 
    //super.key,
    required List<Day?> days,
    required int index,
    required int startDay,
    required this.theme

  }) : 
  _days = days, 
  _index = index,
  _startDay = startDay;

  final List<Day?> _days;
  final int _index;
  final int _startDay;
  final ThemeData theme;

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
          
                borderRadius: BorderRadius.circular(12),
                //border: Border.all(color: Colors.white, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8.0),
                        topLeft: Radius.circular(8.0),
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
          
                           
                            RestDay.daysOfWeek[(_index + _startDay) % 7],
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
          height: 60,
          width: double.infinity,
          
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.surface,
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

                       
                        RestDay.daysOfWeek[(_index + _startDay) % 7],
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
              color: theme.colorScheme.outline,
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

                       
                        RestDay.daysOfWeek[(_index + _startDay) % 7],
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
