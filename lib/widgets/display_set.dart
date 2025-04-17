// Display a single set in a program, usually within dropdown day

/*
Todo here: 
we probably only need one TEC for each field, not 3 for each set
since only one at a time is editable

also, the text fields are not well labelled, its hard to tell what youre inputting

done button is not working as intended
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firstapp/providers_and_settings/program_provider.dart';

class DisplaySet extends StatelessWidget {
  const DisplaySet({
    super.key,
    required this.editIndex,
    required this.context,
    required this.index,
    required this.exerciseIndex,
    required this.setIndex,
    required this.theme,
    required this.onSetSaved,
    required this.onSetTapped
  });

  final List<int> editIndex;
  final BuildContext context;
  final int index;
  final int exerciseIndex;
  final int setIndex;
  final ThemeData theme;
  final Function onSetSaved;
  final Function onSetTapped;

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [
        // Gesture detector to toggle between AxBxC and the editable fields
        (editIndex[0] == index && editIndex[1] == exerciseIndex && editIndex[2] == setIndex) 
          ? Container(
            color: theme.colorScheme.surfaceContainerHighest,
                    
            width: MediaQuery.sizeOf(context).width - 48,
          
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                
                children: [
                  // Show text fields when editing
                  SetTextField(context: context, controller: context.watch<Profile>().setsTEC[index][exerciseIndex][setIndex], hint: 'Sets', maxWidth: 50),
                  SetTextField(context: context, controller: context.watch<Profile>().rpeTEC[index][exerciseIndex][setIndex], hint: 'RPE', maxWidth: 80),
                  const Icon(Icons.clear),
                  SetTextField(context: context, controller: context.watch<Profile>().reps1TEC[index][exerciseIndex][setIndex], hint: 'Reps', maxWidth: 80),
                  const Spacer(flex: 1),

                  // Save set button
                  IconButton(
                    padding: const EdgeInsets.all(0.0),
                    style: ButtonStyle(
                      shape: WidgetStateProperty.all<OutlinedBorder>(
                        const CircleBorder(), 
                      ),

                      minimumSize: WidgetStateProperty.all<Size>(
                        const Size(32, 32), 
                      ),

                      side: WidgetStateProperty.all<BorderSide>(
                        BorderSide(
                          color: theme.colorScheme.secondary,
                          width: 2.0,
                        ),
                      ),
                    ),

                    // callback to parent widget
                    onPressed: () {
                      onSetSaved();
                    },
                    
                    icon: Icon(
                      Icons.check, 
                      color: theme.colorScheme.secondary,
                    )
                  )
                ],
              ),
            ),
          )
        : GestureDetector(
          // callback to parent when widget tapped
          onTap: () {
            onSetTapped();
            
          },
          child: AbsorbPointer(
            child: SizedBox(
            
              width: MediaQuery.sizeOf(context).width - 48,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Display AxBxC format when not editing
                      Text(
                        '${context.watch<Profile>().sets[index][exerciseIndex][setIndex].numSets} x '
                        '${context.watch<Profile>().sets[index][exerciseIndex][setIndex].setLower} x '
                        '${context.watch<Profile>().sets[index][exerciseIndex][setIndex].rpe}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Each textfield within the set
// small wrapper of Flutter textformfield
class SetTextField extends StatelessWidget {
  const SetTextField({
    super.key,
    required this.context,
    required this.controller,
    required this.hint,
    required this.maxWidth,
  });

  final BuildContext context;
  final TextEditingController controller;
  final String hint;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Focus(
        onFocusChange: (hasFocus) {
          if(hasFocus){
            context.read<Profile>().changeDone(true);
          }else{
            context.read<Profile>().changeDone(false);
          }
        },
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            contentPadding: const EdgeInsets.only(bottom: 10, left: 8),
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: 30,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            hintText: hint,
          ),
        ),
      ),
    );
  }
}
