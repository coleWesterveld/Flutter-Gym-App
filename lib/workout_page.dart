// workout page
//not updated
import 'package:flutter/material.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({
    super.key,
  });

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}