import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firstapp/providers_and_settings/program_provider.dart';
import '../database/profile.dart';
import '../providers_and_settings/settings_provider.dart';
import 'package:firstapp/widgets/shake_widget.dart';
import 'package:firstapp/providers_and_settings/active_workout_provider.dart';

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
  });

  @override
  GymSetRowState createState() => GymSetRowState();
}

class GymSetRowState extends State<GymSetRow> {

  final FocusNode weightFocus = FocusNode();
  final FocusNode repsFocus = FocusNode();
  final FocusNode rpeFocus = FocusNode();

  bool _isChecked = false;
  bool _weightError = false;
  bool _repsError = false;
  bool _rpeError = false;
  bool _moveItmoveIt = false;

  @override
  void initState() {
    super.initState();
    if (widget.initiallyChecked != null) _isChecked = widget.initiallyChecked!;

    

    weightFocus.addListener(_updateDoneState);
    repsFocus.addListener(_updateDoneState);
    rpeFocus.addListener(_updateDoneState);
  }

  void _updateDoneState() {
    bool anyFieldFocused = weightFocus.hasFocus || repsFocus.hasFocus || rpeFocus.hasFocus;
    context.read<Profile>().done = anyFieldFocused;
  }

  void _validateInputs() {
    setState(() {
      _weightError = widget.weightController.text.isEmpty || int.tryParse(widget.weightController.text) == null;
      _repsError = widget.repsController.text.isEmpty || int.tryParse(widget.repsController.text) == null;
      _rpeError = widget.rpeController.text.isEmpty || int.tryParse(widget.rpeController.text) == null;
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

  @override
  void dispose() {

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
                  style: TextStyle(fontSize: 16),
                ),
              ),
              _buildTextField(widget.rpeController, rpeFocus, "", 30, _rpeError),
              _buildTextField(widget.weightController, weightFocus, "", 50, _weightError),
              _buildTextField(widget.repsController, repsFocus, "", 40, _repsError),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: InkWell(
                  onTap: () {
                    if (context.read<SettingsModel>().hapticsEnabled) {
                      HapticFeedback.heavyImpact();
                    }

                    _validateInputs();
                    if (_weightError || _repsError || _rpeError) return;

                    setState(() {
                      _isChecked = !_isChecked;
                      widget.onChanged(_isChecked);
                    });

                    if (_isChecked) {
                      context.read<Profile>().logSet(
                        SetRecord.fromDateTime(
                          sessionID: context.read<ActiveWorkoutProvider>().sessionID!,
                          exerciseID: context.read<Profile>()
                            .exercises[context.read<ActiveWorkoutProvider>().activeDayIndex!][widget.exerciseIndex].exerciseID,
                          date: DateTime.now(),
                          numSets: 1,
                          reps: double.parse(widget.repsController.text),
                          weight: double.parse(widget.weightController.text),
                          rpe: double.parse(widget.rpeController.text),
                          historyNote: context.read<ActiveWorkoutProvider>().workoutNotesTEC[widget.exerciseIndex].text,
                        ),
                        useMetric: context.read<SettingsModel>().useMetric,
                      );
                      context.read<ActiveWorkoutProvider>().restStopwatch.reset();
                    }
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

  Widget _buildTextField(
    TextEditingController controller,
    FocusNode focusNode,
    String hint,
    double width,
    bool hasError,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          filled: true,
          fillColor: hasError ? Colors.red.withAlpha(64) : null,
          contentPadding: const EdgeInsets.only(bottom: 10, left: 8),
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: 30,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
          hintText: hint,
          errorStyle: const TextStyle(height: 0),
        ),
        onChanged: (value) => _clearErrors(),
      ),
    );
  }
}