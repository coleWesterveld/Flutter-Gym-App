// analyitcs page
// not updated
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
          ],
        ),
      ),
    );
  }
}