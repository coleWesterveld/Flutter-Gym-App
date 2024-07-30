// program page
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
//import 'program_page_widgets/program_excercise.dart';


// import 'package:flutter/material.dart';

// void main() => runApp(new MaterialApp(home: MyList()));

class ProgramPage extends StatefulWidget {
  @override
  _MyListState createState() => _MyListState();
}

class _MyListState extends State<ProgramPage> {
  int value = 0;
  List<TextEditingController> splitDaysTEC = [TextEditingController(), TextEditingController(), TextEditingController()];//TextEditingController();
  List<String> split = ["Push", "Pull", "Legs"];
  _addItem() {
    setState(() {
      value = value + 1;
      splitDaysTEC.add(TextEditingController());
      split.add("New Day");
      print(split.toString());
      //print(splitDaysTEC.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
              //controller: splitDaysTEC,
  
            
            style: TextStyle(
              fontSize: 20,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              hintStyle: TextStyle(
                fontSize: 15,
              ),
              hintText: "Program Title",
              
            ),
          ),
      ),
      body: ListView.builder(
          itemCount: split.length,
          itemBuilder: (context, index) {
    //print(index.toString());
    //print(splitDaysTEC.length);
        return Card(
            child: Padding(
            padding: EdgeInsets.only(
                top: 8, left: 8.0, right: 8.0, bottom: 8.0),
                child: ExpansionTile(
                title: 
                Row(
                        //verticalDirection: VerticalDirection,
                        children: [
                          Expanded(
                            child: ListTile(
                        title: TextFormField(
                              controller: splitDaysTEC[index],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8))),
                                hintText: split[index],
                              ),
                            ),),
                          ),
                          // SizedBox(
                          //   width: 1,
                          // ),
                          IconButton(onPressed: () {
                            setState( () {
                              split[index] = (splitDaysTEC[index].text);
                              FocusManager.instance.primaryFocus?.unfocus();
                          });
                          }, icon: Icon(Icons.check)),

                          IconButton(onPressed: () {
                            setState( () {
                              value = value - 1;
                              split.removeAt(index);
                              splitDaysTEC.removeAt(index);
                          });
                          }, icon: Icon(Icons.delete)),
                        ],
                      ),

                  children: [
                    for (int exc = 0; exc < 3; exc++)ExpansionTile(
                    title: Text(
                      "runnerok",
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
          );
    },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: Icon(Icons.add),
      ),
    );
  }
}
//Text("Item " + index.toString())




// class ProgramPage extends StatelessWidget {
//   const ProgramPage({
//     super.key,
//     required this.list,
//     required this.excercises,
//   });

//   final List<String> list;
//   final List<String> excercises;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Padding(
//           padding: EdgeInsets.only(top: 68, left: 8, right: 8),
//           child: TextFormField(
//             style: TextStyle(
//               fontSize: 25,
//             ),
//             decoration: const InputDecoration(
//               border: OutlineInputBorder(
//                   borderRadius: BorderRadius.all(Radius.circular(8))),
//               hintStyle: TextStyle(
//                 fontSize: 25,
//               ),
//               hintText: 'Program Title',
              
//             ),
//           ),
//         ),
//         Expanded(
//           child: SizedBox(
//             height: 200.0,
//             child: ExcerciseListView(),
//             ),
//         ),
//         //FloatingActionButton(onPressed: onPressed)
        
//       ],
//     );
    
//   }
// }

