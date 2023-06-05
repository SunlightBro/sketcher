import 'package:flutter/material.dart';
import 'package:sketch/sketch.dart';

void main() {
  runApp(ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Sketch(),
      ),
    );
  }
}
