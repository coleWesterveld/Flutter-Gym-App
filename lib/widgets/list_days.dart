// Displays a list of days, each with a list of exercises containing their sets, for a program/phase of a program

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';                                  // Haptics

import 'package:flutter_slidable/flutter_slidable.dart';                 // Swipe To Delete
import 'package:firstapp/providers_and_settings/program_provider.dart';  // Access Program Details
import 'package:firstapp/providers_and_settings/settings_provider.dart';

import 'package:firstapp/widgets/day_tile.dart';

class ListDays extends StatefulWidget {
  const ListDays({
    super.key,
    required this.editIndex,
    required this.theme,
    required this.context,
    required this.onExerciseAdded,
    required this.onSetAdded,
    required this.onSetTapped,
    required this.onSetSaved,
  });

  final List<int> editIndex;
  final BuildContext context;
  final ThemeData theme;
  final Function(int) onExerciseAdded;
  final Function(int, int) onSetAdded;
  final Function(int, int, int) onSetTapped;
  final Function onSetSaved;

  @override
  State<ListDays> createState() => _ListDaysState();
}

class _ListDaysState extends State<ListDays> {

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      // Reordering days
      onReorder: (oldIndex, newIndex){
        if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
          context.read<Profile>().moveDay(
            oldIndex: oldIndex, 
            newIndex: newIndex, 
            programID: context.read<Profile>().currentProgram.programID
          );
      },
      
      // Button at bottom to add a new day to split
      footer: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          key: const ValueKey('dayAdder'),
        
          color: widget.theme.colorScheme.primary,
          child: InkWell(
          
            splashColor: widget.theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
                context.read<Profile>().splitAppend();                
            },
            child: SizedBox(
              width: double.infinity,
              height: 50.0,
              child: Icon(
                Icons.add,
                color: widget.theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
          
      // Building the list of day tiles
      itemCount: context.watch<Profile>().split.length,
      itemBuilder: (context, index) {
        // Swipe right-to-left to show delete option
        return Slidable(
          closeOnScroll: true,
          direction: Axis.horizontal,

          key: ValueKey(context.watch<Profile>().split[index]),

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

                  // Cache deleted data to allow undo
                  final deletedDay = context.read<Profile>().split[index];
                  final deletedExercises = context.read<Profile>().exercises[index];
                  final deletedSets = context.read<Profile>().sets[index];

                  // Delete the data
                  context.read<Profile>().splitPop(index: index);   

                  // Display snackbar with undo option 
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        style: TextStyle(
                          color: widget.theme.colorScheme.onSecondary,
                        ),
                        'Day Deleted'
                      ),

                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: widget.theme.colorScheme.onSecondary,
                        onPressed: () {
                          try{
                            debugPrint("re-add: ${deletedDay.toString()}");
                            
                            context.read<Profile>().splitInsert(
                              index: index, 
                              day: deletedDay, 
                              exerciseList: deletedExercises, 
                              newSets: deletedSets,
                            );
                          } catch(e){
                            debugPrint('Undo failed: $e');
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
          
          // A tile representing a day
          child: Padding(
            key: ValueKey(context.watch<Profile>().split[index]),
            padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                      
            child: DayTile(
              editIndex: widget.editIndex, 
              context: context, 
              index: index,
              theme: widget.theme,

              onSetSaved: () => widget.onSetSaved(),

              onSetTapped: (exerciseIndex, setIndex) {
                widget.onSetTapped(index, exerciseIndex, setIndex);
              },

              onSetAdded: (exerciseIndex) {
                widget.onSetAdded(index, exerciseIndex);
              },

              onExerciseAdded: () => widget.onExerciseAdded(index)
            
            )
          ),  
        );
      },
    );
  }
}
