import 'dart:math';

import 'package:example/sketch_mode_switch.dart';
import 'package:flutter/material.dart';
import 'package:sketch/sketch.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

void main() {
  runApp(ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SketchPage(),
    );
  }
}

class SketchPage extends StatefulWidget {
  const SketchPage({super.key});

  @override
  State<SketchPage> createState() => _SketchPageState();
}

final IList<SketchElement> samples = IList([
  LineEle(Point(50, 50), Point(600, 200), Colors.red, LineType.dotted, 10),
  LineEle(Point(500, 500), Point(600, 400), Colors.blue, LineType.dotted, 10),
]);

class _SketchPageState extends State<SketchPage> {
  late SketchController controller;

  @override
  void initState() {
    super.initState();
    controller = SketchController(elements: samples);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onSelectSketchMode(SketchMode sketchMode) {
    setState(() {
      controller.sketchMode = sketchMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Sketch(
            controller: controller,
          ),
          Align(
            alignment: Alignment.topCenter,
            child: SketchModeSwitch(
              sketchMode: controller.sketchMode,
              onSelectSketchMode: _onSelectSketchMode,
            ),
          ),
        ],
      ),
    );
  }
}
