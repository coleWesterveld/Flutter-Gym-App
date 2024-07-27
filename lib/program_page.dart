// program page
import 'package:flutter/material.dart';
import 'program_page_widgets/program_excercise.dart';


// import 'package:flutter/material.dart';

// void main() => runApp(new MaterialApp(home: MyList()));

class ProgramPage extends StatefulWidget {
  @override
  _MyListState createState() => _MyListState();
}

class _MyListState extends State<ProgramPage> {
  int value = 2;

  _addItem() {
    setState(() {
      value = value + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: TextFormField(
              //controller: yourController,
              //onChanged: (text) {
                //excercises.add(yourController.text);
              //},
            
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
          itemCount: this.value,
          itemBuilder: (context, index) => this._buildRow(index)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: Icon(Icons.add),
      ),
    );
  }
//Text("Item " + index.toString())
  _buildRow(int index) {
    return Card(
        child: Padding(
        padding: EdgeInsets.only(
            top: 8, left: 8.0, right: 8.0, bottom: 8.0),
            child: ExpansionTile(
            title: TextFormField(
              //controller: yourController,
              //onChanged: (text) {
                //excercises.add(yourController.text);
              //},
            
            style: TextStyle(
              fontSize: 15,
            ),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4))),
              hintStyle: TextStyle(
                fontSize: 15,
              ),
              hintText: "Day " + index.toString(),
              
            ),
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
  }
}




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

