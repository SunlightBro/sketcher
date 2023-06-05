import 'package:flutter/material.dart';
import 'package:sketch/src/element_modifiers.dart';

enum SketchMode {
  line,
  free,
  text,
  edit,
}

class SketchController extends ChangeNotifier {
  SketchMode sketchMode = SketchMode.edit;

  Color color = const Color(0xFF000000);
  LineType lineType = LineType.full;
  double lineThickness = 5;
}
