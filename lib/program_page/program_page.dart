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
import 'package:firstapp/widgets/list_days.dart';
import 'package:firstapp/providers_and_settings/ui_state_provider.dart';

class ProgramPage extends StatefulWidget {

  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  
  ProgramPage({
    Key? programkey, 
    }) : super(key: programkey);
  @override
  ProgramPageState createState() => ProgramPageState();
}

class ProgramPageState extends State<ProgramPage> {
  // This is required for snackbar undo delete to work even when user navigates away

  DateTime today = DateTime.now();

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
  }

  // Search mode callback - is choosing exercise or not
  void _updateSearchMode(bool isEditing, BuildContext context) {
    final uiState = context.read<UiStateProvider>();
    uiState.isChoosingExercise = isEditing;
  }



  @override
  Widget build(BuildContext context) {
    final uiState = context.read<UiStateProvider>();
    ThemeData theme = Theme.of(context);

    if (!context.watch<Profile>().isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Allow user to tap outside of any box to unfocus
    return GestureDetector(
      onTap: (){
        WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
        Provider.of<Profile>(context, listen: false).changeDone(false);
      },

      child: uiState.isChoosingExercise ? Stack(
          children: [
            ExerciseSearchWidget(
              theme: theme,
              onExerciseSelected: (exercise) {
                _handleExerciseSelected(context, exercise, _activeIndex!);
              },
              onSearchModeChanged: (isEditing){
                return _updateSearchMode(isEditing, context);
              },
            ),
          ]
        ): Column(
          children: [
            Expanded(
              child: ListDays(
                  
                  theme: theme, 
                  context: context,
                
                  onExerciseAdded: (index) {
                    setState(() {
                      _activeIndex = index;
                      uiState.isChoosingExercise = true;
                    });
                  },
                
                ),
            ),
            
            const SizedBox(height: 82.5),
          ],
        ),
        
      
    );
  }


}
