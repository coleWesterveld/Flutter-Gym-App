// ignore_for_file: prefer_const_constructors
// TODO: this shoudl come back just for now it was everywhere and annoying

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
import 'package:firstapp/schedule_page/draggable_day.dart';

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

class EditSchedule extends StatefulWidget {
  const EditSchedule({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

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
    //(_days.toString());
    super.initState();
  }

  void generateDays(){
    List<Day?> newDays = [];
    _days = context.read<Profile>().split;
    //(_days.toString());

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

    if (!context.watch<Profile>().isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(

      onTap: (){
            WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
            Provider.of<Profile>(context, listen: false).changeDone(false);
        },

      child: Scaffold(
      
        bottomSheet: buildBottomSheet(),
      
        appBar: AppBar(
          backgroundColor: widget.theme.colorScheme.surface,
          title: const Text(
            "Edit Schedule",
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
          ],
      
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
                      color: widget.theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),

                      boxShadow: [
                        BoxShadow(
                          blurRadius: 5,
                          offset: const Offset(0, 0),
                          spreadRadius: 2,
                          color: widget.theme.colorScheme.shadow.withAlpha((0.3*255).round())
                        )
                      ]

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
                                      //("no");
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
                                                                        
                                  //controller: context.watch<Profile>().rpeTEC[index][exerciseIndex][setIndex],
                                  
                                  keyboardType: TextInputType. numberWithOptions(decimal: true),
                                                                      
                                  decoration:  InputDecoration(
                                    //filled: true,
                                    //fillColor: Color(0xFF1e2025),
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
                      color: widget.theme.colorScheme.surfaceContainerHighest,

                      borderRadius: BorderRadius.circular(8),

                      boxShadow: [
                        BoxShadow(
                          blurRadius: 5,
                          offset: const Offset(0, 0),
                          spreadRadius: 2,
                          color: widget.theme.colorScheme.shadow.withAlpha((0.3*255).round())
                        )
                      ]
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
                //color: ,
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
                //(context.read<Profile>().origin.toString());
              },
        
              builder: (context, candidateData, rejectedData) {
                final isActive = candidateData.isNotEmpty;
                if (_days[index] != null) {
                  return DraggableDay(
                    days: _days, 
                    index: index, 
                    startDay: startDay,
                    theme: widget.theme
                  );
        
                } else {
                  return RestDay(
                    isActive: isActive, 
                    index: index, 
                    startDay: startDay,
                    theme: widget.theme
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
          
        )
      ),
    );
  }

  Widget? buildBottomSheet(){
    // if we should be displaying done button for numeric keyboard, then create.
    if (context.read<Profile>().done){ 
      //return done bottom sheet
      return DoneButtonBottom(
        context: context, 
        theme: widget.theme
      );
    }else{
        return null;
      }
    }
}
