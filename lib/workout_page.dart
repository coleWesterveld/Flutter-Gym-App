import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'user.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'data_saving.dart';

class Workout extends StatefulWidget {
  const Workout({super.key});

  @override
  State<Workout> createState() => _WorkoutState();
}

class _WorkoutState extends State<Workout> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e2025),
        centerTitle: true,
        title: const Text(
          "Workout2",
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
          ),
      ),
      body: const Center(
        child: Column(
          children: [
            Text("Workout Page"),
            // BackButton(
      
            //   onPressed: (){
            //     Navigator.pop(context);
            //   },
            // ),
      
          ],
        )),
    );
  }
}