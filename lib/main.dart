// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
//import 'package:google_fonts/google_fonts.dart';//

/// Flutter code sample for [NavigationBar].

void main() => runApp( NavigationBarApp());

class NavigationBarApp extends StatelessWidget {
  NavigationBarApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      )),
      //theme: ThemeData(useMaterial3: false),s
      home: NavigationExample(),
    );
  }
}

class NavigationExample extends StatefulWidget {
  NavigationExample({super.key});
  
  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    var list = ['Legs', 'Push', 'Pull'];
    var excercises = ['Squats 3x2','Deadlifts 4x2', 'Calf Raises 5x3'];
    return Scaffold(
      resizeToAvoidBottomInset : false,
      
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.deepPurple,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
          Radius.circular(12),
          ),
        ),
        //indicatorShape:  RoundedRectangleBorder(BorderSide side = BorderSide.none, borderRadius = BorderRadius.zero),
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.fitness_center),
            icon: Icon(Icons.fitness_center_outlined),
            label: 'Workout',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.calendar_month),
            icon: Badge(child: Icon(Icons.calendar_month_outlined)),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.now_widgets_outlined),
            selectedIcon: Icon(Icons.now_widgets),
            label: 'Program',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
      body: <Widget>[
        /// Notifications page
        
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              // Card(
              //   child: Padding(
              //   padding: EdgeInsets.only(
              //       top: 36.0, left: 6.0, right: 6.0, bottom: 6.0),
              //       child: ExpansionTile(
              //       title: Text('Excercise 1'),
              //         children: <TextBox>[
              //         TextBox.fromLTRBD(
              //           100,
              //           100,
              //           100,
              //           100,
              //           TextDirection.ltr,
              //         ),
              //         //Text('Birth of the Sun'),
              //         Text('Earth is Born'),
              //       ],
              //     ),
              //   ),
              // ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.notifications_sharp),
                  title: Text('Notification 2'),
                  subtitle: Text('This is a notification'),
                ),
              ),
              Card(
                color: const Color.fromARGB(179, 86, 86, 86),
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: const Text(
                          textAlign: TextAlign.left,
                          'Squats',
                          style: TextStyle(height: 1.5, fontSize : 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      for (int z = 0; z < 4; z++)
                      Row(
                        //verticalDirection: VerticalDirection,
                        children: [
                          Expanded(
                            child: ListTile(
                        title: const Text('Weight'),
                        subtitle: TextFormField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8))),
                                hintText: '80kg', //This should be made to be whateever this value was last workout
                              ),
                            ),),
                          ),
                          // SizedBox(
                          //   width: 1,
                          // ),
                          const Icon(
                            Icons.close,
                          ),
                          Expanded(
                            child:ListTile(
                        title: const Text('Reps'),
                        subtitle:  TextFormField(
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8))),
                                hintText: '7',
                              ),
                            ),),
                          ),
                        ],
                      ),
                      SizedBox(
                            width: double.infinity,
                            child:ListTile(
                              title: const Text('Notes'),
                              subtitle:  SizedBox(
                                height: 100,
                                child: TextFormField(
                                  //expands: true,
                                  maxLines: null,
                                  textInputAction: TextInputAction.done,
                                  keyboardType: TextInputType.text,
                                  //keyboardType: TextInputType.multiline,
                                  decoration: const InputDecoration(
                                    //filled: true, 
                                    hintText: 'Comments',
                                    border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8))),
                                  ),
                            ),
                          ),
                        )
                        ),
                      

                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      //   children: [
                      //     TextField(
                      //       decoration: InputDecoration(
                      //         border: OutlineInputBorder(),
                      //         hintText: 'Weight'
                      //       ),
                      //     ),

                      //     TextField(
                      //       decoration: InputDecoration(
                      //         border: OutlineInputBorder(),
                      //         hintText: 'Reps'
                      //       ),
                      //     ),

                      //   ],
                      // ),
                    ]
                  ),
                ),
              ),
              
            ],
          ),
        ),

        /// Home page
        Card(
          shadowColor: Colors.transparent,
          margin: const EdgeInsets.all(8.0),
          child: SizedBox.expand(
            child: Center(
              child: Text(
                'Home page',
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
        ),

        

        /// Program page
        Column(
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
                    title: Text(list[n]),
                      children: [
                        for (int exc = 0; exc < excercises.length; exc++)ExpansionTile(
                        title: Text(excercises[exc]),
                      children: <Widget>[
                      
                      Text('No belt, 0 RIR all sets. no safeties, thats for babies'),
                      
                    ],
                  ),]
                  ),
                ),
              ),
            ),
          ],
        ),

        ListView.builder(
          reverse: true,
          itemCount: 2,
          itemBuilder: (BuildContext context, int index) {
            if (index == 1) {
              return Align(
                alignment: Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    'Hello',
                    style: theme.textTheme.bodyLarge!
                        .copyWith(color: theme.colorScheme.onPrimary),
                  ),
                ),
              );
            }
            return Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(8.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Hi!',
                  style: theme.textTheme.bodyLarge!
                      .copyWith(color: theme.colorScheme.onPrimary),
                ),
              ),
            );
          },
        ),
      ][currentPageIndex],
    );
  }
}