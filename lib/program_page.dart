// program page
import 'package:flutter/material.dart';
import 'program_page_widgets/program_excercise.dart';

class ProgramPage extends StatelessWidget {
  const ProgramPage({
    super.key,
    required this.list,
    required this.excercises,
  });

  final List<String> list;
  final List<String> excercises;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 68, left: 8, right: 8),
          child: Text(
            "PPL Split",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
              ),
            textScaler: TextScaler.linear(2),
          ),
        ),
        ExcerciseListView(),
      ],
    );
    
  }
}

