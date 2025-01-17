import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../user.dart';

class Workout extends StatefulWidget {
  const Workout({super.key});

  @override
  State<Workout> createState() => _WorkoutState();
}

class _WorkoutState extends State<Workout> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) => context.read<Profile>().setActiveDay(null),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1e2025),
          centerTitle: true,
          title: Text(
            context.read<Profile>().activeDay?.dayTitle ?? "titleError",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: Center(
            child: _buildList()),
      ),
    );
  }

  Widget _buildList() {

    //stump for now
    return Text("workout");

    // activeDay 
    // return ListView.builder(
    //   itemCount: context.watch<Profile>()exercises[activeDayInde],
    //   itemBuilder: itemBuilder
    //   );
  }
}
