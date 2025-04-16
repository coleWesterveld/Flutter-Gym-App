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
//TODO: fix error where clicking on one textfield then directly to another getrs rid of done button, unexpectedly

*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';                                 // For Slider
import 'package:flutter/services.dart';                                  // Haptics

// Utilities
import 'package:flutter_slidable/flutter_slidable.dart';                 // Swipe To Delete
import 'package:firstapp/database/database_helper.dart';                 // Database Helper
import 'package:firstapp/providers_and_settings/program_provider.dart';  // Access Program Details
import 'package:firstapp/other_utilities/days_between.dart';
import 'package:firstapp/other_utilities/lightness.dart';                // Lightening Colours
import 'package:firstapp/providers_and_settings/settings_provider.dart';

// Widgets
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:table_calendar/table_calendar.dart';                     // For Bottomsheet Calendar
import 'package:firstapp/program_page/custom_exercise_form.dart';        // Add An Exercise
import "package:firstapp/program_page/exercise_search.dart";             // Exercise Form - Migrating Away From
import 'package:firstapp/analytics_page/exercise_search.dart';           // New Exercise Search
import 'package:firstapp/program_page/programs_drawer.dart';
import 'package:firstapp/providers_and_settings/settings_page.dart';
import 'package:firstapp/program_page/list_exercises.dart';

// When editing a day, the user can edit either title or colour asociated
enum Viewer {title, color}

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
  int? _sliding = 0;

  DateTime startDay = DateTime(2024, 8, 10);

  TextEditingController customExerciseTEC = TextEditingController();
  TextEditingController alertTEC = TextEditingController();

  // Will saved index of a set that is currently being edited
  List<int> editIndex = [-1, -1, -1];

  // Single colour in colour picker to choose new colour for a day
  Widget pickerItemBuilder(Color color, bool isCurrentColor, void Function() changeColor) {
    
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: color,
        boxShadow: [BoxShadow(color: color.withAlpha((255 * 0.8).round()), offset: const Offset(1, 2), blurRadius: 0.0)],
      ),

      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: changeColor,
          borderRadius: BorderRadius.circular(8.0),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isCurrentColor ? 1 : 0,
            child: Icon(
              Icons.done,
              size: 36,
              color: widget.theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  // Layout of pop-up colour picker
  Widget pickerLayoutBuilder(BuildContext context, List<Color> colors, PickerItem child) {
    Orientation orientation = MediaQuery.of(context).orientation;

    return SizedBox(
      width: 300,
      height: orientation == Orientation.portrait ? 360 : 240,
      child: GridView.count(
        crossAxisCount: orientation == Orientation.portrait ?  5: 4,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        children: [for (Color color in colors) child(color)],
      ),
    );
  }

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
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
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
      
        //list of day cards
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
              child: listDays(context),
            ),
            SizedBox(height: 82),
          ],
        ),
        
      ),
    );
  }

  /////////////////////////////////////////////////////////////////////
  // LIST OF DAYS IN A SPLIT
  /////////////////////////////////////////////////////////////////////

  ReorderableListView listDays(BuildContext context) {
    return ReorderableListView.builder(
      //reordering days
        onReorder: (oldIndex, newIndex){
          if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
          setState(() {
            // if (newIndex > oldIndex) {
            //   newIndex -= 1;
            // }
            context.read<Profile>().moveDay(
              oldIndex: oldIndex, 
              newIndex: newIndex, 
              programID: context.read<Profile>().currentProgram.programID);
    
    
          });
        },
      
        //button at bottom to add a new day to split
        footer: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            key: ValueKey('dayAdder'),
          
            color: Color(0XFF1A78EB),
            child: InkWell(
            
              splashColor: Colors.deepOrange,
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
                setState(() {
                  context.read<Profile>().splitAppend();
                });
                
                //insertDay(context, 1, 'Day 1 - Upper Body');
                
              },
              child: SizedBox(
                width: double.infinity,
                height: 50.0,
                child: Icon(Icons.add),
              ),
            ),
          ),
        ),
            
        // building the rest of the tiles, one for each day from split list stored in user
        //dismissable and reorderable: each child for dismissable needs to have a unique key
        itemCount: context.watch<Profile>().split.length,
        itemBuilder: (context, index) {
          // todo: currently, some are slideable and some are dismissable. make all slideable
          // Undos currently caches then restores item, may want to switch to a soft delete first in DB as undo method? just an idea, for now im happy, it works.
          return Slidable(
            closeOnScroll: true,
            direction: Axis.horizontal,

            key: ValueKey(context.watch<Profile>().split[index]),
            // background: Container(
            //   color: Colors.red,
            //   child: Icon(Icons.delete)
            // ),
            endActionPane: ActionPane(
              extentRatio: 0.3,
              motion: const ScrollMotion(), 
              children: [SlidableAction(
                
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                onPressed: (direction) {
                  if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
                  final deletedDay = context.read<Profile>().split[index];
                  final deletedExercises = context.read<Profile>().exercises[index];
                  final deletedSets = context.read<Profile>().sets[index];
                  setState(() {
                    context.read<Profile>().splitPop(index: index);    
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        style: TextStyle(
                          color: Colors.white
                        ),
                        'Day Deleted'
                        ),
                        action: SnackBarAction(
                        label: 'Undo',
                        textColor: Colors.white,
                        onPressed: () {
                          try{
                          debugPrint("re-add: ${deletedDay.toString()}");

                          //setState(() {

                            
                            context.read<Profile>().splitInsert(
                              index: index, 
                              day: deletedDay, 
                              exerciseList: deletedExercises, 
                              newSets: deletedSets,
                            );
                          //});
                          } catch(e){
                            debugPrint('Undo failed: $e');
                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to undo deletion :(')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
            ),
              ],
            ),
            
            //outline for each day tile in the list
            child: Padding(
              key: ValueKey(context.watch<Profile>().split[index]),
              padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                        
              child: dayTile(context, index)
            ),  
          );
        },
    );
  }

  Container dayTile(BuildContext context, int index) {
    return Container(
              decoration: BoxDecoration(
                border: Border.all(color: lighten(Color(0xFF141414), 20)),
     
                color: Color(0xFF1e2025),
                borderRadius: BorderRadius.circular(12.0),
              ),
          
              //defining the inside of the actual box, display information
              child:  Center(
                child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      listTileTheme: ListTileThemeData(
                        contentPadding: EdgeInsets.only(left: 4, right: 16), // Removes extra padding
                      ),
                    ),
                  
                  //expandable to see exercises and sets for that day
                  child: ExpansionTile(
                  iconColor: Color(0XFF1A78EB),
                  collapsedIconColor: Color(0XFF1A78EB),
                  onExpansionChanged: (val){
                    if (!val){
                      WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
                      Provider.of<Profile>(context, listen: false).changeDone(false);
                    }
                  },
          
                  //top row always displays day title, and edit button
                  //sized boxes and padding is just a bunch of formatting stuff
                  //tbh it could probably be made more concise
                  //TODO: simplify this
                  title: 
                    SizedBox(
                      height: 40,
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 30,
                              width: 100,
                              child: 
                                Row(
                                  children: [
                                      
                                    //number
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        
                                        "${index + 1}",
                                            
                                        style: TextStyle(
                                            height: 0.6,
                                  
                                  color: Color(context.watch<Profile>().split[index].dayColor),
                                  fontSize: 50,
                                          fontWeight: FontWeight.w900,
                                        ),
                                            
                                      //day title
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left : 16.0),
                                      child: SizedBox(
                                        width: MediaQuery.sizeOf(context).width - 186,
                                        child: Text(
                                          overflow: TextOverflow.ellipsis,

                                          context.watch<Profile>().split[index].dayTitle,
                                          style: TextStyle(
                                            color: Color.fromARGB(255, 255, 255, 255),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                  ], 
                                ),
                              ),
                          ),
                            
                          //update title button
                          
                          IconButton(onPressed: () {
                              
                              //TODO: make a button to go between two screens, 
                              // default to changing title but when toggled to color can also change day color.
                              //TODO: color prefereces persistence
                              
                              showDialog(
                                anchorPoint: Offset(100, 100),
                                
                                context: context,
                                builder: (BuildContext context) {
                                  return StatefulBuilder(
                                    builder: (context, StateSetter setState) {
                                        return AlertDialog(
                                          //Padding: EdgeInsets.only(bottom: alertInsetValue),
                                          title: CupertinoSlidingSegmentedControl(
                                            padding: EdgeInsets.all(4.0),
                                            children: const <int, Text>{
                                              0: Text("Title"),
                                              1: Text("Color"),
                                            }, 
                                    
                                            onValueChanged: (int? newValue){
                                              _sliding = newValue;
                                    
                                              setState((){});
                                          
                                            },
                                            thumbColor: Colors.orange,
                                            groupValue: _sliding,
                                          ),
                                          content: editBuilder(index),
                                          actions: [
                                            IconButton(
                                            onPressed: (){
                                              if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
                                              String? dayTitle = alertTEC.text;
                                              if (dayTitle.isNotEmpty) {
                                              //rebuild widget tree reflecting new title
                                              setState( () {
                                                Provider.of<Profile>(context, listen: false).splitAssign(
                                                  index: index, 
                                                  newDay: context.read<Profile>().split[index].copyWith(newDayTitle: dayTitle),

                                                );
                                              });} //
                                              Navigator.of(context, rootNavigator: true).pop('dialog');
                                              _sliding = 0;
          
                                              
                                            },
                                            icon: Icon(Icons.check))
  ]
                                    
                                    );},
                                  );
                                },
                              );
                            
                              //widget.writePrefs();
                            },
          
                            icon: Icon(Icons.edit_outlined),
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                          
                    //children of expansion tile - what gets shown when user expands that day
                    // shows exercises for that day
                    //this part is viewed after tile is expanded
                    //TODO: show sets per exercise, notes, maybe most recent weight/reps
                    //exercises are reorderable
        
                    //TODO: get rid of little bit of color that somehow gets through at bottom
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:Color(0xFF1e2025),
                          borderRadius: BorderRadius.only(
                            
                            bottomRight: Radius.circular(12.0),
                            
                            bottomLeft: Radius.circular(12.0)),
                          ),
                        
                        
                        child: ListExercises(
                          editIndex: editIndex, 
                          widget: widget, 
                          context: context, 
                          index: index,
                          theme: widget.theme,

                          onExerciseAdded: () async {
                            setState(() {
                                _activeIndex = index;
                                _isEditing = true;
                              }
                            );
                          },

                          onSetAdded: (exerciseIndex) {
                            setState(() {
                              editIndex = [
                                index,
                                exerciseIndex, 
                                context.read<Profile>().sets[index][exerciseIndex].length
                              ];
                            });
                          },

                          onSetTapped: (exerciseIndex, setIndex) {
                            setState(() {
                              // Toggle between edit and display view
                              editIndex = [index, exerciseIndex, setIndex]; 
                            });
                          },

                          onSetSaved: () {
                            setState(() => editIndex = [-1, -1, -1]);
                          }
                        ),
                      ),
                    ]
                  ),
                ),
              ),
            );
  }


  //TODO: move to another file
  //this is to show text box to enter text for day titles and exercises
Future<dynamic> openDialog() {

  bool showCustomMaker = false;
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows the bottom sheet to adjust to content height
    showDragHandle: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(16),
      ),
    ),
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final mediaQuery = MediaQuery.of(context);
          final screenHeight = mediaQuery.size.height;
          final keyboardHeight = mediaQuery.viewInsets.bottom;
          final availableHeight = screenHeight - keyboardHeight;
          final maxHeight = availableHeight * 0.7; // Ensures some padding remains above

          //debugPrint(showCustomMaker.toString());

          if (showCustomMaker) {
            return Padding(
              padding: EdgeInsets.only(bottom: keyboardHeight),

              // here I could maybe add a toggle that will capitalize by default but can be turned off.
              // TODO: toggle ^ and potentially do checks if custom exercise is already in DB, then pop up "did you mean X?" for some similar exercise or something.
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
 // Print to the debug console
                      setModalState(() {
                        showCustomMaker = false; // Updates state inside modal
                      });
                      debugPrint(showCustomMaker.toString());
                    },
                    label: Icon(
                      Icons.arrow_back_ios_outlined,
                      color: Colors.blue,
                    )
                  ),
                  CustomExerciseForm(height: maxHeight - 48, exit: ()=> setState(() {
                    _isEditing=false;
                  })),
                ],
              ),
            );
          } else {
            return Padding(
              padding: EdgeInsets.only(bottom: keyboardHeight),
              child: SizedBox(
                height: maxHeight, // Prevents it from taking full height
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ExerciseDropdown(),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: lighten(Color(0xFF141414), 20)),
                        ),
                        color: Color(0xFF1e2025),
                      ),
                      height: 60,
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ButtonTheme(
                            minWidth: double.infinity,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                backgroundColor: WidgetStateProperty.all(Color(0xFF007aff)),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  showCustomMaker = true; // Updates state inside modal
                                });
                                debugPrint(showCustomMaker.toString());
                              },
                              child: Text(
                                'Add New Exercise',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        },
      );
    },
  );
}

// TODO: fix the done button. it has a wierd bar going over it, like it has too much height allocated
// also, it goes away when clicking directly from one textbox to another
  Widget? buildBottomSheet(){
    // if we should be displaying done button for numeric keyboard, then create.
    // else display calendar
  if (_isEditing) return null;
  if (context.read<Profile>().done){ 
    //return done bottom sheet
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
                setState((){});
              },

              child: Text(
                'Done',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      }else{
        // return calendary bottom sheet


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

  // TODO: keep this at the top of the screen, but not go off screen when keyboard comes up
  // its jarring when it bounces around
  Widget editBuilder(index){ 
          alertTEC = TextEditingController(text: context.watch<Profile>().split[index].dayTitle);
          

          // Ensure text is selected when the widget is built
          alertTEC.selection = TextSelection(
            baseOffset: 0,
            extentOffset: alertTEC.text.length,
          );

          if(_sliding == 0){
            //Value = MediaQuery.sizeOf(context).height - 450;
            return SizedBox(
              height: 100,
              width: 300,
              child: TextFormField(
                  
                  onFieldSubmitted: (value){
                    if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
                    Navigator.of(context).pop(alertTEC.text);
                  },
                  autofocus: true,
                  controller: alertTEC,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: alertTEC.clear,
                      icon: Icon(Icons.highlight_remove),
                    ),
                    
                    hintText: "Enter Text",
                  )
                ),
            );

          }else{
                return SizedBox(
                  height: 250,
                  width: 300,
                  child: SingleChildScrollView(
                    
                    child: BlockPicker(
                      pickerColor: Color(context.watch<Profile>().split[index].dayColor),
                      onColorChanged: (Color color) {
                        context.read<Profile>().splitAssign(
                          
                          index: index,
                          newDay: context.read<Profile>().split[index].copyWith(newDayColor: color.value),

                        );
                        setState(() {});
                      },
                        
                      
                      availableColors: Profile.colors,
                      layoutBuilder: pickerLayoutBuilder,
                      itemBuilder: pickerItemBuilder,
                    ),
                  ),
                );
          }
  }
}
