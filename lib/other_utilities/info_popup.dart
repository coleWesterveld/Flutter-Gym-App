import 'package:flutter/material.dart';

class InfoPopupWidget extends StatelessWidget {
  final Widget? child;
  final Widget popupContent;

  const InfoPopupWidget({
    this.child,
    required this.popupContent,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (child != null) child!,
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              barrierDismissible: true, // Dismiss when tapping outside
              builder: (BuildContext context) {
                return Dialog(
                  insetPadding: EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: popupContent,
                  ),
                );
              },
            );
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'i',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}