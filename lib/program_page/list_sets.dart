// Displays A list of sets for an exercise under the program page

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';                                  // Haptics

import 'package:flutter_slidable/flutter_slidable.dart';                 // Swipe To Delete
import 'package:firstapp/providers_and_settings/program_provider.dart';  // Access Program Details
import 'package:firstapp/providers_and_settings/settings_provider.dart'; // Access to Settings

import 'package:firstapp/program_page/display_set.dart';
import 'package:firstapp/program_page/program_page.dart';

// TODO: add sets here too, centre text boxes, add notes option on dropdown
// TODO: fix bug when user navigates away from program page and presses undo

class ListSets extends StatefulWidget {
  const ListSets({
    super.key,
    required this.editIndex,
    required this.widget,
    required this.context,
    required this.index,
    required this.exerciseIndex,
    required this.onSetTapped,
    required this.onSetSaved,
    required this.theme,
  });

  final List<int> editIndex;
  final ProgramPage widget;
  final BuildContext context;
  final int index;
  final int exerciseIndex;
  final Function(int) onSetTapped;
  final Function onSetSaved;
  final ThemeData theme;

  @override
  State<ListSets> createState() => _ListSetsState();
}

class _ListSetsState extends State<ListSets> {
  @override
  Widget build(BuildContext context) {

    return ReorderableListView.builder(

      //on reorder, update widget with new ordering
      onReorder: (oldIndex, newIndex){
        if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
        
        setState(() {
          context.read<Profile>().moveSet(oldIndex: oldIndex, newIndex: newIndex, dayIndex: widget.index, exerciseIndex: widget.exerciseIndex);
        });
      },

      physics: const NeverScrollableScrollPhysics(),
      itemCount: context.read<Profile>().sets[widget.index][widget.exerciseIndex].length,
      shrinkWrap: true,

      // Displaying list of sets for that exercise
      itemBuilder: (context, setIndex) {
        // Slide to delete
        return Slidable(
          closeOnScroll: true,
          direction: Axis.horizontal,

          key: ValueKey(context.watch<Profile>().sets[widget.index][widget.exerciseIndex][setIndex]),
          endActionPane: ActionPane(
            extentRatio: 0.3,
            motion: const ScrollMotion(), 
            children: [SlidableAction(
              
              backgroundColor: widget.theme.colorScheme.error,
              foregroundColor: widget.theme.colorScheme.onError,
              icon: Icons.delete,
              onPressed: (direction) {
                if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();

                // Delete and save for potential of undo
                final deletedSet = context.read<Profile>().sets[widget.index][widget.exerciseIndex][setIndex];
                setState(() {
                  context.read<Profile>().setsPop(index1: widget.index, index2: widget.exerciseIndex, index3: setIndex);
                });

                // Dipslay snackbar with undo
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      style: TextStyle(
                        color: Colors.white
                      ),
                      'Set Deleted'
                      ),
                      action: SnackBarAction(
                      label: 'Undo',
                      textColor: Colors.white,
                      onPressed: () {
                        try{
                        debugPrint("re-add: ${deletedSet.toString()}");

                        setState(() {
                          context.read<Profile>().setsInsert(
                            index1: widget.index, 
                            index2: widget.exerciseIndex,
                            index3: setIndex,
                            data: deletedSet, 
                          );
                        });
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
          // Actual information about the sets
          child: DisplaySet(
            editIndex: widget.editIndex, 
            context: context, 
            index: widget.index, 
            exerciseIndex: widget.exerciseIndex, 
            setIndex: setIndex,
            theme: widget.widget.theme,

            onSetTapped: () => widget.onSetTapped(setIndex),
            onSetSaved: (){
              widget.onSetSaved();

              context.read<Profile>().setsAssign(
                index1: widget.index, 
                index2: widget.exerciseIndex, 
                index3: setIndex, 
                // my silly way of getting around error where cant parse if box is blank is to prepend '0' in the string
                // if empty, will save 0. else, will disregard the 0.
                // THIS IS PROBLEMATIC IF -1 is put - have "0-1"
                data: context.read<Profile>().sets[widget.index][widget.exerciseIndex][setIndex].copyWith(
                  newNumSets: int.parse("0${context.read<Profile>().setsTEC[widget.index][widget.exerciseIndex][setIndex].text}"),
                  newRpe: int.parse("0${context.read<Profile>().rpeTEC[widget.index][widget.exerciseIndex][setIndex].text}"),
                  newSetLower: int.parse("0${context.read<Profile>().reps1TEC[widget.index][widget.exerciseIndex][setIndex].text}"),
                  newSetUpper: int.parse("0${context.read<Profile>().reps2TEC[widget.index][widget.exerciseIndex][setIndex].text}"),
                )
              );
            },
          ),
        );
      },
    );
  }
}
