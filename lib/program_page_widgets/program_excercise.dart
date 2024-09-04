/// each card with an excercise
/// 
library;
import 'package:flutter/material.dart';


class ProgramExcercise extends StatefulWidget {
  
  ProgramExcercise({
    super.key,
    required this.name,
    //required this.n,
    required this.excercises,
  });

  final String name;
  List<String> excercises;

  @override
  State<ProgramExcercise> createState() => _ProgramExcerciseState();
}

class _ProgramExcerciseState extends State<ProgramExcercise> {
  //final int n;
  TextEditingController yourController = TextEditingController();
  List<String> excercises = [];
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Card(
        child: Padding(
        padding: const EdgeInsets.only(
            top: 8, left: 8.0, right: 8.0, bottom: 8.0),
            child: ExpansionTile(
            title: TextFormField(
              controller: yourController,
              onChanged: (text) {
                excercises.add(yourController.text);
              },
            
            style: const TextStyle(
              fontSize: 15,
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              hintStyle: TextStyle(
                fontSize: 15,
              ),
              hintText: 'Day 1',
              
            ),
          ),
              children: [
                for (int exc = 0; exc < widget.excercises.length; exc++)ExpansionTile(
                title: Text(
                  widget.excercises[exc],
                  style: const TextStyle(
                    fontSize: 14
                  ),
                  ),
              children: const <Widget>[
              
              Text('No belt, 0 RIR all sets. no safeties, thats for babies'),
              
            ],
          ),]
          ),
        ),
      ),
    );
  }
}


class ExcerciseListView extends StatelessWidget {
  final List<ProgramExcercise> excercise_list = [
    ProgramExcercise(name: 'Legs', excercises: const ['squat', 'bench']),
    ProgramExcercise(name: 'Push', excercises: const ['sumo', 'deadlift']),
    ProgramExcercise(name: 'Pull', excercises: const ['run', 'walk']),
  ];

  ExcerciseListView({super.key});
  

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: excercise_list,
      

    );
  }
}
