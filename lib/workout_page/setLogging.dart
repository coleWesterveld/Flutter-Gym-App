import 'package:flutter/material.dart';

class GymSetRow extends StatefulWidget {
  final double prevWeight;
  final int prevReps;
  final double expectedRPE;

  const GymSetRow({
    Key? key,
    required this.prevWeight,
    required this.prevReps,
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

  @override
  void dispose() {
    weightController.dispose();
    repsController.dispose();
    rpeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous weight and reps
        Column(
          children: [
            Text("Last: ${widget.prevWeight}kg"),
            Text("${widget.prevReps} reps"),
          ],
        ),
        // Weight input
        SizedBox(
          width: 50,
          child: TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Kg"),
          ),
        ),
        // Reps input
        SizedBox(
          width: 40,
          child: TextField(
            controller: repsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Reps"),
          ),
        ),
        // Actual RPE input
        SizedBox(
          width: 40,
          child: TextField(
            controller: rpeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "RPE"),
          ),
        ),
        // Expected RPE
        Text("Exp: ${widget.expectedRPE.toStringAsFixed(1)}"),
        // Checkbox
        Checkbox(
          value: isLogged,
          onChanged: (bool? value) {
            setState(() {
              isLogged = value ?? false;
            });
          },
        ),
      ],
    );
  }
}
