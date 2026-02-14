// Where the user can add an exercise to the exercise database
// Navigated from the select exercise page

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firstapp/database/database_helper.dart';
import '../providers_and_settings/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:firstapp/widgets/shake_widget.dart';

class CustomExerciseForm extends StatefulWidget {

  const CustomExerciseForm({
    super.key, 
    required this.height,
    required this.exit,
    required this.theme,
    required this.onDone
  });

  final void Function() exit;
  final double height;
  final ThemeData theme;
  final Function(Map<String, dynamic>) onDone;

  @override
  CustomExerciseFormState createState() => CustomExerciseFormState();
}

class CustomExerciseFormState extends State<CustomExerciseForm> {
  final TextEditingController _exerciseTEC = TextEditingController();
  final TextEditingController _musclesTEC = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  bool _shakeExercise = false;
  String? _exerciseError;


  /// Capitalizes the first letter of every word in [input]
  String capitalizeWords(String input) {
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  void dispose() {
    _exerciseTEC.dispose();
    _musclesTEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height: widget.height,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              // Main exercise text field
              // Shakes if user tries to submit without entering
              ShakeWidget(
                shake: _shakeExercise,
                child: TextFormField(
                  selectAllOnFocus: true,
                  controller: _exerciseTEC,
                  autofocus: true,
                  decoration: InputDecoration(
                    errorText: _exerciseError,
                    hintText: "Enter Exercise",
                    errorBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                      borderSide: BorderSide(
                        width: 2.0, 
                        color: widget.theme.colorScheme.error
                      ),
                    ),

                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                      borderSide: BorderSide(
                        width: 2.0, 
                        color: widget.theme.colorScheme.error
                      ),
                    ),

                    suffixIcon: IconButton(
                      icon: const Icon(Icons.highlight_remove),
                      onPressed: _exerciseTEC.clear,
                    ),
                  ),

                  // Nothing happens until the done button is pressed. This is just haptics
                  onFieldSubmitted: (value) {
                    if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
                  },
                ),
              ),

              const SizedBox(height: 16.0),

              // Optional Muscles Worked field
              TextFormField(
                selectAllOnFocus: true,
                onChanged: (value) {
                  if (value.trim().isNotEmpty && _exerciseError != null) {
                    setState(() {
                      _exerciseError = null;
                    });
                  }
                },
                controller: _musclesTEC,
                decoration: InputDecoration(
                  
                  hintText: "Muscles Worked (Optional)",
  
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.highlight_remove),
                    onPressed: _musclesTEC.clear,
                  ),
                ),
              ),

              const SizedBox(height: 16.0),

              // Done button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                     height: 60,
                     width: (MediaQuery.sizeOf(context).width - 32) / 2,
                    child: Card(
                    
                      color: widget.theme.colorScheme.primary,
                      child: InkWell(
                        splashColor: widget.theme.colorScheme.secondary,
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {

                          // Retrieve and trim text values
                          final exerciseText = _exerciseTEC.text.trim();

                          if (exerciseText.isEmpty) {
                            setState(() {
                              _exerciseError = "You need to enter a title";
                              _shakeExercise = true;
                            });

                            // Reset the shake flag after the animation duration.
                            Future.delayed(const Duration(milliseconds: 500), () {
                              setState(() {
                                _shakeExercise = false;
                              });
                            });
                            return;
                          }

                          // Clear error if input is valid.
                          setState(() {
                            _exerciseError = null;
                          });
     
                          final musclesText = _musclesTEC.text.trim();
                                        
                          // Capitalize each word in the inputs
                          final formattedExercise = capitalizeWords(exerciseText);
                          final formattedMuscles = musclesText.isNotEmpty ? capitalizeWords(musclesText) : '';
                            
                          final id = await dbHelper.insertCustomExercise(
                            exerciseTitle: formattedExercise, 
                            musclesWorked: formattedMuscles
                          );

                          widget.onDone({'exercise_id': id});

                          widget.exit();
       
                        },
                        child: Center(
                          child: Text(
                            "Done",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: widget.theme.colorScheme.onPrimary,
                            )
                          )
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                     height: 60,
                     width: (MediaQuery.sizeOf(context).width - 32) / 2,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: widget.theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    
                      child: InkWell(
                      
                        splashColor: widget.theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        
                        onTap: () {
                          widget.exit();
                                        
                        },
                        child: Center(
                          child: Text(
                            "Cancel",
                            
                            style: TextStyle(
                              color: widget.theme.colorScheme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600
                            )
                          )
                        ),
                      ),
                    ),
                             
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/////////////////////////////////////////////////
// Shake widget for text box if not entered properly
