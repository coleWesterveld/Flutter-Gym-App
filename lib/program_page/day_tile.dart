// A single day in the program page

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:firstapp/providers_and_settings/program_provider.dart';  // Access Program Details

import 'package:firstapp/program_page/list_exercises.dart';
import 'package:firstapp/program_page/popup_day_editor.dart';

class DayTile extends StatefulWidget {
  const DayTile({
    super.key,
    required this.editIndex,
    required this.context,
    required this.index,
    required this.theme,
    required this.onSetSaved,
    required this.onSetTapped,
    required this.onSetAdded,
    required this.onExerciseAdded,
  });

  final List<int> editIndex;
  final BuildContext context;
  final int index;
  final ThemeData theme;
  final Function onSetSaved;
  final Function onSetTapped;
  final Function onSetAdded;
  final Function onExerciseAdded;

  @override
  State<DayTile> createState() => _DayTileState();
}

class _DayTileState extends State<DayTile> {

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: widget.theme.colorScheme.outline),

        color: widget.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
      ),
          
      // Defining the inside of the actual box, display information
      child:  Center(
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            listTileTheme: const ListTileThemeData(
              // Removes extra padding
              contentPadding: EdgeInsets.only(left: 4, right: 16), 
            ),
          ),
                  
          // Expandable to see exercises and sets for that day
          child: ExpansionTile(
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)
            ),
            
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)
            ),

            iconColor: widget.theme.colorScheme.primary,
            collapsedIconColor: widget.theme.colorScheme.primary,
            onExpansionChanged: (val){
              if (!val){
                WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
                Provider.of<Profile>(context, listen: false).changeDone(false);
              }
            },
  
            // Top row always displays day title, and edit button
            // Sized boxes and padding is just a bunch of formatting stuff
            // tbh it could probably be made more concise
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
                              // Number
                              SizedBox(
                                width: 30,
                                child: Text(
                                
                                  "${widget.index + 1}",
                                    
                                  style: TextStyle(
                                    height: 0.6,
                          
                                    color: Color(context.watch<Profile>().split[widget.index].dayColor),
                                    fontSize: 50,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),

                              // Day title
                              Padding(
                                padding: const EdgeInsets.only(left : 16.0),
                                child: SizedBox(
                                  width: MediaQuery.sizeOf(context).width - 186,
                                  child: Text(
                                    overflow: TextOverflow.ellipsis,
                                    context.watch<Profile>().split[widget.index].dayTitle,
                                    
                                    style: TextStyle(
                                      color: widget.theme.colorScheme.onSurface,
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
                    
                    // Update title button
                    IconButton(
                      onPressed: () {         
                        showDialog(
                          anchorPoint: const Offset(100, 100),
                          context: context,

                          builder: (BuildContext context) {
                            return StatefulBuilder(
                              builder: (context, StateSetter setState) {
                                return PopUpDayEditor(
                                  theme: widget.theme,
                                  index: widget.index,
                                  titleTEC: TextEditingController(
                                    text: context.watch<Profile>().split[widget.index].dayTitle
                                  ),

                                );
                              },
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.edit_outlined),
                      color: widget.theme.colorScheme.secondary,
                    ),
                  ],
                ),
              ),
                          
            // Reorderable list of exercises for that day which come up upon tap to expanding
            children: [
              Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(12.0),
                    bottomLeft: Radius.circular(12.0)
                  ),
                ),

                child: ListExercises(
                  editIndex: widget.editIndex, 
                  context: context, 
                  index: widget.index,
                  theme: widget.theme,

                  onExerciseAdded: () async {
                    widget.onExerciseAdded();
                  },

                  onSetAdded: (exerciseIndex) {
                    widget.onSetAdded(exerciseIndex);
                  },

                  onSetTapped: (exerciseIndex, setIndex) {
                    widget.onSetTapped(exerciseIndex, setIndex);
                  },

                  onSetSaved: () {
                    widget.onSetSaved();
                  }
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }
}
