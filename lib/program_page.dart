// program page
// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
//import 'program_page_widgets/program_excercise.dart';


// import 'package:flutter/material.dart';

// void main() => runApp(new MaterialApp(home: MyList()));

//program page, where user defines the overall program by days,
// then excercises for each day with sets, rep range and notes
class ProgramPage extends StatefulWidget {
  @override
  _MyListState createState() => _MyListState();
}

// this class contains the list view of expandable card tiles 
// title is day title (eg. 'legs') and when expanded, leg excercises for that day show up
class _MyListState extends State<ProgramPage> {
  int value = 0;
  List<TextEditingController> splitDaysTEC = [TextEditingController(), TextEditingController(), TextEditingController()];//TextEditingController();
  List<String> split = ["Push", "Pull", "Legs"];

  // list of excercises at a given day
  List<List<String>> excercises = [[], [], []];
  List<List<TextEditingController>> excercisesTEC = [[], [], []];

  // adds day to split
  _addItem() {
    setState(() {
      value = value + 1;
      splitDaysTEC.add(TextEditingController());
      split.add("New Day");
      excercises.add([]);
      excercisesTEC.add([]);
      //print(split.toString());
      //print(splitDaysTEC.toString());
    });
  }

  @override
  // main scaffold, putting it all together
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // program title
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

      //list of day cards
      body: ListView.builder(
        //shrinkWrap: true,
          itemCount: split.length + 1,
          itemBuilder: (context, index) {
            //print(index.toString());
            //print(splitDaysTEC.length);
            // defines what each card will look like
            if (index == split.length){
              return Card(
                
                color: Colors.deepPurple,
                child: InkWell(
     
                  splashColor: Colors.purple,
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    _addItem();
                  },
                  child: SizedBox(
                    width: double.infinity,
                    height: 50.0,
                    child: Icon(Icons.add),
                  ),
                ),
              );
            }
            else{
            return Card(
              
              child: Padding(
                padding: EdgeInsets.only(
                  top: 8, left: 8.0, right: 8.0, bottom: 8.0),
                  child: ExpansionTile(
                  title: 
                  // row has day title, confirm update button, delete button
                  // and excercise dropdown button
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
                            ),
                          ),
                        ),

                        //confirm update button
                        IconButton(onPressed: () {
                          setState( () {
                            split[index] = (splitDaysTEC[index].text);
                            //closes keyboard
                            FocusManager.instance.primaryFocus?.unfocus();
                            });
                          }, icon: Icon(Icons.check)
                        ),

                        // detete day button
                        IconButton(onPressed: () {
                          setState( () {
                            value = value - 1;
                            split.removeAt(index);
                            excercises.removeAt(index);
                            splitDaysTEC.removeAt(index);
                            excercisesTEC.removeAt(index);
                          });
                          }, icon: Icon(Icons.delete)
                        ),
                      ],
                    ),

                  // excercises for each day
                  //this part is viewed after tile is expanded
                    children: [
                      ListView.builder(
                        itemCount: excercises[index].length + 1,
                        shrinkWrap: true,
                        itemBuilder: (context, excerciseIndex) {
                          //print(index.toString());
                          //print(splitDaysTEC.length);
                          // defines what each card will look like
                          if (excerciseIndex == excercises[index].length){
                            return Card(
                              
                              color: Colors.deepPurple,
                              child: InkWell(
                  
                                splashColor: Colors.purple,
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setState(() {
                                    value = value + 1;
                                    excercisesTEC[index].add(TextEditingController());
                                    excercises[index].add("New Excercise");
                                    
                                    //print(split.toString());
                                    //print(splitDaysTEC.toString());
                                  });
                                },
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 50.0,
                                  child: Icon(Icons.add),
                                ),
                              ),
                            );
                          }
                          else{
                            return Card(
                            
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 8, left: 8.0, right: 8.0, bottom: 8.0),
                                  // expansion tile allows to add notes for each excercise
                                child: ExpansionTile(
                                title: 
                              // row has day title, confirm update button, delete button
                              // and excercise dropdown button
                                  Row(
                                  //verticalDirection: VerticalDirection,
                                    children: [
                                      Expanded(
                                        child: ListTile(
                                          title: TextFormField(
                                            controller: excercisesTEC[index][excerciseIndex],
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(8))),
                                            hintText: excercises[index][excerciseIndex],
                                            ),
                                          ),
                                        ),
                                      ),

                                      //confirm update exceercisesbutton
                                      IconButton(onPressed: () {
                                        setState( () {
                                          excercises[index][excerciseIndex] = (excercisesTEC[index][excerciseIndex].text);
                                        //closes keyboard
                                          FocusManager.instance.primaryFocus?.unfocus();
                                          });
                                      }, icon: Icon(Icons.check)
                                      ),

                                      // detete excercises button
                                      IconButton(onPressed: () {
                                        setState( () {
                                          value = value - 1;
                                          excercises[index].removeAt(excerciseIndex);
                                          excercisesTEC[index].removeAt(excerciseIndex);
                                        });
                                        }, icon: Icon(Icons.delete)
                                      ),
                                    ],//row children
                                  ),//row
                                ),//Expandsion tile
                              ),//Padding
                            );//card
                          }//else
                        },//item builder
                      ),
                    ]
                  
                  ),
                ),
              );
          }
    },
      ),
    );
  }
}






