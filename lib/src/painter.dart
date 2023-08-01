import 'package:fast_immutable_collections/fast_immutable_collections.dart'
    as fic;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sketch/src/elements.dart';

class SketchPainter extends CustomPainter {
  ///Initialize a instance of [SketchPainter] class
  SketchPainter(this.sketchElements);

  /// a list of all painted elements
  final fic.IList<SketchElement> sketchElements;

  @override
  void paint(Canvas canvas, Size size) {
    for (final sE in sketchElements) {
      sE.draw(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is SketchPainter) {
      if (sketchElements == oldDelegate.sketchElements) {
        return false;
      }
    }
    return true;
  }
}

class ActivePainter extends CustomPainter {
  ///Initialize a instance of [ActivePainter] class
  ActivePainter(this.sketchElement);

  /// active Element
  final SketchElement? sketchElement;

  @override
  void paint(Canvas canvas, Size size) {
    final ele = sketchElement;
    if (ele != null) {
      ele.draw(canvas, size, Colors.orange);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
