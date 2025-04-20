import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import 'package:firstapp/other_utilities/timespan.dart';
import 'package:firstapp/other_utilities/format_weekday.dart';


class ExerciseProgressChart extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final ThemeData theme;
  final Timespan selectedTimespan;
  final ValueChanged<Timespan>? onTimespanChanged;


  const ExerciseProgressChart({
    super.key, 
    required this.exercise,
    required this.theme,
    required this.selectedTimespan,
    this.onTimespanChanged,


  });

  @override
  _ExerciseProgressChartState createState() => _ExerciseProgressChartState();
}

class _ExerciseProgressChartState extends State<ExerciseProgressChart> {
  List<FlSpot> _dataPoints = [];
  List<String> _dates = [];
  List<String> _years = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(ExerciseProgressChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTimespan != widget.selectedTimespan) {
      // Refresh data when timespan changes
      _fetchData(); 
    }
  }

  Future<void> _fetchData() async {
    final dbHelper = DatabaseHelper.instance;
    final records = await dbHelper.fetchSetRecords(exerciseId: widget.exercise['exercise_id']);
    
    List<FlSpot> points = [];
    List<String> dates = [];

    // years for top labels
    List<String> years = [];

    if (records.isEmpty) {
      setState(() {
        points = [];
      });
      return;
    }

    final startDate = getStartDateForTimespan(widget.selectedTimespan);

    final filteredSets = records.where((set) {
      final setDate = DateTime.tryParse(set['date']);
      return setDate != null && setDate.isAfter(startDate);
    }).toList();

    // Reverse the order to make the oldest record the first X value
    for (int i = filteredSets.length - 1; i >= 0; i--) {
      final record = filteredSets[i];
      DateTime date = DateTime.parse(record['date']);
      double weight = record['weight'].toDouble();
      int reps = record['reps'] + (10-record['rpe']);
      
      // Epley formula for estimated 1RM
      int e1RM = (weight * (1 + reps / 30)).round();

      points.add(FlSpot((filteredSets.length - 1 - i).toDouble(), e1RM.toDouble()));
      dates.add(DateFormat('MMM d').format(date)); // Format date for X-axis
      years.add(DateFormat('yyyy').format(date)); // Store the year
    }

    setState(() {
      _dataPoints = points;
      _dates = dates;
      _years = years;
    });
  }

  @override
  Widget build(BuildContext context) {
    //debugPrint("datapoints.length: ${_dataPoints}");
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
                        rightTitles: const AxisTitles(
                          
                          sideTitles: SideTitles(
                            minIncluded: false,
                            maxIncluded: false,
                            showTitles: true,
                            reservedSize: 40, // Space for label
                          ),
                          
                          axisNameSize: 22, // Adjust spacing for clarity
                        ),

                        leftTitles: const AxisTitles(
                          
                          sideTitles: SideTitles(
                            minIncluded: false,
                            maxIncluded: false,
                            showTitles: true,
                            reservedSize: 40, // Space for label
                          ),
                          axisNameWidget: Text(
                            'Predicted 1RM (lbs)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          axisNameSize: 22, // Adjust spacing for clarity
                        ),

                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < _dates.length) {
                                // Show year only if it's the first point or year changed
                                if (index == 0 || 
                                    (index > 0 && _years[index] != _years[index - 1])) {
                                  return SideTitleWidget(
                                    meta: meta,
                                    child: Text(_years[index]),
                                  );
                                }
                              }
                              return const SizedBox.shrink(); // Hide other labels
                            },
                            interval: 1,
                        ),
                        ),
                        

                        bottomTitles: AxisTitles(

                          sideTitles: SideTitles(
                          reservedSize: 30,
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index % ((_dataPoints.length / 6).floor()) == 0 && index >= 0 && index < _dates.length) { 
                               //debugPrint("Runnnnn");
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(_dates[index], style: const TextStyle(fontSize: 14)),
                              );
                            }
                            return Container(); // Hide labels that don’t meet the condition
                          },
                          interval: 1, // Keep interval 1 so the graph still renders all points
                        ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((spot) {
                              final index = spot.x.toInt();
                              if (index >= 0 && index < _dates.length) {
                                return LineTooltipItem(
                                  '${spot.y.toStringAsFixed(1)} lbs\n${(_dates[index])} ${_years[index]}',
                                  const TextStyle(color: Colors.white),
                                );
                              }
                              return null;
                            }).toList();
                          },
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
                          belowBarData: BarAreaData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      "Timespan: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14
                      )
                    ),

                    DropdownButton<Timespan>(
                        value: widget.selectedTimespan,
                        onChanged: (Timespan? newValue) {
                          if (newValue != null) {
                            // This assumes you'll handle the state change in parent widget
                            // If managing state here, you'd use setState instead
                            widget.onTimespanChanged?.call(newValue);
                          }
                        },
                        items: Timespan.values.map((Timespan timespan) {
                          return DropdownMenuItem<Timespan>(
                            value: timespan,
                            child: Text(
                              timespan.displayName,
                              style: TextStyle(
                                color: widget.theme.colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ],
            ),
          );
  }
}
