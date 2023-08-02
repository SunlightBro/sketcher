import 'dart:math';

import 'package:example/color_picker.dart';
import 'package:example/line_type_switch.dart';
import 'package:example/sketch_mode_switch.dart';
import 'package:example/stroke_width_switch.dart';
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
    controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    controller.removeListener(() {});
    controller.dispose();
    super.dispose();
  }

  void _onSelectSketchMode(SketchMode sketchMode) {
    setState(() {
      controller.sketchMode = sketchMode;
    });
  }

  void _onSelectLineType(LineType lineType) {
    controller.lineType = lineType;
  }

  void _onSelectColor(Color color) {
    controller.color = color;
  }

  void _onSelectStrokeWidth(double strokeWidth) {
    controller.strokeWidth = strokeWidth;
  }

  @override
  Widget build(BuildContext context) {
    final activeElementColor = controller.activeElementColor;
    final activeElementLineType = controller.activeElementLineType;
    final activeElementStrokeWidth = controller.activeElementStrokeWidth;
    return Scaffold(
      body: Stack(
        children: [
          SketchWidget(
            controller: controller,
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                SizedBox(height: 16.0),
                Text("Sketch Mode"),
                SketchModeSwitch(
                  sketchMode: controller.sketchMode,
                  onSelectSketchMode: _onSelectSketchMode,
                ),
                SizedBox(height: 8.0),
                Text("Color"),
                ColorPicker(
                  color: activeElementColor ?? controller.color,
                  onSelectColor: _onSelectColor,
                ),
                SizedBox(height: 8.0),
                Text("Line Type"),
                LineTypeSwitch(
                  lineType: activeElementLineType ?? controller.lineType,
                  onSelectLineType: _onSelectLineType,
                ),
                SizedBox(height: 8.0),
                Text("Stroke Width"),
                StrokeWidthSwitch(
                  strokeWidth: activeElementStrokeWidth ?? controller.strokeWidth,
                  onSelectStrokeWidth: _onSelectStrokeWidth,
                ),
                IconButton(
                    onPressed: controller.undoPossible
                        ? () => controller.undo()
                        : null,
                    icon: Icon(Icons.undo))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
