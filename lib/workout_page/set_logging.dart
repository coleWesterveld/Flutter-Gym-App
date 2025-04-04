import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../other_utilities/lightness.dart';
import 'package:firstapp/user.dart';
import '../database/profile.dart';

class GymSetRow extends StatefulWidget {
  final double prevWeight;
  final int prevReps;
  final double expectedWeight;
  final int expectedReps;
  final double expectedRPE;
  final int exerciseIndex, setIndex;
  final Function(bool) onChanged;
  final  bool? initiallyChecked;

  const GymSetRow({
    super.key,
    required this.prevWeight,
    required this.prevReps,
    required this.expectedWeight,
    required this.expectedReps,
    required this.expectedRPE,
    required this.exerciseIndex,
    required this.setIndex,
    required this.onChanged,
    this.initiallyChecked,

  });

  @override
  _GymSetRowState createState() => _GymSetRowState();
}

class _GymSetRowState extends State<GymSetRow> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
  final TextEditingController rpeController = TextEditingController();

  final FocusNode weightFocus = FocusNode();
  final FocusNode repsFocus = FocusNode();
  final FocusNode rpeFocus = FocusNode();

  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    if (widget.initiallyChecked != null) _isChecked = widget.initiallyChecked!;

    // Add listeners to focus nodes
    weightFocus.addListener(_updateDoneState);
    repsFocus.addListener(_updateDoneState);
    rpeFocus.addListener(_updateDoneState);
  }

  void _updateDoneState() {
    bool anyFieldFocused = weightFocus.hasFocus || repsFocus.hasFocus || rpeFocus.hasFocus;
    context.read<Profile>().done = anyFieldFocused;
  }

  @override
  void dispose() {
    weightController.dispose();
    repsController.dispose();
    rpeController.dispose();

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

    assert (context.read<Profile>().sessionID != null, "SessionID is null, this... uhh... shouldnt happen.");
    assert(context.read<Profile>().activeDayIndex != null, "no active day index, this shouldnt happen.");
    assert(context.read<Profile>().activeDay != null, "no active day, this shouldnt happen.");

    return Container(
      decoration: BoxDecoration(
        color: _isChecked ? Colors.blue.withAlpha(100) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "${widget.prevWeight}kg x ${widget.prevReps} @ ${widget.expectedRPE} RPE",
                style: TextStyle(fontSize: 16),
              ),
            ),
            _buildTextField(rpeController, weightFocus, "Weight", 30),
            _buildTextField(weightController, repsFocus, "Reps", 50),
            _buildTextField(repsController, rpeFocus, "RPE", 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: InkWell(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  context.read<Profile>().incrementSet([widget.exerciseIndex, widget.setIndex]);
                  debugPrint("Next set: ${context.read<Profile>().nextSet}");
                  
                  setState(() {
                    _isChecked = !_isChecked;
                    widget.onChanged(_isChecked);
                  });

                  context.read<Profile>().logSet(
                    SetRecord.fromDateTime(
                    sessionID: context.read<Profile>().sessionID!, 
                    exerciseID: context.read<Profile>().exercises[
                      context.read<Profile>().activeDayIndex!
                    ][widget.exerciseIndex].exerciseID, 
                    date: DateTime.now(), 
                    numSets: 1, 
                    // maybe allow for floats at some point
                    reps: int.parse(repsController.text), 

                    weight: int.parse(weightController.text), 
                    rpe: int.parse(rpeController.text))
                  );


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
                    : null
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, FocusNode focusNode, String hint, double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode, // Attach focus node
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          filled: true,
          fillColor: Color(0xFF1e2025),
          contentPadding: EdgeInsets.only(bottom: 10, left: 8),
          constraints: BoxConstraints(
            maxWidth: width,
            maxHeight: 30,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          hintText: hint,
        ),
      ),
    );
  }
}
