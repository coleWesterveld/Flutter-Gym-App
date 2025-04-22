// Displays a list of exercises, each with a list of sets for a day

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';                                  // Haptics

import 'package:flutter_slidable/flutter_slidable.dart';                 // Swipe To Delete
import 'package:firstapp/providers_and_settings/program_provider.dart';  // Access Program Details
import 'package:firstapp/providers_and_settings/settings_provider.dart';

import 'package:firstapp/widgets/list_sets.dart';

//TODO: add sets here too, centre text boxes, add notes option on dropdown
// TODO: exercise edit doesnt work - i disabled it. I need to migrate to the new exercise selector

class ListExercises extends StatefulWidget {
  const ListExercises({
    super.key,
    required this.context,
    required this.index,
    required this.onExerciseAdded,
    required this.theme,
  });

  final BuildContext context;
  final int index;
  final Function onExerciseAdded;
  final ThemeData theme;

  @override
  State<ListExercises> createState() => _ListExercisesState();
}

class _ListExercisesState extends State<ListExercises> {
  //final Function(int, int) onExerciseReorder;
  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
                                    
      //on reorder, update tree with new ordering
      onReorder: (oldIndex, newIndex){
        if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
        //widget.onExerciseReorder(oldIndex, newIndex);
        setState(() {
          context.read<Profile>().moveExercise(
            oldIndex: oldIndex, 
            newIndex: newIndex, 
            dayIndex: widget.index
          );
        });
      },
      
      // "add exercise" button at bottom of exercise list
      footer: Padding(
        key: const ValueKey('exerciseAdder'),
        padding: const EdgeInsets.all(8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ButtonTheme(
            minWidth: 100,

            child: TextButton.icon(
              onPressed: () async {
                if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
                // callback to program page - displays fullscreen exercise search and adds the chosen exercise
                await widget.onExerciseAdded();
              },
            
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  )
                ),

                backgroundColor: WidgetStateProperty.all(
                  widget.theme.colorScheme.primary,
                ),
              ),
              
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    color: widget.theme.colorScheme.onPrimary,
                  ),
                  Text(
                    "Exercise  ",
                    style: TextStyle(
                      color: widget.theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      physics: const NeverScrollableScrollPhysics(),
      itemCount: context.read<Profile>().exercises[widget.index].length,
      shrinkWrap: true,

      // Displaying list of exercises for that day
      itemBuilder: (context, exerciseIndex) {
        // Dismissable by swipe
        return Slidable(
          closeOnScroll: true,
          direction: Axis.horizontal,

          key: ValueKey(context.watch<Profile>().exercises[widget.index][exerciseIndex]),

          endActionPane: ActionPane(
            extentRatio: 0.3,
            motion: const ScrollMotion(),

            children: [
              SlidableAction(
              
                backgroundColor: widget.theme.colorScheme.error,
                foregroundColor: widget.theme.colorScheme.onError,
                icon: Icons.delete,

                onPressed: (direction) {
                if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
                  final deletedExercise = context.read<Profile>().exercises[widget.index][exerciseIndex];
                  final deletedSets = context.read<Profile>().sets[widget.index][exerciseIndex];
                  setState(() {
                    context.read<Profile>().exercisePop(index1: widget.index, index2: exerciseIndex);
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'Exercise Deleted'
                      ),

                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          try{
                            ("re-add: ${deletedExercise.toString()}");

                            setState(() {
                              context.read<Profile>().exerciseInsert(
                                index1: widget.index, 
                                index2: exerciseIndex,
                                data: deletedExercise, 
                                newSets: deletedSets,
                              );
                            });
                          } catch(e){
                            ('Undo failed: $e');

                            // Show error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to undo deletion :(')),
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

          // Box containing one exercise and its sets
          child: Container(
            // Outline to make dividers 
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.theme.colorScheme.outline,
                  width: 0.5
                ),
              ),
            ),

            child: Material(
              color: widget.theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    // Top title of exercise and set add button and edit button
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              context.watch<Profile>().exercises[widget.index][exerciseIndex].exerciseTitle,
                                                                
                              style: TextStyle(
                                color: widget.theme.colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
        
                        // Add set button 
                        Align(
                          key: const ValueKey('setAdder'),
                          alignment: Alignment.centerLeft,
        
                          child: Container(
                            width: 70,
                            height: 30,
            
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha((255 * 0.5).round()),
                                  offset: const Offset(0.0, 0.0),
                                  blurRadius: 12.0,
                                ),
                              ],
                            ),
                          
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.only(top: 0, bottom: 0, right: 0, left: 8),
                                backgroundColor: widget.theme.colorScheme.surface,//_listColorFlop(index: exerciseIndex + 1),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 2,
                                    color: widget.theme.colorScheme.primary,
                                  ),
                                  borderRadius: const BorderRadius.all(Radius.circular(8))
                                ),
                              ),
                          
                              onPressed: () {
                                if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
                              
                                context.read<Profile>().setsAppend(
                                  index1: widget.index,
                                  index2: exerciseIndex,
                                );

                                context.read<Profile>().editIndex = [
                                  widget.index, 
                                  exerciseIndex, 
                                  context.read<Profile>().sets[widget.index][exerciseIndex].length
                                ];
                              
                              },

                              label: Row(
                                children: [
                                  Icon(
                                    Icons.add,
                                    color: widget.theme.colorScheme.onSurface,
                                  ),

                                  Text(
                                    "Set",
                                    style: TextStyle(
                                      color: widget.theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  
                        // Confirm update button
                        IconButton(
                          // TODO: here we need to use the new exercise selector
                          onPressed: () async {
                            if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
                              int? exerciseID = 70;//await openDialog();
                              if (exerciseID == null) return;
                              
                            setState( () {
                              Provider.of<Profile>(context, listen: false).exerciseAssign(
                                index1: widget.index, 
                                index2: exerciseIndex,
                                data: Provider.of<Profile>(context, listen: false).exercises[widget.index][exerciseIndex].copyWith(newexerciseID: exerciseID)
                              );
                            });
                          }, 
                        
                          icon: const Icon(Icons.edit),
                          color: widget.theme.colorScheme.onSurface,
                        ),
                      ],
                    ),
          
                    // Displaying list of sets for each exercise
                    ListSets(
                      //widget: widget.widget, 
                      context: context, 
                      index: widget.index, 
                      exerciseIndex: exerciseIndex,
                      theme: widget.theme,
                    
             
                    ),
                  ],
                ),
              ),
            )
          )
        );
      },
    );
  }
}
