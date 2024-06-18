// program page
import 'package:flutter/material.dart';

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
        for (int n =0; n < list.length; n++)
        Padding(
          padding: EdgeInsets.only(top: 8, left: 8, right: 8),
          child: Card(
            child: Padding(
            padding: EdgeInsets.only(
                top: 8, left: 8.0, right: 8.0, bottom: 8.0),
                child: ExpansionTile(
                title: Text(
                  list[n],
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
        ),
      ],
    );
  }
}