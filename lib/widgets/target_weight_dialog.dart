// For taking in target weight for goal on anayltics page

// TODO: allow n rep maxes, not just 1rm
// allow users to manually enter a current weight if they dont like auto calculated
// maybe toggle between auto and not

/* 
TODO: put this in all numeric text fields:
TextField(
  controller: _weightController,
  keyboardType: TextInputType.number,
  // Ensure only numbers can be entered
  inputFormatters: [                        // THIS CODE *******
    FilteringTextInputFormatter.digitsOnly,
  ],
  decoration: InputDecoration(
    labelText: "Target Weight",
    suffixText: "lbs",
    border: const OutlineInputBorder(),
      // Show error border/text if submitted when empty
      errorText: _submittedWhenEmpty && _weightController.text.isEmpty
          ? "Weight cannot be empty"
          : null,
  ),
  autofocus: true,
  onChanged: (text) {
      // Reset shake state as soon as user starts typing
      if (_submittedWhenEmpty && text.isNotEmpty) {
        setState(() {
          _submittedWhenEmpty = false;
        });
      }
  },
),
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firstapp/widgets/shake_widget.dart';

class TargetWeightDialog extends StatefulWidget {
  final String exerciseName;
  final ThemeData theme;

  const TargetWeightDialog({
    super.key,
    required this.exerciseName,
    required this.theme,
  });

  @override
  TargetWeightDialogState createState() => TargetWeightDialogState();
}

class TargetWeightDialogState extends State<TargetWeightDialog> {
  final TextEditingController _weightController = TextEditingController();
  bool _submittedWhenEmpty = false;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Set Target for ${widget.exerciseName}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShakeWidget(
            shake: _submittedWhenEmpty,
            child: TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              // Ensure only numbers can be entered
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: "Target Weight",
                suffixText: "lbs",
                border: const OutlineInputBorder(),
                 // Show error border/text if submitted when empty
                 errorText: _submittedWhenEmpty && _weightController.text.isEmpty
                     ? "Weight cannot be empty"
                     : null,
              ),
              autofocus: true,
              onChanged: (text) {
                 // Reset shake state as soon as user starts typing
                 if (_submittedWhenEmpty && text.isNotEmpty) {
                   setState(() {
                     _submittedWhenEmpty = false;
                   });
                 }
              },
            ),
          ),
        ],
      ),
      actions: [
        SizedBox(
          height: 45,
          width: 72,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: ButtonStyle(
          
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  side: BorderSide(
                    width: 2,
                    color: widget.theme.colorScheme.primary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.pressed)) return widget.theme.colorScheme.primary;
                  return null;
                },
              ),
            ),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: widget.theme.colorScheme.primary,
              ),
            ),
          ),
        ),

        SizedBox(
          width: 72,
          height: 45,
          child: TextButton(
            onPressed: () {
              if (_weightController.text.isNotEmpty) {
                // Pass the weight back when the dialog is popped
                Navigator.pop(context, int.parse(_weightController.text));
              } else {
                setState(() {
                  _submittedWhenEmpty = true;
                });
              }
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
          
              overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (states.contains(WidgetState.pressed)) return widget.theme.colorScheme.primary;
                return null;
              }),
            ),
          
            child: Text(
              "Save",
              style: TextStyle(
                color: widget.theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
