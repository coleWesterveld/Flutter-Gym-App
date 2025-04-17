// Program Page
// Here, user will define a workout program that they can follow
// Defines days, exercises, rep ranges, intensity, etc.

/*
Still Todo on this page:
- since only one set can be editing at a time, we dont need a list of Text editing controllers - we just need one for each field
- ability to add notes per exercise
- fix double digit days - they dont show up well
- LATER: add sidebar, user can have multiple different programs to swap between
- make a max of all user input fields - make them as long as possible but stop them from being absurd
- after search, it should put the user back at the opened expansiontile (it should not revert to being closed)
- convert exercise form to new form
- move some widgets like exercise search into a widgets folder maybe
- added exercises should show up right away and at top
- test undo even on different pages
- modifiable start date
- muilti phase programs
- idk if I need to crazy callbacks for like onSet___ -> I think editIndex could just be local
    - then again, it is needed I think if we want only one at a time open
//TODO: fix error where clicking on one textfield then directly to another getrs rid of done button, unexpectedly
// TODO: fix the done button. it has a wierd bar going over it, like it has too much height allocated
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Utilities
import 'package:firstapp/database/database_helper.dart';                 // Database Helper
import 'package:firstapp/providers_and_settings/program_provider.dart';  // Access Program Details
import 'package:firstapp/other_utilities/days_between.dart';
import 'package:firstapp/other_utilities/lightness.dart';                // Lightening Colours
import 'package:firstapp/providers_and_settings/settings_provider.dart';

// Widgets
import 'package:table_calendar/table_calendar.dart';                     // For Bottomsheet Calendar
import 'package:firstapp/program_page/custom_exercise_form.dart';        // Add An Exercise
import "package:firstapp/program_page/exercise_search.dart";             // Exercise Form - Migrating Away From
import 'package:firstapp/analytics_page/exercise_search.dart';           // New Exercise Search
import 'package:firstapp/program_page/programs_drawer.dart';
import 'package:firstapp/providers_and_settings/settings_page.dart';
import 'package:firstapp/program_page/list_days.dart';

class ProgramPage extends StatefulWidget {

  final DatabaseHelper dbHelper;
  final ThemeData theme;
  
  const ProgramPage({
    Key? programkey, 
    required this.dbHelper,
    required this.theme
    }) : super(key: programkey);
  @override
  ProgramPageState createState() => ProgramPageState();
}

class ProgramPageState extends State<ProgramPage> {
  // This is required for snackbar undo delete to work even when user navigates away
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey();

  DateTime today = DateTime.now();

  bool _isEditing = false;

  int? _exerciseID;
  int? _activeIndex;

  DateTime startDay = DateTime(2024, 8, 10);

  TextEditingController customExerciseTEC = TextEditingController();
  TextEditingController alertTEC = TextEditingController();

  // Will saved index of a set that is currently being edited
  List<int> editIndex = [-1, -1, -1];

  // Single colour in colour picker to choose new colour for a day
  
  // Add exercise to a day
  void _handleExerciseSelected(BuildContext context, Map<String, dynamic> exercise, int index) {
    debugPrint("Adding $exercise to $index ");
    setState(() {
      _exerciseID = exercise['exercise_id'];
    });

    if (_exerciseID == null) return;

    context.read<Profile>().exerciseAppend(
      index: index,
      exerciseId: _exerciseID!,
    );

    debugPrint("ExerciseID: $_exerciseID");
  }

  // Search mode callback - is choosing exercise or not
  void _updateSearchMode(bool isEditing) {
    setState(() {
      _isEditing = isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Allow user to tap outside of any box to unfocus
    return GestureDetector(
      onTap: (){
        WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
        Provider.of<Profile>(context, listen: false).changeDone(false);
      },

      child: Scaffold(
        // required for snackbars to work after navigating away
        key: scaffoldMessengerKey, 

        resizeToAvoidBottomInset: true,

        appBar: AppBar(
          centerTitle: true,
          title: Text(
            context.watch<Profile>().currentProgram.programTitle,
          ),

          // Open Drawer to see/select/edit programs
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
        ),

        actions: [
          // More Actions - currently implementing multi-phase programs
          PopupMenuButton<String>(            
            icon: const Icon(Icons.more_horiz, size: 28),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'phaseAdder',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Make Multi-Phase'),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'phaseAdder'){
                debugPrint(value);
                // set program to multiphase
                // we will have to change the DB schema for this
                // whole lotta changes... 
              }
            },
          ),

          // Takes to settings page
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),

      // Program edit/select side drawer
      drawer: ProgramsDrawer(
        currentProgramId: context.read<Profile>().currentProgram.programID,
        onProgramSelected: (selectedProgram) {
          debugPrint("New: $selectedProgram");
          context.read<Profile>().updateProgram(selectedProgram);
        },
      ),
      
      // Bottom Calendar Sheet
      bottomSheet: buildBottomSheet(),
      
      // List of day cards
      body: _isEditing ? Stack(
          children: [ExerciseSearchWidget(
            onExerciseSelected: (exercise) {
              _handleExerciseSelected(context, exercise, _activeIndex!);
            },
            onSearchModeChanged: _updateSearchMode,
          ),]
        ): Column(
          children: [
            Expanded(
              child: ListDays(
                editIndex: editIndex, 
                theme: widget.theme, 
                context: context,

                onExerciseAdded: (index) {
                  setState(() {
                    _activeIndex = index;
                    _isEditing = true;
                  });
                },

                onSetAdded: (index, exerciseIndex) {
                  setState(() {
                    editIndex = [
                      index,
                      exerciseIndex, 
                      context.read<Profile>().sets[index][exerciseIndex].length
                    ];
                  });
                },

                onSetTapped:(index, exerciseIndex, setIndex) {
                  setState(() {
                    // Toggle between edit and display view
                    editIndex = [index, exerciseIndex, setIndex]; 
                  });
                },

                onSetSaved: () => setState(() => editIndex = [-1, -1, -1]),

              ),
            ),
            const SizedBox(height: 82),
          ],
        ),
        
      ),
    );
  }

  Widget? buildBottomSheet(){
    // if we should be displaying done button for numeric keyboard, then create.
    // else display calendar
    if (_isEditing) return null;

    if (context.read<Profile>().done){ 
      //return done bottom sheet
      return DoneButtonBottom(context: context);
    }else{
      return CalendarBottomSheet(today: today);
    }
  }  
}


class CalendarBottomSheet extends StatelessWidget {
  const CalendarBottomSheet({
    super.key,
    required this.today,
  });

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF1e2025),
      padding: const EdgeInsets.all(8.0),
      height: 82,
      child: TableCalendar(
        headerVisible: false,
        calendarFormat: CalendarFormat.week,
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            DateTime origin = DateTime(2024, 1, 7);
    
            for (int splitDay = 0; splitDay < context.watch<Profile>().split.length; splitDay ++){
              int diff = daysBetween(origin , day) % context.watch<Profile>().splitLength;
              if (diff == (context.watch<Profile>().splitLength ~/ context.watch<Profile>().split.length) * splitDay) {
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(context.watch<Profile>().split[splitDay].dayColor),
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
                  ),
                );
              }
            }
            
            return null;
          },
        ),
    
        rowHeight: 50,
        focusedDay: today, 
        firstDay: DateTime.utc(2010, 10, 16), 
        lastDay: DateTime.utc(2030, 3, 14),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white), // Color for weekdays (Mon-Fri)
            weekendStyle: TextStyle(color: Colors.white),   // Color for weekends (Sat-Sun)
      ),
    ),
                );
  }
}

class DoneButtonBottom extends StatelessWidget {
  const DoneButtonBottom({
    super.key,
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
    
        border: Border(
          top: BorderSide(
            color:  lighten(Color(0xFF141414), 20),
          ),
        ),
        
        color: Color(0xFF1e2025),
          //borderRadius: BorderRadius.circular(12.0),
        ),
    
        height: 50,
        width: double.infinity,
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ButtonStyle(
                //when clicked, it splashes a lighter purple to show that button was clicked
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)
                  ),
                ),
                backgroundColor: WidgetStateProperty.all(Color(0xFF6c6e6e),),
              ),
                
              onPressed: () {
                WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
                context.read<Profile>().done = false;
                //setState((){});
              },
    
              child: Text(
                'Done',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
  }
}
