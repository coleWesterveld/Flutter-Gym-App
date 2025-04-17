import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firstapp/database/database_helper.dart';
import '../providers_and_settings/settings_provider.dart';
import 'package:provider/provider.dart';

class CustomExerciseForm extends StatefulWidget {
  final double height;
  const CustomExerciseForm({
    super.key, 
    required this.height,
    required this.exit,
    });

  final void Function() exit;

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
    // You can adjust maxHeight as needed, for example if this is inside a modal.
    //final maxHeight = MediaQuery.of(context).size.height * 0.5;

    return SizedBox(
      height: widget.height,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            // mainAxisSize.min allows the column to wrap its content
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main exercise text field
              ShakeWidget(
                shake: _shakeExercise,
                child: TextFormField(
                  controller: _exerciseTEC,
                  autofocus: true,
                  decoration: InputDecoration(
                    errorText: _exerciseError,
                    hintText: "Enter Exercise",
                    errorBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)), // For focused state
                      borderSide: BorderSide(width: 2.0), // Optional focus border
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)), // Adjust the radius as needed
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)), // For non-focused state
                      borderSide: BorderSide(color: Colors.grey), // Optional border color
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)), // For focused state
                      borderSide: BorderSide(color: Colors.blue, width: 2.0), // Optional focus border
                    ),
                    suffixIcon: IconButton(
                      icon:const  Icon(Icons.highlight_remove),
                      onPressed: _exerciseTEC.clear,
                    ),
                  ),
                  onFieldSubmitted: (value) {
                    if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              // Optional Muscles Worked field
              TextFormField(
                onChanged: (value) {
                  if (value.trim().isNotEmpty && _exerciseError != null) {
                    setState(() {
                      _exerciseError = null;
                    });
                  }
                },
                
                controller: _musclesTEC,
                
                decoration: InputDecoration(
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)), // Adjust the radius as needed
                      borderSide: BorderSide.none, // Removes the border if you want only the filled background
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)), // For non-focused state
                      borderSide: BorderSide(color: Colors.grey), // Optional border color
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16.0)), // For focused state
                      borderSide: BorderSide(color: Colors.blue, width: 2.0), // Optional focus border
                    ),
                  
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
                    
                      color: const Color(0XFF1A78EB),
                      child: InkWell(
                      
                        splashColor: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                                          
                          
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
                          final formattedMuscles =
                              musclesText.isNotEmpty ? capitalizeWords(musclesText) : '';
                            
                     
                        
                            dbHelper.insertCustomExercise(
                              exerciseTitle: formattedExercise, 
                              musclesWorked: formattedMuscles
                            );

                            widget.exit();
                          
                                          
                        },
                        child: const Center(
                          child: Text(
                            "Done",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600
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
                        borderRadius: BorderRadius.circular(12), // Optional: Rounded corners
                        side: const BorderSide(
                          color: Color(0XFF1A78EB), // Outline color
                          width: 2, // Outline width
                        ),
                      ),
                    
                      //color: const Color(0XFF1A78EB),
                      child: InkWell(
                      
                        splashColor: Colors.deepOrange,
                        borderRadius: BorderRadius.circular(16),
                        
                        onTap: () {
                          widget.exit();
                                        
                        },
                        child: const Center(
                          child: Text(
                            "Cancel",
                            
                            style: TextStyle(
                              color: Color(0XFF1A78EB),
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
              // ElevatedButton(
              //   onPressed: () {
              //     // Retrieve and trim text values
              //     final exerciseText = _exerciseTEC.text.trim();
              //     final musclesText = _musclesTEC.text.trim();

              //     // Capitalize each word in the inputs
              //     final formattedExercise = capitalizeWords(exerciseText);
              //     final formattedMuscles =
              //         musclesText.isNotEmpty ? capitalizeWords(musclesText) : '';
                    
              //     
              //     Navigator.of(context).pop(
              //       dbHelper.insertCustomExercise(
              //         exerciseTitle: formattedExercise, 
              //         musclesWorked: formattedMuscles
              //       ),
              //     );

              //   },
              //   child: const Text("Done"),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}


/////////////////////////////////////////////////
// shake widget for text box if not entered properly

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;

  const ShakeWidget({
    Key? key,
    required this.child,
    required this.shake,
  }) : super(key: key);

  @override
  _ShakeWidgetState createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(milliseconds: 500), vsync: this);

    _offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the "shake" flag changes to true, trigger the animation.
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offsetAnimation.value, 0),
          child: widget.child,
        );
      },
    );
  }
}
