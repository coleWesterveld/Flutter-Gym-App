// Side drawer to edit, select and add programs

import 'package:firstapp/database/database_helper.dart';
import 'package:firstapp/database/profile.dart';
import 'package:flutter/material.dart';

class ProgramsDrawer extends StatelessWidget {
  final int currentProgramId;
  final Function(Program) onProgramSelected;
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  final ThemeData theme;

  ProgramsDrawer({
    required this.currentProgramId,
    required this.onProgramSelected,
    required this.theme,
    super.key,
  });

  Future<List<Program>> _fetchPrograms() async {
    final programMaps = await dbHelper.fetchPrograms();
    return programMaps.map((map) => Program.fromMap(map)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: FutureBuilder<List<Program>>(
        future: _fetchPrograms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading programs'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No programs found'));
          }

          final programs = snapshot.data!;
          
          return Column(
            children: [
               DrawerHeader(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                ),

                child: Center(
                  child: Text(
                    'Your Programs',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
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
                      leading: Icon(
                        Icons.fitness_center, 
                        color: theme.colorScheme.onSurface,
                      ),

                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              program.programTitle,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                              ),
                            ),
                          ),
                          if (program.programID == currentProgramId) 
                            IconButton(
                              icon: Icon(
                                Icons.edit, 
                                color: theme.colorScheme.onSurface, 
                                size: 20
                              ),

                              onPressed: () => _showEditProgramDialog(context, program),
                            ),
                        ],
                      ),
                      selected: program.programID == currentProgramId,
                      selectedTileColor: theme.colorScheme.outline,
                      onTap: () {
                        onProgramSelected(program);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),

              Divider(color: theme.colorScheme.outline),

              ListTile(
                leading: Icon(
                  Icons.add, 
                  color: theme.colorScheme.onSurface
                ),

                title: Text(
                  'Create New Program',
                  style: TextStyle(color: theme.colorScheme.onSurface),
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

  void _showEditProgramDialog(BuildContext context, Program program) {
    final programNameController = TextEditingController(text: program.programTitle);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Program'),
        content: TextField(
          controller: programNameController,
          decoration: const InputDecoration(hintText: 'Enter new program name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),

          TextButton(
            onPressed: () async {
              if (programNameController.text.isNotEmpty) {
                final updatedProgram = program.copyWith(
                  newTitle: programNameController.text
                );
                
                // Update program in database
                await dbHelper.updateProgram(updatedProgram);
                
                // If editing current program, update the selection
                if (program.programID == currentProgramId) {
                  onProgramSelected(updatedProgram);
                }
                
                if (context.mounted){
                  Navigator.pop(context);
                }
                
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCreateProgramDialog(BuildContext context) {
    final programNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Program'),

        content: TextField(
          controller: programNameController,
          decoration: const InputDecoration(hintText: 'Enter program name'),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),

          TextButton(
            onPressed: () async {
              if (programNameController.text.isNotEmpty) {
                final id = await dbHelper.insertProgram(
                  programNameController.text,
                );
                
                final newProgram = Program(
                  programID: id,
                  programTitle: programNameController.text,
                );
                
                onProgramSelected(newProgram);

                if (context.mounted){
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
