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
import 'package:collection/collection.dart';


class DisplaySet extends StatefulWidget {
  const DisplaySet({
    super.key,
    required this.index,
    required this.exerciseIndex,
    required this.setIndex,
    required this.theme,
  });

  final int index;
  final int exerciseIndex;
  final int setIndex;
  final ThemeData theme;


  @override
  State<DisplaySet> createState() => _DisplaySetState();
}

class _DisplaySetState extends State<DisplaySet> {
  late TextEditingController _setsController;
  late TextEditingController _rpeController;
  late TextEditingController _repsLowerController;
  late TextEditingController _repsUpperController;

  final Function listEquals = const ListEquality().equals;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<Profile>(context, listen: false);
    final setData = profile.sets[widget.index][widget.exerciseIndex][widget.setIndex];
    
    _setsController = TextEditingController(text: setData.numSets.toString());
    _rpeController = TextEditingController(text: setData.rpe.toString());
    _repsLowerController = TextEditingController(text: setData.setLower.toString());
    _repsUpperController = TextEditingController(text: setData.setUpper.toString());
  }

  @override
  void dispose() {
    _setsController.dispose();
    _rpeController.dispose();
    _repsLowerController.dispose();
    _repsUpperController.dispose();
    super.dispose();
  }

  void _saveSet() {
    context.read<Profile>().editIndex = [-1, -1, -1];
    
    final profile = Provider.of<Profile>(context, listen: false);
    profile.setsAssign(
      index1: widget.index,
      index2: widget.exerciseIndex,
      index3: widget.setIndex,
      data: profile.sets[widget.index][widget.exerciseIndex][widget.setIndex].copyWith(
        newNumSets: int.tryParse(_setsController.text) ?? 0,
        newRpe: int.tryParse(_rpeController.text) ?? 0,
        newSetLower: int.tryParse(_repsLowerController.text) ?? 0,
        newSetUpper: int.tryParse(_repsUpperController.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (
          listEquals(
            context.watch<Profile>().editIndex,
            [widget.index, widget.exerciseIndex, widget.setIndex]
          )
        )
          Container(
            color: widget.theme.colorScheme.surfaceContainerHighest,
            width: MediaQuery.sizeOf(context).width - 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SetTextField(controller: _setsController, hint: 'Sets', maxWidth: 50),
                  SetTextField(controller: _rpeController, hint: 'RPE', maxWidth: 50),
                  const Icon(Icons.clear),
                  SetTextField(controller: _repsLowerController, hint: 'Reps', maxWidth: 50),
                  const Text("-"),
                  SetTextField(controller: _repsUpperController, hint: 'Reps', maxWidth: 50),
                  const Spacer(flex: 1),

                  IconButton(
                    onPressed: _saveSet,
                    icon: Icon(
                      Icons.check, 
                      color: widget.theme.colorScheme.secondary
                    ),
                    
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
                          color: widget.theme.colorScheme.secondary,
                          width: 2.0,
                        ),
                      ),
                    ),                  
                  )
                ],
              ),
            ),
          )
        else
          GestureDetector(
            onTap: () => context.read<Profile>().editIndex = [
              widget.index, 
              widget.exerciseIndex, 
              widget.setIndex
            ],

            child: AbsorbPointer(
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width - 48,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '${context.watch<Profile>().sets[widget.index][widget.exerciseIndex][widget.setIndex].numSets} x '
                        '${context.watch<Profile>().sets[widget.index][widget.exerciseIndex][widget.setIndex].setLower} x '
                        '${context.watch<Profile>().sets[widget.index][widget.exerciseIndex][widget.setIndex].rpe}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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

// Simplified SetTextField
class SetTextField extends StatelessWidget {
  const SetTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.maxWidth,
  });

  final TextEditingController controller;
  final String hint;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Focus(
        onFocusChange: (hasFocus) {
          context.read<Profile>().changeDone(hasFocus);
        },
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            contentPadding: const EdgeInsets.only(bottom: 10, left: 8),
            constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 30),
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
