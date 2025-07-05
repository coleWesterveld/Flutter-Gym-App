import 'package:keyboard_actions/keyboard_actions.dart';
import "package:flutter/material.dart";


KeyboardActionsConfig buildKeyboardActionsConfig(BuildContext context, ThemeData theme, List<FocusNode> nodes) {
  return KeyboardActionsConfig(
    keyboardBarColor: theme.colorScheme.surface,
    keyboardActionsPlatform: KeyboardActionsPlatform.IOS,
    actions: nodes.map((node) {
      return KeyboardActionsItem(

        focusNode: node,
        toolbarButtons: [
          (node) => TextButton(
            style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                ),
                onPressed: () => node.unfocus(),
                child: const Text('Done'),
              ),
        ],
      );
    }).toList(),
  );
}