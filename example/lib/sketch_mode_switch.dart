import 'package:flutter/material.dart';
import 'package:sketch/sketch.dart';

class SketchModeSwitch extends StatelessWidget {
  const SketchModeSwitch({
    Key? key,
    required this.sketchMode,
    required this.onSelectSketchMode,
  }) : super(key: key);

  final SketchMode sketchMode;
  final Function(SketchMode) onSelectSketchMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SegmentedButton<SketchMode>(
        style: ButtonStyle(),
        segments: [
          ButtonSegment(
            icon: Icon(Icons.edit),
            label: Text("Edit Mode"),
            value: SketchMode.edit,
          ),
          ButtonSegment(
            icon: Icon(Icons.line_axis),
            label: Text("Line Mode"),
            value: SketchMode.line,
          ),
          ButtonSegment(
            icon: Icon(Icons.circle_outlined),
            label: Text("Circle Mode"),
            value: SketchMode.oval,
          ),
          ButtonSegment(
            icon: Icon(Icons.square_outlined),
            label: Text("Rect Mode"),
            value: SketchMode.rect,
          ),
          ButtonSegment(
            icon: Icon(Icons.draw_outlined),
            label: Text("Path Mode"),
            value: SketchMode.path,
          ),
          ButtonSegment(
            icon: Icon(Icons.text_fields),
            label: Text("Text Mode"),
            value: SketchMode.text,
          ),
        ],
        selected: <SketchMode>{sketchMode},
        onSelectionChanged: (Set<SketchMode> newSelection) {
          onSelectSketchMode(newSelection.first);
        },
      ),
    );
  }
}
