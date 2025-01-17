// analyitcs page
// not updated
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import "../user.dart";
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
// overall goal of this page:
// metrics for motivation/acccountability
// insights into effective exercises or routines 
// (effectiveness measured by increased strength, or other metric)
// fun for workout and data geeks :)

// To continue I should add mock history to plot and test

// allow users to see graphs by search, or pin graphs or goals
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
// I may need a list of all exercises possible, otherwise for example:
// "Dumbbell Press" would be different to "dumbbell press" to "dumbbell chest press"
// which proably mean all the same thing
Color lighten(Color c, [int percent = 10]) {
  // not very fond of this solution, it seems to work though. 
  // will have to migrate from previous solution as colors is moving from 0-255 to 0-1
  assert(1 <= percent && percent <= 100);
  var p = percent / 100;
  return Color.lerp(
  c, Colors.white, p
  )!;
      
}

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

    final List<Map<String, dynamic>> _goals = [
    {'title': 'Bench Press', 'current': 275, 'goal': 315},
  ];

  void _addGoal() {
    setState(() {
      _goals.add({'title': 'New Goal', 'current': 0, 'goal': 100});
    });
  }
  
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

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
        
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SearchBar(
                  hintText: "Search exercise",
        
                  onTapOutside:(event) => WidgetsBinding.instance.focusManager.primaryFocus?.unfocus(),
                  constraints: BoxConstraints(
                    minHeight: 40, // Set the minimum height
                    maxHeight: 40, // Set the maximum height
                  ),
        
                  backgroundColor: WidgetStateProperty.all( Color(0xFF1e2025)),
                  leading: Icon(Icons.search, color: Color(0xFFdee3e5)),
                ),
              ),
        
              // const Center(
              //   child: Text(
              //     "Example Graph",
              //     style: TextStyle(
              //       fontSize: 20,
              //       fontWeight: FontWeight.w900
              //     )
              //   )
              // ),
        
              // SizedBox(
              //   height: 200,
              //   width: double.infinity,
              //   child: LineChart(
                  
                  
              //     LineChartData(
                    
              //       lineBarsData: [
              //         LineChartBarData(
              //           dotData: FlDotData(
              //             show: true,
              //             getDotPainter: (spot, percent, barData, index) {
              //               return FlDotCirclePainter(
              //                 radius: 4,
              //                 color: Color(0xFF1e2025),
              //                 strokeColor: Colors.blue,
              //                 strokeWidth: 2,
              //               );
              //             },
              //           ),
              
              //           spots: dataPoints,
              //           isCurved: false,
              //           color: Colors.blue,
              //           barWidth: 4,
              //           belowBarData: BarAreaData(
              //             show: true,
              //             color: Colors.blue.withAlpha(75),
              //           ),
              //           //dotData: FlDotData(show: false),
              //         ),
              //       ],
              //       gridData: FlGridData(show: true),
              //       borderData: FlBorderData(
              //         show: true,
              //         border: const Border(
              //           left: BorderSide(color: Colors.grey),
              //           bottom: BorderSide(color: Colors.grey),
              //         ),
              //       ),
              //       titlesData: FlTitlesData(
              //         leftTitles: AxisTitles(
              //           sideTitles: SideTitles(
              //             showTitles: true,
              //             reservedSize: 40,
              //             interval: 10,
              //             getTitlesWidget: (value, _) => Text(
              //               '${value.toInt()} kg',
              //               style: const TextStyle(fontSize: 12),
              //             ),
              //           ),
              //         ),
              //         bottomTitles: AxisTitles(
              //           sideTitles: SideTitles(
              //             showTitles: true,
              //             interval: 1,
              //             getTitlesWidget: (value, _) {
              //               final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
              //               return Text(
              //                 labels[value.toInt()],
              //                 style: const TextStyle(fontSize: 12),
              //               );
              //             },
              //           ),
              //         ),
              //       ),
              //       minX: 0,
              //       maxX: 5,
              //       minY: 40,
              //       maxY: 80,
              //     ),
              //   ),
              // ),
        
              Container(
                height: 325,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Color(0xFF1e2025),  
                ),
        
                
                //height: 200,
                child:  const Align( // this will not stay const 
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            // TODO: instead of current scroll, each card shoudl take fill page and there should be dot tab indiators on bottom
                            "This Week",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                       Expanded(child: PageViewWithIndicator()),
        
                      // Expanded(
                      //   child: Padding(
                      //     padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                      //     child: Row(
                      //       children: [
                      //         Align(
                      //           alignment: Alignment.centerLeft,
                      //           child: Icon(Icons.arrow_back_ios),
                      //         ),
                          
                      //         Expanded(
                      //           child: ListView.builder(
                      //             scrollDirection: Axis.horizontal,
                      //             itemCount: context.read<Profile>().split.length,
                      //             itemBuilder: (context, index) {
                      //               return DayProgress(index: index);
                      //             }
                                
                      //           ),
                      //         ),
                          
                      //         Icon(Icons.arrow_forward_ios)
                      //       ],
                      //     ),
                      //   ),
                      // ),
              
                      
                      
                      // Column(children: [
                      //   // good start make it look better and needs more metrics in the week view but overall good
                      //   // maybe have an arrow for each exercise to take the user to see the full graph
                      //   Row(children:[Text("Bench Press"), Icon(Icons.arrow_drop_up, color: Colors.green), Text("+5lbs")]),
                      //   Row(children:[Text("Deadlifts"), Icon(Icons.arrow_drop_down, color: Colors.red), Text("-2.5lbs")]),
                      //   Row(children:[Text("Squats"), Icon(Icons.arrow_drop_up, color: Colors.green), Text("+2.5lbs")])
        
                      
                      // ],)
        
        
        
                    ],
                  )
                )
              ),
        
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  //height: 325,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFF1e2025),  
                  ),
                        
                  
                  //height: 200,
                  child: Align( // this will not stay const 
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0 ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Goals",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ButtonTheme(
                                    minWidth: 100,
                                    //height: 130,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        _addGoal();
                                      },
                                    
                                      style: ButtonStyle(
                                        //when clicked, it splashes a lighter purple to show that button was clicked
                                        shape: WidgetStateProperty.all(RoundedRectangleBorder(
                                
                                          borderRadius: BorderRadius.circular(12))),
                                        backgroundColor: WidgetStateProperty.all(Color(0XFF1A78EB),), 
                                        overlayColor: WidgetStateProperty. resolveWith<Color?>((states) {
                                          if (states.contains(WidgetState.pressed)) return Color(0XFF1A78EB);
                                          return null;
                                        }),
                                      ),
                                      
                                      label: 
                                          const Text(
                            
                                            "Add Goal",
                                            style: TextStyle(
                                                color: Color.fromARGB(255, 255, 255, 255),
                                                //fontSize: 18,
                                                //fontWeight: FontWeight.w800,
                                              ),
                                          ),
                                        
                                      
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            //alignment: WrapAlignment.start,
                            children: _buildGoalList(),
                          ),
                        ),
                        
                      ],
                    )
                  )
                ),
              ),
        
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildGoalList() {
    //debugPrint('${(MediaQuery.sizeOf(context).width - 48)/2}');
    List<Widget> goalList = [];
    for (var goal in _goals){
      goalList.add(
        Padding(
          padding: const EdgeInsets.only(left:  8.0, right: 8.0, bottom: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                // goal has title, current, goal
                    "${goal['title']}",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: lighten(Color(0xFF1e2025), 10),
                ),
                
                
                // TODO: currently the conainer resizes, but the child does not, this must be fixed or it will overlap on smaller screens
                width:  (MediaQuery.sizeOf(context).width - 48)/2,
                //height: 250,
                // TODO: make customzeable
                // right now this is a mockup but I need values to be able to be added
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: GoalProgress(
                    current: goal['current'],
                    goal: goal['goal']
                  ),
                ),
                            
              ),
            ],
          ),
        ),
      );
    }

    return goalList;
     
  }
}

class GoalProgress extends StatefulWidget {
  const GoalProgress({
    super.key,
    required this.current,
    required this.goal
  });
  final int current;
  final int goal;

  @override
  State<GoalProgress> createState() => _GoalProgressState();
}

class _GoalProgressState extends State<GoalProgress> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      //color: Colors.red,
      height: 175,
      width: 175,
      child: Stack(
        children: [
            Center(
              child: ThickCircularProgress(
                progress: widget.current/widget.goal, // Example progress (75%)
                completedStrokeWidth: 25.0,
                backgroundStrokeWidth: 18.0,
                completedColor: Color(0XFF1A78EB),
                backgroundColor: lighten(Color(0xFF1e2025), 20),
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Actual',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFF1A78EB),
                  ),
                ),
                                
                const SizedBox(height: 5),
                
                Text(
                  '${widget.current} lbs',
                  textHeightBehavior: TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                                
                const Divider(
                  height: 5,
                  color: Colors.grey, // Line color
                  thickness: 2.0,    // Line thickness
                  indent: 60.0,      // Left padding
                  endIndent: 60.0,   // Right padding
                ),
                                
                Text(
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                                
                  '${widget.goal} lbs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Goal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFF1A78EB),
                  ),
                ),
                                
                                
                
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DayProgress extends StatefulWidget {
  DayProgress({
    super.key,
    required this.index,
  });

  final int index;

  @override
  State<DayProgress> createState() => _DayProgressState();
}

class _DayProgressState extends State<DayProgress> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: lighten(Color(0xFF1e2025), 10),
        ),
        
        
      
        width: 200,
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 300,
                    ),

                    child: Text(
                      context.read<Profile>().split[widget.index].dayTitle,

                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      maxLines: 2,

                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),


                  // TODO: this should be read from database as actual date
                  Text("Mon, 13/01")
                ],
              ),
            

            Expanded(
              child: ListView.builder(
              
                  itemCount: context.read<Profile>().exercises[widget.index].length,
                  itemBuilder: (context, exerciseIndex) {
                    return Container(
                      
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(1)),
                        border: Border(bottom: BorderSide(color: lighten(Color(0xFF1e2025), 30)/*Theme.of(context).dividerColor*/, width: 0.5),),
                      ),

                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 300,
                                ),
                              
                                child: Text(
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: true,
                                  maxLines: 2,
                                  context.read<Profile>().exercises[widget.index][exerciseIndex].exerciseTitle,
                                ),
                              ),
                            ),
                        
                            Row(
                              children:[
                                buildTick(), 
                                  
                                Text("5lbs")
                              ]
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  
                ),
            ),
            ],
          ),
        )
                    
      ),
    );
  }

  Icon buildTick() {
    // random for mock for now but will eventually be based off of real data
    int random = Random().nextInt(3);
    const List<Color> colors = [Colors.red, Colors.green, Colors.grey];
    const List<IconData> icons = [Icons.arrow_drop_down, Icons.arrow_drop_up, Icons.remove];
    
    return Icon(
      icons[random], 
      color: colors[random],
    );
  }
}



class PageViewWithIndicator extends StatefulWidget {
  const PageViewWithIndicator({super.key});

  @override
  _PageViewWithIndicatorState createState() => _PageViewWithIndicatorState();
}

class _PageViewWithIndicatorState extends State<PageViewWithIndicator> {
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: context.read<Profile>().split.length,
            itemBuilder: (context, index) {
              return DayProgress(index: index);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SmoothPageIndicator(
            controller: _pageController,
            count: context.read<Profile>().split.length,
            effect: const ExpandingDotsEffect(
              dotHeight: 8.0,
              dotWidth: 8.0,
              activeDotColor: Colors.blue,
              dotColor: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

// cant even lie this whole class was written by ChatGPT
// I wanted to have the circular progress indicator more customizeable
// specifically, I can make the progressed part thicker than the non completed part
class ThickCircularProgress extends StatelessWidget {
  final double progress; // Progress as a value between 0 and 1
  final double completedStrokeWidth;
  final double backgroundStrokeWidth;
  final Color completedColor;
  final Color backgroundColor;

  const ThickCircularProgress({
    required this.progress,
    this.completedStrokeWidth = 10.0,
    this.backgroundStrokeWidth = 4.0,
    this.completedColor = Colors.blue,
    this.backgroundColor = Colors.grey,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(150, 150), // Adjust the size as needed
      painter: CircularProgressPainter(
        progress: progress,
        completedStrokeWidth: completedStrokeWidth,
        backgroundStrokeWidth: backgroundStrokeWidth,
        completedColor: completedColor,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double completedStrokeWidth;
  final double backgroundStrokeWidth;
  final Color completedColor;
  final Color backgroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.completedStrokeWidth,
    required this.backgroundStrokeWidth,
    required this.completedColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw the background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = backgroundStrokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw the completed arc
    final completedPaint = Paint()
      ..color = completedColor
      ..strokeWidth = completedStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Optional: Rounded ends
    final sweepAngle = progress * 2 * 3.14159265359;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159265359 / 2, // Start angle (top of the circle)
      sweepAngle,
      false,
      completedPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}