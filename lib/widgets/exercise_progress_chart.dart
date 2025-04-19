import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class ExerciseProgressChart extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final ThemeData theme;

  const ExerciseProgressChart({
    super.key, 
    required this.exercise,
    required this.theme,
  });

  @override
  _ExerciseProgressChartState createState() => _ExerciseProgressChartState();
}

class _ExerciseProgressChartState extends State<ExerciseProgressChart> {
  List<FlSpot> _dataPoints = [];
  List<String> _dates = [];


  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final dbHelper = DatabaseHelper.instance;
    final records = await dbHelper.fetchSetRecords(exerciseId: widget.exercise['exercise_id']);

    List<FlSpot> points = [];
    List<String> dates = [];

    // Reverse the order to make the oldest record the first X value
    for (int i = records.length - 1; i >= 0; i--) {
      final record = records[i];
      DateTime date = DateTime.parse(record['date']);
      double weight = record['weight'].toDouble();
      int reps = record['reps'] + (10-record['rpe']);
      
      // Epley formula for estimated 1RM
      int e1RM = (weight * (1 + reps / 30)).round();

      points.add(FlSpot((records.length - 1 - i).toDouble(), e1RM.toDouble()));
      dates.add(DateFormat('MMM d').format(date)); // Format date for X-axis
    }

    setState(() {
      _dataPoints = points;
      _dates = dates;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _dataPoints.isEmpty
        ? const Center(child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "No history found for this exercise."
            ),
        ))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  widget.exercise['exercise_title'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(
                          
                          sideTitles: SideTitles(
                            minIncluded: false,
                            maxIncluded: false,
                            showTitles: true,
                            reservedSize: 40, // Space for label
                          ),
                          
                          axisNameSize: 22, // Adjust spacing for clarity
                        ),

                        leftTitles: AxisTitles(
                          
                          sideTitles: SideTitles(
                            minIncluded: false,
                            maxIncluded: false,
                            showTitles: true,
                            reservedSize: 40, // Space for label
                          ),
                          axisNameWidget: const Text(
                            'Predicted 1RM (lbs)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          axisNameSize: 22, // Adjust spacing for clarity
                        ),
                        bottomTitles: AxisTitles(

                          sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index % 3 == 0 && index >= 0 && index < _dates.length) { 
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(_dates[index], style: const TextStyle(fontSize: 10)),
                              );
                            }
                            return Container(); // Hide labels that don’t meet the condition
                          },
                          interval: 1, // Keep interval 1 so the graph still renders all points
                        ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      gridData: FlGridData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _dataPoints,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
