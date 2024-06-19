/// each card with an excercise
/// 
import 'package:flutter/material.dart';


class ProgramExcercise extends StatelessWidget {
  
  const ProgramExcercise({
    super.key,
    required this.name,
    //required this.n,
    required this.excercises,
  });

  final String name;
  //final int n;
  final List<String> excercises;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8, left: 8, right: 8),
      child: Card(
        child: Padding(
        padding: EdgeInsets.only(
            top: 8, left: 8.0, right: 8.0, bottom: 8.0),
            child: ExpansionTile(
            title: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                fontSize: 18,
              )
            ),
              children: [
                for (int exc = 0; exc < excercises.length; exc++)ExpansionTile(
                title: Text(
                  excercises[exc],
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
    ProgramExcercise(name: 'day1', excercises: ['squat', 'bench']),
    ProgramExcercise(name: 'day2', excercises: ['sumo', 'deadlift']),
    ProgramExcercise(name: 'day3', excercises: ['run', 'walk']),
  ];
  

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: excercise_list,

    );
  }
}
