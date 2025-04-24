// Popup to edit day title, colour
// comes up on pressing edit button of a day

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';                                 // For Slider
import 'package:flutter/services.dart';                                  // Haptics

import 'package:firstapp/providers_and_settings/program_provider.dart';  // Access Program Details
import 'package:firstapp/providers_and_settings/settings_provider.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class PopUpDayEditor extends StatefulWidget {
  const PopUpDayEditor({
    super.key,
    required this.theme,
    required this.index,
    required this.titleTEC,
  });

  final ThemeData theme;
  final int index;
  final TextEditingController titleTEC;

  @override
  State<PopUpDayEditor> createState() => _PopUpDayEditorState();
}

class _PopUpDayEditorState extends State<PopUpDayEditor> {

  // For day-editor slider - 0 is editing title, 1 is editing colour
  bool? _sliding = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: CupertinoSlidingSegmentedControl(
        padding: const EdgeInsets.all(4.0),
        children: const <bool, Text>{
          false: Text("Title"),
          true: Text("Color"),
        }, 
                                
        onValueChanged: (bool? newValue){
          setState((){
            _sliding = newValue;
          });                       
        },
        thumbColor: widget.theme.colorScheme.secondary,
        groupValue: _sliding,
      ),
    
      content: editBuilder(widget.index, widget.theme, widget.titleTEC),
    
      actions: [
        IconButton(
          onPressed: (){
            if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
            
            
            if (widget.titleTEC.text.isNotEmpty) {
              Provider.of<Profile>(context, listen: false).splitAssign(
                index: widget.index, 
                newDay: context.read<Profile>().split[widget.index].copyWith(newDayTitle: widget.titleTEC.text),
                context: context
              );
            }
    
            Navigator.of(context, rootNavigator: true).pop('dialog');
            _sliding = false;
          },
          icon: const Icon(Icons.check)
        )
      ]
        
    );
  }

  Widget editBuilder(index, theme, titleTEC){ 

    // Ensure text is selected when the widget is built
    titleTEC.selection = TextSelection(
      baseOffset: 0,
      extentOffset: titleTEC.text.length,
    );

    if(_sliding == false){
      return SizedBox(
        height: 100,
        width: 300,

        child: TextFormField(
          onFieldSubmitted: (value){
            if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
            Navigator.of(context).pop(widget.titleTEC.text);
          },
          
          autofocus: true,
          controller: titleTEC,

          decoration: InputDecoration(
            suffixIcon: IconButton(
              onPressed: titleTEC.clear,
              icon: const Icon(Icons.highlight_remove),
            ),

            hintText: "Enter Text",
          )
        ),
      );
    }else{
      return SizedBox(
        height: 250,
        width: 300,
        child: SingleChildScrollView(
          
          // Allow user to change day colour
          child: BlockPicker(
            pickerColor: Color(context.watch<Profile>().split[index].dayColor),
            onColorChanged: (Color color) {
              context.read<Profile>().splitAssign(
                index: index,
                newDay: context.read<Profile>().split[index].copyWith(newDayColor: color.toARGB32()),
                context: context
              );
            },
            
            availableColors: Profile.colors,
            layoutBuilder: pickerLayoutBuilder,
            itemBuilder: pickerItemBuilder,
          ),
        ),
      );
    }
  }

  Widget pickerItemBuilder(Color color, bool isCurrentColor, void Function() changeColor) {
    
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((255 * 0.8).round()), 
            offset: const Offset(1, 2), 
            blurRadius: 0.0)
          ],
      ),

      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: changeColor,
          borderRadius: BorderRadius.circular(8.0),

          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isCurrentColor ? 1 : 0,
            child: Icon(
              Icons.done,
              size: 36,
              color: widget.theme.colorScheme.onSurface,
            ),

          ),
        ),
      ),
    );
  }

  // Layout of pop-up colour picker
  Widget pickerLayoutBuilder(BuildContext context, List<Color> colors, PickerItem child) {
    Orientation orientation = MediaQuery.of(context).orientation;

    return SizedBox(
      width: 300,
      height: orientation == Orientation.portrait ? 360 : 240,
      child: GridView.count(
        crossAxisCount: orientation == Orientation.portrait ?  5: 4,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        children: [for (Color color in colors) child(color)],
      ),
    );
  }
}
