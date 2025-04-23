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

// Widgets
import 'package:firstapp/widgets/exercise_search.dart';           // New Exercise Search
import 'package:firstapp/widgets/programs_drawer.dart';
import 'package:firstapp/providers_and_settings/settings_page.dart';
import 'package:firstapp/widgets/list_days.dart';
import 'package:firstapp/widgets/done_button.dart';
import 'package:firstapp/widgets/calendar_bottom_sheet.dart';

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
  
  // Add exercise to a day
  void _handleExerciseSelected(BuildContext context, Map<String, dynamic> exercise, int index) {
    setState(() {
      _exerciseID = exercise['exercise_id'];
    });

    if (_exerciseID == null) return;

    context.read<Profile>().exerciseAppend(
      index: index,
      exerciseId: _exerciseID!,
    );

    ("ExerciseID: $_exerciseID");
  }

  // Search mode callback - is choosing exercise or not
  void _updateSearchMode(bool isEditing) {
    setState(() {
      _isEditing = isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<Profile>().isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

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
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
        ),

        actions: [
          // More Actions - currently implementing multi-phase programs
          // PopupMenuButton<String>(            
          //   icon: const Icon(Icons.more_horiz, size: 28),
          //   itemBuilder: (context) => [
          //     const PopupMenuItem(
          //       value: 'phaseAdder',
          //       child: ListTile(
          //         leading: Icon(Icons.add),
          //         title: Text('Make Multi-Phase'),
          //       ),
          //     ),
          //   ],
          //   onSelected: (value) {
          //     if (value == 'phaseAdder'){
          //       (value);
          //       // set program to multiphase
          //       // we will have to change the DB schema for this
          //       // whole lotta changes... 
          //     }
          //   },
          // ),

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
          ("New: $selectedProgram");
          context.read<Profile>().updateProgram(selectedProgram);
        },

        theme: widget.theme,
      ),
      
      // Bottom Calendar Sheet
      bottomSheet: buildBottomSheet(),
      
      // List of day cards
      body: _isEditing ? Stack(
          children: [
            ExerciseSearchWidget(
              theme: widget.theme,
              onExerciseSelected: (exercise) {
                _handleExerciseSelected(context, exercise, _activeIndex!);
              },
              onSearchModeChanged: _updateSearchMode,
            ),
          ]
        ): Column(
          children: [
            Expanded(
              child: ListDays(
                theme: widget.theme, 
                context: context,

                onExerciseAdded: (index) {
                  setState(() {
                    _activeIndex = index;
                    _isEditing = true;
                  });
                },

              ),
            ),
            const SizedBox(height: 82),
          ],
        ),
        
      ),
    );
  }

  Widget? buildBottomSheet(){
    // If we should be displaying done button for numeric keyboard, then create.
    // Else display calendar
    if (_isEditing) return null;

    if (context.read<Profile>().done){ 
      return DoneButtonBottom(
        context: context,
        theme: widget.theme,
      );
    }else{
      return CalendarBottomSheet(
        today: today,
        theme: widget.theme
      );
    }
  }  
}
