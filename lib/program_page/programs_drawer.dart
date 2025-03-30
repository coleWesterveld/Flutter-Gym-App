import 'package:firstapp/database/database_helper.dart';
import 'package:firstapp/database/profile.dart';
//import 'package:firstapp/database/profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


class ProgramsDrawer extends StatelessWidget {
  //final DatabaseHelper dbHelper;
  final int currentProgramId;
  final Function(Program) onProgramSelected;
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  ProgramsDrawer({
    //required this.dbHelper,
    required this.currentProgramId,
    required this.onProgramSelected,
    Key? key,
  }) : super(key: key);

  Future<List<Program>> _fetchPrograms() async {
    final programMaps = await dbHelper.fetchPrograms();
    return programMaps.map((map) => Program.fromMap(map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFF1e2025),
      child: FutureBuilder<List<Program>>(
        future: _fetchPrograms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading programs'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No programs found'));
          }

          final programs = snapshot.data!;
          
          return Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Color(0xFF1e2025),
                ),
                child: Center(
                  child: Text(
                    'Your Programs',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    return ListTile(
                      leading: Icon(Icons.fitness_center, color: Colors.white),
                      title: Text(
                        program.programTitle,
                        style: TextStyle(color: Colors.white),
                      ),
                      selected: program.programID == currentProgramId,
                      selectedTileColor: Colors.blueGrey[800],
                      onTap: () {
                        onProgramSelected(program);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              Divider(color: Colors.grey),
              ListTile(
                leading: Icon(Icons.add, color: Colors.white),
                title: Text(
                  'Create New Program',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _showCreateProgramDialog(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateProgramDialog(BuildContext context) {
    final programNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Program'),
        content: TextField(
          controller: programNameController,
          decoration: InputDecoration(hintText: 'Enter program name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (programNameController.text.isNotEmpty) {
                // Insert new program using your dbHelper
                final id = await dbHelper.insertProgram(
                  programNameController.text,
                );
                
                // Create a new Program object
                final newProgram = Program(
                  programID: id,
                  programTitle: programNameController.text,
                );
                
                // Call the selection callback
                onProgramSelected(newProgram);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close drawer
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }
}