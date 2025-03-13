import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../other_utilities/lightness.dart';

class GymSetRow extends StatefulWidget {
  final double prevWeight;
  final int prevReps;
  final double expectedWeight;
  final int expectedReps;
  final double expectedRPE;

  const GymSetRow({
    Key? key,
    required this.prevWeight,
    required this.prevReps,
    required this.expectedWeight,
    required this.expectedReps,
    required this.expectedRPE,
  }) : super(key: key);

  @override
  _GymSetRowState createState() => _GymSetRowState();
}

class _GymSetRowState extends State<GymSetRow> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
  final TextEditingController rpeController = TextEditingController();
  bool isLogged = false;
  bool showPrevious = false;
  bool isChecked = false;

  @override
  void dispose() {
    weightController.dispose();
    repsController.dispose();
    rpeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isChecked ? Colors.blue.withAlpha(100) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
      
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "${205}kg x ${2} @ 7 RPE",
                style: TextStyle(
                  fontSize: 16,
                ),
                ),
            ),
      
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextFormField(
                //controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF1e2025),
                  contentPadding: EdgeInsets.only(bottom: 10, left: 8),
                  constraints: BoxConstraints(
                    maxWidth: 30,
                    maxHeight: 30,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  hintText: "8",
                ),
              ),
            ),
      
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextFormField(
                //controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF1e2025),
                  contentPadding: EdgeInsets.only(bottom: 10, left: 8),
                  constraints: BoxConstraints(
                    maxWidth: 50,
                    maxHeight: 30,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  hintText: "8",
                ),
              ),
            ),
      
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextFormField(
                //controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF1e2025),
                  contentPadding: EdgeInsets.only(bottom: 10, left: 8),
                  constraints: BoxConstraints(
                    maxWidth: 40,
                    maxHeight: 30,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  hintText: "8",
                ),
              ),
            ),
      
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: InkWell(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  // Toggle your isChecked state here, e.g.,
                  setState(() { isChecked = !isChecked; });
                },
                child: Container(
                  width: 24.0,
                  height: 24.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isChecked ? Colors.blue : Colors.grey, width: 2),
                  ),
                  child: Center(
                          child: Icon(
                            Icons.check,
                            size: 16.0,
                            color: isChecked ? Colors.blue : Colors.grey,
                          ),
                        ),
                ),
              ),
            )
      
          ],
        ),
      ),
    );
  }
}
