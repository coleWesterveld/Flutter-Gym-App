// analyitcs page
// not updated
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// overall goal of this page:
// metrics for motivation/acccountability
// insights into effective excercises or routines 
// (effectiveness measured by increased strength, or other metric)
// fun for workout and data geeks :)


// maybe cool idea: allow easy export as CSV
// goal is to have analytics on a few things, namely: 
// DOTS or other powerlifting scoring scores based off of SBD and bodyweight
// bodyweight
// estimated 1RM in lift of choice**
// training frequency by month/week or some kind of volume tracker?
// maybe something to do a spotify wrapped type thing
// should clearly show markers like stocks do or something ie. ^5% 
// show gains for this week and then long term
// maybe good to have a smart feature which puts graphs that are important at the top automatically
//  important could be "progressing exceptionally well/poorly"

// for this, I may need to adjust my approach that I am taking currently: 
// I may need a list of all excercises possible, otherwise for example:
// "Dumbbell Press" would be different to "dumbbell press" to "dumbbell chest press"
// which proably mean all the same thing


Color darken(Color c, [int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    var f = 1 - percent / 100;
    return Color.fromARGB(
        c.alpha,
        (c.red * f).round(),
        (c.green  * f).round(),
        (c.blue * f).round()
    );
}

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {

  // these should be taken from database
  final List<FlSpot> dataPoints = const [
    FlSpot(0, 50),
    FlSpot(1, 52),
    FlSpot(2, 64),
    FlSpot(3, 65),
    FlSpot(4, 70),
    FlSpot(5, 72),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e2025),
        centerTitle: true,
        title: const Text(
          "Analytics",
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
          ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SearchBar(
                hintText: "Search excercise",

                onTapOutside:(event) => WidgetsBinding.instance.focusManager.primaryFocus?.unfocus(),
                constraints: BoxConstraints(
                  minHeight: 40, // Set the minimum height
                  maxHeight: 40, // Set the maximum height
                ),

                backgroundColor: WidgetStateProperty.all( Color(0xFF1e2025)),
                leading: Icon(Icons.search, color: Color(0xFFdee3e5)),
              ),
            ),

            const Center(
              child: Text(
                "Example Graph",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900
                )
              )
            ),

            SizedBox(
              height: 300,
              width: double.infinity,
              child: LineChart(
                
                
                LineChartData(
                  
                  lineBarsData: [
                    LineChartBarData(
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Color(0xFF1e2025),
                            strokeColor: Colors.blue,
                            strokeWidth: 2,
                          );
                        },
                      ),
            
                      spots: dataPoints,
                      isCurved: false,
                      color: Colors.blue,
                      barWidth: 4,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withAlpha(75),
                      ),
                      //dotData: FlDotData(show: false),
                    ),
                  ],
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.grey),
                      bottom: BorderSide(color: Colors.grey),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 10,
                        getTitlesWidget: (value, _) => Text(
                          '${value.toInt()} kg',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                          return Text(
                            labels[value.toInt()],
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ),
                  ),
                  minX: 0,
                  maxX: 5,
                  minY: 40,
                  maxY: 80,
                ),
              ),
            ),

            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Color(0xFF1e2025),  
              ),

              
              //height: 200,
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Text("This Week")
                    ),

                    Column(children: [
                      // good start make it look better and needs more metrics in the week view but overall good
                      // maybe have an arrow for each excercise to take the user to see the full graph
                      Row(children:[Text("Bench Press"), Icon(Icons.arrow_drop_up, color: Colors.green), Text("+5lbs")]),
                      Row(children:[Text("Deadlifts"), Icon(Icons.arrow_drop_down, color: Colors.red), Text("-2.5lbs")]),
                      Row(children:[Text("Squats"), Icon(Icons.arrow_drop_up, color: Colors.green), Text("+2.5lbs")])

                    
                    ],)

                  ],
                )
              )
            ),

          ],
        ),
      ),
    );
  }
}


