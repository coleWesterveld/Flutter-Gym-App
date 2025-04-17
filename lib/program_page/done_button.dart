// IOS for some reason does not have a way to have 
// a numeric keyboard AND a done button to dismiss at the same time
// So this is my workaround - a done button which will be just above the keyboard when needed

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:firstapp/providers_and_settings/program_provider.dart';  // Access Program Details
import 'package:firstapp/other_utilities/lightness.dart';                // Lightening Colours
import 'package:firstapp/providers_and_settings/settings_provider.dart';

class DoneButtonBottom extends StatelessWidget {
  const DoneButtonBottom({
    super.key,
    required this.context,
    required this.theme,
  });

  final BuildContext context;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
    
        border: Border(
          top: BorderSide(
            color:  theme.colorScheme.outline,
          ),
        ),
        
        color: theme.colorScheme.surface,
      ),
    
      height: 50,
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            style: ButtonStyle(
              // When clicked, it splashes a lighter purple to show that button was clicked
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)
                ),
              ),

              // Trying to match IOS buttons...
              backgroundColor: WidgetStateProperty.all(const Color(0xFF6c6e6e),),
            ),
              
            onPressed: () {
              if (context.read<SettingsModel>().hapticsEnabled) HapticFeedback.heavyImpact();
              WidgetsBinding.instance.focusManager.primaryFocus?.unfocus();
              context.read<Profile>().done = false;
            },
  
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
