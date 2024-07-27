/// each card with an excercise
/// 
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
      padding: EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Card(
        child: Padding(
        padding: EdgeInsets.only(
            top: 8, left: 8.0, right: 8.0, bottom: 8.0),
            child: ExpansionTile(
            title: TextFormField(
              controller: yourController,
              onChanged: (text) {
                excercises.add(yourController.text);
              },
            
            style: TextStyle(
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
                  style: TextStyle(
                    fontSize: 14
                  ),
                  ),
              children: <Widget>[
              
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
    ProgramExcercise(name: 'Legs', excercises: ['squat', 'bench']),
    ProgramExcercise(name: 'Push', excercises: ['sumo', 'deadlift']),
    ProgramExcercise(name: 'Pull', excercises: ['run', 'walk']),
  ];
  

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: excercise_list,
      

    );
  }
}
