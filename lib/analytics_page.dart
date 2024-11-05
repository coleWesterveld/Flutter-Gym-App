// analyitcs page
// not updated
import 'package:flutter/material.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e2025),
        centerTitle: true,
        title: const Text(
          "Analytics",
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
          ),
      ),
    );
  }
}