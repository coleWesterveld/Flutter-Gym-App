import 'package:firstapp/other_utilities/decimal_input_formatter.dart';
import 'package:firstapp/other_utilities/keyboard_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firstapp/providers_and_settings/program_provider.dart';
import '../database/profile.dart';
import '../providers_and_settings/settings_provider.dart';
import 'package:firstapp/widgets/shake_widget.dart';
import 'package:firstapp/providers_and_settings/active_workout_provider.dart';
import 'dart:async'; // For Timer
import 'package:keyboard_actions/keyboard_actions.dart';


class GymSetRow extends StatefulWidget {
  final int repsLower;
  final int repsUpper;
  final double expectedRPE;
  final int exerciseIndex, setIndex;
  final Function(bool) onChanged;
  final bool? initiallyChecked;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final TextEditingController rpeController;
  final int? recordID;

  const GymSetRow({
    super.key,
    required this.repsLower,
    required this.repsUpper,
    required this.expectedRPE,
    required this.exerciseIndex,
    required this.setIndex,
    required this.onChanged,
    required this.repsController,
    required this.weightController,
    required this.rpeController,
    this.initiallyChecked,
    required this.recordID
  });

  @override
  GymSetRowState createState() => GymSetRowState();
}

class GymSetRowState extends State<GymSetRow> with SingleTickerProviderStateMixin {

  final FocusNode weightFocus = FocusNode();
  final FocusNode repsFocus = FocusNode();
  final FocusNode rpeFocus = FocusNode();

  bool _isChecked = false;
  bool _weightError = false;
  bool _repsError = false;
  bool _rpeError = false;
  bool _moveItmoveIt = false;

  // For detecting changes on focus loss
  String _initialWeightOnFocus = "";
  String _initialRepsOnFocus = "";
  String _initialRpeOnFocus = "";

  late AnimationController _saveAnimationController;
  String? _animatingFieldIdentifier; // 'weight', 'reps', or 'rpe'

  // For "Saved" confirmation
  String? _fieldJustSaved; // Will be 'weight', 'reps', or 'rpe'
  Timer? _saveConfirmationTimer;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.recordID != null;

    _saveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Total duration of the animation sequence
    );

    _saveAnimationController.addListener(() {
      if (mounted) {
        setState(() {}); // Trigger rebuilds to show animation frames
      }
    });

    _saveAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _animatingFieldIdentifier = null; // Clear after animation completes
          });
        }
      }
    });

    weightFocus.addListener(_onWeightFocusChange);
    repsFocus.addListener(_onRepsFocusChange);
    rpeFocus.addListener(_onRpeFocusChange);

    weightFocus.addListener(_updateDoneState);
    repsFocus.addListener(_updateDoneState);
    rpeFocus.addListener(_updateDoneState);
  }


  @override
  void didUpdateWidget(GymSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recordID != oldWidget.recordID) {
      setState(() {
        _isChecked = widget.recordID != null;
      });
    }
  }

  void _updateDoneState() {
    bool anyFieldFocused = weightFocus.hasFocus || repsFocus.hasFocus || rpeFocus.hasFocus;
    context.read<Profile>().done = anyFieldFocused;
  }

  void _validateInputs() {
    setState(() {
      _weightError = widget.weightController.text.isEmpty || double.tryParse(widget.weightController.text) == null;
      _repsError = widget.repsController.text.isEmpty || double.tryParse(widget.repsController.text) == null;
      _rpeError = widget.rpeController.text.isEmpty || double.tryParse(widget.rpeController.text) == null;
    });

    if (_weightError || _repsError || _rpeError) {
      _moveItmoveIt = true;
    }
  }

  void _clearErrors() {
    setState(() {
      _weightError = false;
      _repsError = false;
      _rpeError = false;
    });
  }

  // track for save confirmations and user updating already logged set
  void _onWeightFocusChange() {
    if (weightFocus.hasFocus) {
      _initialWeightOnFocus = widget.weightController.text;
      if (_animatingFieldIdentifier == 'weight') _saveAnimationController.stop(); // Stop animation if re-focused
      setState(() => _animatingFieldIdentifier = null );
    } else {
      if (widget.recordID != null && widget.weightController.text != _initialWeightOnFocus) {
        _handleFieldUpdate('weight');
      }
    }
  }

  void _onRpeFocusChange() {
    if (rpeFocus.hasFocus) {
      _initialRpeOnFocus = widget.rpeController.text;
      if (_animatingFieldIdentifier == 'rpe') _saveAnimationController.stop();
      setState(() => _animatingFieldIdentifier = null );
    } else {
      if (widget.recordID != null && widget.rpeController.text != _initialRpeOnFocus) {
        _handleFieldUpdate('rpe');
      }
    }
  }

  void _onRepsFocusChange() {
    if (repsFocus.hasFocus) {
      _initialRepsOnFocus = widget.repsController.text;
      if (_animatingFieldIdentifier == 'reps') _saveAnimationController.stop();
      setState(() => _animatingFieldIdentifier = null );
    } else {
      if (widget.recordID != null && widget.repsController.text != _initialRepsOnFocus) {
        _handleFieldUpdate('reps');
      }
    }
  }

  Future<void> _handleFieldUpdate(String fieldName) async {
    if (widget.recordID == null || _saveAnimationController.isAnimating && _animatingFieldIdentifier == fieldName) {
         return; // Don't update if no recordID or already animating this field
    }

    // Temporarily unfocus to prevent keyboard issues during animation (optional)
    // FocusScope.of(context).unfocus();
    // await Future.delayed(Duration(milliseconds: 50)); // Give time for keyboard to hide if unfocused

    _validateInputs();
    if (_weightError || _repsError || _rpeError) {
      debugPrint("Validation error on update for field $fieldName, not saving.");

      // revert changes that cause an error. this is also paired with red and shake to indicate error.
      if (_weightError){
        widget.weightController.text = _initialWeightOnFocus;
      } else if (_repsError){
        widget.repsController.text = _initialRepsOnFocus;
      } else if (_repsError){
        widget.rpeController.text = _initialRpeOnFocus;
      }

      return;
    }

    final profileProvider = context.read<Profile>();
    final double? weight = double.tryParse(widget.weightController.text);
    final double? reps = double.tryParse(widget.repsController.text);
    final double? rpe = double.tryParse(widget.rpeController.text);

    if (weight == null || reps == null || rpe == null) {
      debugPrint("Error parsing values for update.");
      return;
    }

    bool success = await profileProvider.updateLoggedSet(
      recordID: widget.recordID!,
      fields: {'reps': reps, 'weight': weight, 'rpe': rpe},
    );

    if (success && mounted) {
      setState(() {
        _animatingFieldIdentifier = fieldName;
      });
      _saveAnimationController.reset();
      _saveAnimationController.forward();

      _initialWeightOnFocus = widget.weightController.text;
      _initialRepsOnFocus = widget.repsController.text;
      _initialRpeOnFocus = widget.rpeController.text;
    } else if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update set"), duration: Duration(seconds: 2)),
      );
    }
  }

  void _clearSavedConfirmation() {
    _saveConfirmationTimer?.cancel();
    if (_fieldJustSaved != null) {
      setState(() {
        _fieldJustSaved = null;
      });
    }
  }

  @override
  void dispose() {
    _saveAnimationController.dispose();
    weightFocus.removeListener(_onWeightFocusChange);
    repsFocus.removeListener(_onRepsFocusChange);
    rpeFocus.removeListener(_onRpeFocusChange);
    weightFocus.removeListener(_updateDoneState);
    repsFocus.removeListener(_updateDoneState);
    rpeFocus.removeListener(_updateDoneState);
    weightFocus.dispose();
    repsFocus.dispose();
    rpeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(context.read<ActiveWorkoutProvider>().sessionID != null, "SessionID is null");
    assert(context.read<ActiveWorkoutProvider>().activeDayIndex != null, "No active day index");
    assert(context.read<ActiveWorkoutProvider>().activeDay != null, "No active day");
    return ShakeWidget(
      shake: _moveItmoveIt,
      onAnimationComplete: () => _moveItmoveIt = false,
      child: Container(
        decoration: BoxDecoration(
          color: _isChecked ? Colors.blue.withAlpha(128) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  "${widget.repsLower}-${widget.repsUpper} reps @ ${widget.expectedRPE} RPE",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
                _buildTextFieldWithConfirmation(widget.rpeController, rpeFocus, "", 35, _rpeError, "rpe"),
                _buildTextFieldWithConfirmation(widget.weightController, weightFocus, "", 50, _weightError, "weight"),
                _buildTextFieldWithConfirmation(widget.repsController, repsFocus, "", 40, _repsError, "reps"),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: InkWell(
                  onTap: () {
                    if (context.read<SettingsModel>().hapticsEnabled) {
                      HapticFeedback.heavyImpact();
                    }

                    // is not checked means now we are trying to save it
                    // we dont need to validate inputs when unsaving
                    if (!_isChecked){
                      WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
                      _validateInputs();
                      if (_weightError || _repsError || _rpeError) return;
                    }

                    _clearSavedConfirmation();

                    setState(() {
                      _isChecked = !_isChecked;
                      widget.onChanged(_isChecked);
                    });

                    
                  },
                  child: Container(
                    width: 24.0,
                    height: 24.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isChecked ? Colors.blue : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: _isChecked
                        ? Center(
                            child: Icon(
                              Icons.check,
                              size: 16.0,
                              color: _isChecked ? Colors.blue : Colors.grey,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // yeah atp this should maybe be made
   

  Widget _buildTextFieldWithConfirmation(
    TextEditingController controller,
    FocusNode focusNode,
    String hint,
    double width,
    bool hasError,
    String fieldIdentifier, // To know which field this is

  ) {

    final bool amIAnimating = _animatingFieldIdentifier == fieldIdentifier;
    final double animValue = _saveAnimationController.value; // 0.0 to 1.0
    final theme = Theme.of(context);

    Color currentBgColor = hasError ? theme.colorScheme.errorContainer : theme.scaffoldBackgroundColor;
    double textOpacity = 1.0;
    double checkmarkOpacity = 0.0;

    if (amIAnimating) {
      // Animation phases:
      // 0.0 - 0.25: Fade text out, fade bg to green
      // 0.25 - 0.75: Show checkmark, bg green
      // 0.75 - 1.0: Fade checkmark out, fade text in, fade bg to normal
      if (animValue < 0.25) {
        textOpacity = 1.0 - (animValue / 0.25);
        currentBgColor = Color.lerp(currentBgColor, Colors.green.withOpacity(0.6), animValue / 0.25)!;
        checkmarkOpacity = animValue / 0.25; // Fade in checkmark with bg
      } else if (animValue < 0.75) {
        textOpacity = 0.0;
        currentBgColor = Colors.green.withOpacity(0.6);
        checkmarkOpacity = 1.0;
      } else {
        textOpacity = (animValue - 0.75) / 0.25;
        currentBgColor = Color.lerp(Colors.green.withOpacity(0.6), hasError ? theme.colorScheme.errorContainer : theme.colorScheme.surfaceContainerHighest.withAlpha(100), (animValue - 0.75) / 0.25)!;
        checkmarkOpacity = 1.0 - ((animValue - 0.75) / 0.25);
      }
      textOpacity = textOpacity.clamp(0.0, 1.0);
      checkmarkOpacity = checkmarkOpacity.clamp(0.0, 1.0);
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        width: width,
        // height: 30,

        child: Stack(
          alignment: Alignment.center,

          children: [
            KeyboardActions(
              disableScroll: true,
              config: buildKeyboardActionsConfig(context, theme, [focusNode]),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
              
                style: TextStyle(
                  fontSize: 14,
                  color: (theme.textTheme.bodyLarge?.color ?? Colors.black).withOpacity(textOpacity),
                ),
              
                inputFormatters: [
                  // TODO: RPE is allowed 1 decimal, everything else can have 2. textbox sizes could be bigger so scroll is not needed, but also needs to be reactive
                  TwoDecimalTextInputFormatter()
                ],
                decoration: InputDecoration(
                  
                  filled: true,
                  fillColor: hasError ? Colors.red.withAlpha(64) : currentBgColor,
                  contentPadding: const EdgeInsets.only(bottom: 10, left: 8),
                  constraints: BoxConstraints(
                    maxWidth: width,
                    maxHeight: 30,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  hintText: hint,
                  errorStyle: const TextStyle(height: 0),
                ),
                onChanged: (value) => _clearErrors(),
              ),
            ),

            // Checkmark overlay
          if (checkmarkOpacity > 0) // Only build if visible or fading
            IgnorePointer( // Checkmark should not be interactive
              child: Opacity(
                opacity: checkmarkOpacity,
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white.withOpacity(0.9), // White checkmark, slightly transparent for blending
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}