// program page
// ignore_for_file: prefer_const_constructors

//import 'package:firstapp/main.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'user.dart';

//import 'program_page_widgets/program_excercise.dart';
int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
   return (to.difference(from).inHours / 24).round();
}

// import 'package:flutter/material.dart';

// void main() => runApp(new MaterialApp(home: MyList()));

//program page, where user defines the overall program by days,
// then excercises for each day with sets, rep range and notes
class ProgramPage extends StatefulWidget {
  //final List<String> split;
  
  const ProgramPage({Key? programkey}) : super(key: programkey);
  @override
  _MyListState createState() => _MyListState();
}

// this class contains the list view of expandable card tiles 
// title is day title (eg. 'legs') and when expanded, leg excercises for that day show up
class _MyListState extends State<ProgramPage> {
  //int value = 0;
  //List<String> split = ["Push", "Pull", "Legs"];
  DateTime today = DateTime.now();
  //Map<DateTime, List<Event>> events = {};
  final List<DateTime> toHighlight = [DateTime(2024, 8, 20)];
  DateTime startDay = DateTime(2024, 8, 10);
  // excercise days are colour coded which will correspond 
  // to colour when putting in calendar to make it look nicer
  // and gives quick and easy view of weekly frequency 
  // and overall volume of each day
  // todo: connect colour to each day so that it doesnt reset when you like delete a day or sm,,thn
  List<Color> pastelPalette = [
    Color.fromRGBO(150, 50, 50, 0.6), 
    Color.fromRGBO(199, 143, 74, 0.6), 
    Color.fromRGBO(220, 224, 85, 0.6),
    Color.fromRGBO(57, 129, 42, 0.6),
    Color.fromRGBO(61, 169, 179, 0.6),
    Color.fromRGBO(61, 101, 167, 0.6),
    Color.fromRGBO(106, 92, 185, 0.6), 
    Color.fromRGBO(131, 49, 131, 0.6),
    Color.fromRGBO(180, 180, 178, 0.6),
    ];


  //TextEditingController();
  List<TextEditingController> splitDaysTEC = List.empty(growable: true);

  // list of excercises at a given day
  //excercises needs to be added as part of user class
  //List<List<String>> excercises = [[], [], []];
  List<List<TextEditingController>> excercisesTEC = List.filled(3, List.empty(growable: true), growable: true);

  // adds day to split
  _addItem() {
    //setState(() {
      
      //value = value + 1;
      splitDaysTEC.add(TextEditingController());
      context.read<Profile>().excerciseAppendList(newDay: []);
      excercisesTEC.add([]);
      context.read<Profile>().splitAppend(newDay: "New Day");
      //print(splitDaysTEC.length);
      
      //print(Provider.of<Profile>(context, listen: false).split.toString());
      
      

      //print(split.toString());
      //print(splitDaysTEC.toString());
    //});
  }

  @override
  // main scaffold, putting it all together
  Widget build(BuildContext context) {
    List<TextEditingController> splitDaysTEC = List.filled(Provider.of<Profile>(context, listen: false).split.length, TextEditingController());
    List<List<TextEditingController>>;
    for (int x = 0; x < Provider.of<Profile>(context, listen: false).excercises.length;x++){
      excercisesTEC.add([]);
      for (int y = 0; y < Provider.of<Profile>(context, listen: false).excercises[x].length;y++){
        excercisesTEC[x].add(TextEditingController());
      };
    };
    
    //print(splitDaysTEC.length);
    return Scaffold(
      appBar: AppBar(
        // program title
        title: SizedBox(
          height: 40,
          child: TextFormField(
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
        
      ),
      bottomSheet: SizedBox(
        height: 66,
        child: TableCalendar(
          //origin = monday
          //for x in range(len(split))
          //startday[x] = origin + (splitLength // daysinsplit) * x
          // for i in startday, highlight every 7th day from that point
          headerVisible: false,
          calendarFormat: CalendarFormat.week,
                  calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  DateTime origin = today;
                  for (int splitDay = 0; splitDay < context.watch<Profile>().split.length + 1; splitDay ++){

                  
                    if (daysBetween(origin , day) % 7 == (7 ~/ context.watch<Profile>().split.length) * splitDay) {
                      return Container(
                        decoration: BoxDecoration(
                          color: pastelPalette[splitDay],
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                  }
                  
                  return null;
                },
              ),
                  rowHeight: 50,
                  focusedDay: today, 
                  firstDay: DateTime.utc(2010, 10, 16), 
                  lastDay: DateTime.utc(2030, 3, 14)
                ),
      ),

      //list of day cards
      body: SizedBox(
        height: 510,
        child: ReorderableListView.builder(
            onReorder: (oldIndex, newIndex){
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
        
                //managing these lists shoudl probably be put into a function or smthn this is kinda ugly
                //but hey it works ig
                String x = Provider.of<Profile>(context, listen: false).split[oldIndex];
                context.read<Profile>().splitPop(index: oldIndex);
                context.read<Profile>().splitInsert(index: newIndex, data: x);
              
        
                List<String> y = context.read<Profile>().excercises[oldIndex];
                context.read<Profile>().excercisePopList(index: oldIndex);
                //excercises.removeAt(oldIndex);
                context.read<Profile>().excerciseInsertList(index: newIndex, data: y);
                //excercises.insert(newIndex, y);
        
                TextEditingController z = splitDaysTEC[oldIndex];
                splitDaysTEC.removeAt(oldIndex);
                splitDaysTEC.insert(newIndex, z);
        
                List<TextEditingController> a = excercisesTEC[oldIndex];
                excercisesTEC.removeAt(oldIndex);
                excercisesTEC.insert(newIndex, a);
        
                Color c = pastelPalette[oldIndex];
                pastelPalette.removeAt(oldIndex);
                pastelPalette.insert(newIndex, c);
                //Navigator.of(context).push(MaterialPageRoute(builder: (context)=> SchedulePage(program: widget.split)));

              });
              //print(split.toString());
            },
          //shrinkWrap: true,
            itemCount: context.watch<Profile>().split.length + 1,
            itemBuilder: (context, index) {
              
              
              //print(index.toString());
              //print(splitDaysTEC.length);
              // defines what each card will look like
              if (index == context.watch<Profile>().split.length){
                return Card(
                  key: ValueKey(index),
        
                  
                  color: Colors.deepPurple,
                  child: InkWell(
             
                    splashColor: Colors.purple,
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() {
                        _addItem();
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
                key: ValueKey(index),
                color: pastelPalette[index],
                
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 8, left: 8.0, right: 8.0, bottom: 8.0),
                    child: ExpansionTile(
                    iconColor: Color.fromARGB(255, 255, 255, 255),
                    collapsedIconColor: Color.fromARGB(255, 255, 255, 255),
                    title: 
                    // row has day title, confirm update button, delete button
                    // and excercise dropdown button
                      Row(
                        //verticalDirection: VerticalDirection,
                        children: [
                          Expanded(
                            child: ListTile(
                              title: SizedBox(
                                height: 40,
                                width: 100,
                                child: 
                                
                                TextFormField(
                                  
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  controller: splitDaysTEC[index],
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Color.fromARGB(94, 117, 117, 117),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                    
                                    border: OutlineInputBorder(
                                      //borderSide: BorderSide(width: 0),
                                        borderRadius: BorderRadius.all(Radius.circular(4)),
                                    ),

                                    hintText: context.watch<Profile>().split[index],
                                  ),
                                ),
                              ),
                            ),
                          ),
        
                          //confirm update button
                          IconButton(onPressed: () {
                            setState( () {

                              context.read<Profile>().splitAssign(index: index, data: splitDaysTEC[index].text);
                              //closes keyboard
                              FocusManager.instance.primaryFocus?.unfocus();
                              //Navigator.of(context).push(MaterialPageRoute(builder: (context)=> SchedulePage(program: widget.split)));

                              });
                            }, 
                            icon: Icon(Icons.check),
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
        
                          // detete day button
                          IconButton(onPressed: () {
                            setState( () {
                              //value = value - 1;
                              context.read<Profile>().splitPop(index: index);
                              context.read<Profile>().excercisePopList(index: index);
                              //excercises.removeAt(index);
                              splitDaysTEC.removeAt(index);
                              excercisesTEC.removeAt(index);
                              //Navigator.of(context).push(MaterialPageRoute(builder: (context)=> SchedulePage(program: widget.split)));

                            });
                            }, 
                            icon: Icon(Icons.delete),
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ],
                      ),
        
                    // excercises for each day
                    //this part is viewed after tile is expanded
                      children: [
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: context.read<Profile>().excercises[index].length + 1,
                          shrinkWrap: true,
                          itemBuilder: (context, excerciseIndex) {
                            //print(index.toString());
                            //print(splitDaysTEC.length);
                            // defines what each card will look like
                            if (excerciseIndex == context.read<Profile>().excercises[index].length){
                              return Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 8),
                                child: SizedBox(
                                  // width: 50,
                                  // height: 50,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: ButtonTheme(
                                      minWidth: 100,
                                      height: 100,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                              excercisesTEC[index].add(TextEditingController());
                                              //print(excercisesTEC[index].length.toString());
                                              context.read<Profile>().excerciseAppend(newExcercise: "New Excercise", index: index);
                                              //excercises[index].add("New Excercise");
                                              //print("ok");
                                            });  
                                        },
                                        
                                        style: ButtonStyle(
                                          shape: WidgetStateProperty.all(CircleBorder()),
                                          //padding: WidgetStateProperty.all(EdgeInsets.all(20)),
                                          backgroundColor: WidgetStateProperty.all(Colors.deepPurple), // <-- Button color
                                          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
                                            if (states.contains(WidgetState.pressed)) return Colors.deepPurpleAccent; // <-- Splash color
                                          }),
                                        ),
                                        child: Icon(Icons.add),
                                        
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            else{
                              //todo: centre text boxes, add notes option on dropdown
                              return ExpansionTile(
                                iconColor: Color.fromARGB(255, 21,18,24),
                                  title: 
                                // row has day title, confirm update button, delete button
                                // and excercise dropdown button
                                    Row(
                                    //verticalDirection: VerticalDirection,
                                      children: [
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: ListTile(
                                              title: TextFormField(
                                                controller: excercisesTEC[index][excerciseIndex],
                                                decoration: InputDecoration(
                                                  
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.all(Radius.circular(8))),
                                                hintText: context.read<Profile>().excercises[index][excerciseIndex],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
        
                                        //confirm update exceercisesbutton
                                        IconButton(onPressed: () {
                                          setState( () {
                                            context.read<Profile>().excerciseAssign(index1: index, index2: excerciseIndex, data: (excercisesTEC[index][excerciseIndex].text));
                                            //excercises[index][excerciseIndex] = (excercisesTEC[index][excerciseIndex].text);
                                          //closes keyboard
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            });
                                        }, icon: Icon(Icons.check)
                                        ),
        
                                        // detete excercises button
                                        IconButton(onPressed: () {
                                          setState( () {
                                            //value = value - 1;
                                            context.read<Profile>().excercisePop(index1: index, index2: excerciseIndex);
                                            //excercises[index].removeAt(excerciseIndex);
                                            excercisesTEC[index].removeAt(excerciseIndex);
                                          });
                                          }, icon: Icon(Icons.delete)
                                        ),
                                      ],//row children
                                    ),//row
                                  );//,//Expandsion tile
                                //),//Padding
                              //);//card
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
      ),
    );
  }
}






